import { firestoreGet, firestorePatch } from './firebase.ts';

const headers = {
  'Access-Control-Allow-Origin': '*',
  'Content-Type': 'application/json',
};

const paidStatuses = new Set(['settlement']);
const terminalStatuses = new Set([
  'settlement',
  'capture',
  'cancel',
  'deny',
  'expire',
  'failure',
]);

Deno.serve(async (request) => {
  let stage = 'received';
  if (request.method === 'OPTIONS') {
    return new Response('ok', { status: 204, headers });
  }
  if (request.method !== 'POST') {
    return response({ error: 'Method not allowed' }, 405);
  }

  try {
    console.log('midtrans-webhook: notification received');
    stage = 'parse_notification';
    const notification = await request.json();
    const validation = validateNotification(notification);
    if (!validation.ok) {
      return response({ error: validation.error }, 400);
    }

    const {
      orderId,
      statusCode,
      grossAmount,
      signature,
      transactionStatus,
      fraudStatus,
      transactionId,
    } = validation.value;
    const serverKey = Deno.env.get('MIDTRANS_SERVER_KEY');
    console.log('midtrans-webhook: payload validated', {
      orderId,
      transactionStatus,
    });
    stage = 'verify_signature';
    if (!serverKey) {
      console.error('midtrans-webhook: MIDTRANS_SERVER_KEY is not configured');
      return response({ error: 'Webhook pembayaran belum dikonfigurasi' }, 503);
    }

    const expectedSignature = await sha512(
      `${orderId}${statusCode}${grossAmount}${serverKey}`,
    );
    if (!safeEqual(expectedSignature, signature)) {
      return response({ error: 'Signature notification tidak valid' }, 401);
    }

    stage = 'read_order';
    const order = await firestoreGet(`orders/${encodeURIComponent(orderId)}`);
    if (!order) {
      return response({ error: 'Order tidak ditemukan' }, 404);
    }

    const orderAmount = Number(order.totalPrice);
    if (!Number.isSafeInteger(orderAmount) || orderAmount !== Number(grossAmount)) {
      console.error('midtrans-webhook: amount mismatch', { orderId });
      return response({ error: 'Nominal transaksi tidak sesuai order' }, 422);
    }

    stage = 'read_payment';
    const paymentPath = `payments/${encodeURIComponent(orderId)}`;
    const previousPayment = await firestoreGet(paymentPath);
    const previousStatus = previousPayment?.transactionStatus?.toString() ?? '';

    // Midtrans can retry or deliver notifications out of order. A settled
    // payment must never be downgraded by a later pending/failed notification.
    if (isPaid(previousStatus, previousPayment?.paymentStatus)) {
      await firestorePatch(paymentPath, {
        lastNotificationAt: new Date().toISOString(),
      });
      if (order.paymentStatus !== 'lunas') {
        await firestorePatch(`orders/${encodeURIComponent(orderId)}`, {
          paymentStatus: 'lunas',
        });
      }
      return response({ ok: true, duplicate: true }, 200);
    }

    const paymentStatus = mapPaymentStatus(transactionStatus, fraudStatus);
    const now = new Date().toISOString();
    stage = 'write_payment';
    await firestorePatch(paymentPath, {
      orderId,
      amount: orderAmount,
      paymentStatus,
      transactionStatus,
      fraudStatus,
      transactionId,
      statusCode,
      lastNotificationAt: now,
      updatedAt: now,
      createdAt: previousPayment?.createdAt ?? now,
    });

    // CleanPick currently defines only belumBayar and lunas. Pending and
    // failed Midtrans states remain belumBayar on the order, while their
    // exact provider status is retained in payments/{orderId}.
    if (order.paymentStatus !== paymentStatus) {
      stage = 'write_order';
      await firestorePatch(`orders/${encodeURIComponent(orderId)}`, {
        paymentStatus,
      });
    }

    return response({ ok: true, orderId, paymentStatus }, 200);
  } catch (error) {
    console.error('midtrans-webhook failed', {
      stage,
      message: error instanceof Error ? error.message : 'unknown error',
    });
    return response({ error: 'Webhook gagal diproses' }, 500);
  }
});

type Notification = {
  orderId: string;
  statusCode: string;
  grossAmount: string;
  signature: string;
  transactionStatus: string;
  fraudStatus: string;
  transactionId: string;
};

function validateNotification(value: unknown):
  | { ok: true; value: Notification }
  | { ok: false; error: string } {
  if (value === null || typeof value !== 'object') {
    return { ok: false, error: 'Payload notification tidak valid' };
  }

  const body = value as Record<string, unknown>;
  const orderId = text(body.order_id);
  const statusCode = text(body.status_code);
  const grossAmount = text(body.gross_amount);
  const signature = text(body.signature_key);
  const transactionStatus = text(body.transaction_status);
  const fraudStatus = text(body.fraud_status);
  const transactionId = text(body.transaction_id);

  if (!orderId || !/^[A-Za-z0-9_-]{1,64}$/.test(orderId)) {
    return { ok: false, error: 'order_id tidak valid' };
  }
  if (!statusCode || !grossAmount || !signature || !transactionStatus) {
    return { ok: false, error: 'Field notification wajib tidak lengkap' };
  }
  const amount = Number(grossAmount);
  if (!Number.isSafeInteger(amount) || amount <= 0) {
    return { ok: false, error: 'gross_amount tidak valid' };
  }
  if (!terminalStatuses.has(transactionStatus) && transactionStatus !== 'pending') {
    return { ok: false, error: 'transaction_status tidak dikenali' };
  }

  return {
    ok: true,
    value: {
      orderId,
      statusCode,
      grossAmount,
      signature,
      transactionStatus,
      fraudStatus,
      transactionId,
    },
  };
}

function mapPaymentStatus(
  transactionStatus: string,
  fraudStatus: string,
): 'lunas' | 'belumBayar' {
  if (paidStatuses.has(transactionStatus)) return 'lunas';
  if (transactionStatus === 'capture' && fraudStatus === 'accept') return 'lunas';
  return 'belumBayar';
}

function isPaid(transactionStatus: unknown, paymentStatus: unknown): boolean {
  return paymentStatus === 'lunas' || transactionStatus === 'settlement';
}

function text(value: unknown): string {
  return typeof value === 'string'
    ? value.trim()
    : value == null
        ? ''
        : String(value).trim();
}

async function sha512(value: string): Promise<string> {
  const bytes = new TextEncoder().encode(value);
  const digest = await crypto.subtle.digest('SHA-512', bytes);
  return Array.from(new Uint8Array(digest))
    .map((byte) => byte.toString(16).padStart(2, '0'))
    .join('');
}

function safeEqual(left: string, right: string): boolean {
  if (left.length !== right.length) return false;
  let difference = 0;
  for (let index = 0; index < left.length; index++) {
    difference |= left.charCodeAt(index) ^ right.charCodeAt(index);
  }
  return difference === 0;
}

function response(body: Record<string, unknown>, status: number): Response {
  return new Response(JSON.stringify(body), { status, headers });
}
