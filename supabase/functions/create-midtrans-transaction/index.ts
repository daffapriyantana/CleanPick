import {
  FirebaseTokenError,
  firestoreGet,
  firestorePatch,
  verifyFirebaseToken,
} from './firebase.ts';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};
const jsonHeaders = { ...corsHeaders, 'Content-Type': 'application/json' };

Deno.serve(async (request) => {
  if (request.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });
  try {
    if (request.method !== 'POST') return json({ error: 'Method not allowed' }, 405);
    const authHeader = request.headers.get('Authorization') ?? '';
    let claims;
    try {
      claims = await verifyFirebaseToken(authHeader.replace(/^Bearer\s+/i, ''));
    } catch (error) {
      if (error instanceof FirebaseTokenError && error.reason === 'missing') {
        return json({ error: 'Token Firebase tidak dikirim oleh aplikasi' }, 401);
      }
      return json({ error: 'Token Firebase tidak valid atau sudah kedaluwarsa. Login ulang diperlukan.' }, 401);
    }
    const body = await request.json();
    const orderId = body.orderId?.toString();
    const action = body.action?.toString();
    if (!orderId || !/^[A-Za-z0-9_-]{1,64}$/.test(orderId)) {
      return json({ error: 'orderId tidak valid' }, 400);
    }

    const order = await firestoreGet(`orders/${encodeURIComponent(orderId)}`);
    if (!order) return json({ error: 'Pesanan tidak ditemukan' }, 404);
    if (order.customerId !== claims.sub) return json({ error: 'Anda tidak memiliki akses ke pesanan ini' }, 403);
    if (order.status === 'dibatalkan') return json({ error: 'Pesanan yang dibatalkan tidak dapat dibayar' }, 409);
    if (order.paymentStatus === 'lunas') return json({ error: 'Pesanan sudah dibayar' }, 409);

    const grossAmount = Number(order.totalPrice);
    if (!Number.isSafeInteger(grossAmount) || grossAmount <= 0) {
      return json({ error: 'Nominal pesanan tidak valid' }, 422);
    }

    if (action === 'verify') {
      const serverKey = Deno.env.get('MIDTRANS_SERVER_KEY');
      if (!serverKey) throw new Error('Midtrans secret is not configured');
      const statusResponse = await fetch(
        `https://api.sandbox.midtrans.com/v2/${encodeURIComponent(orderId)}/status`,
        {
          headers: {
            Authorization: `Basic ${btoa(`${serverKey}:`)}`,
            Accept: 'application/json',
          },
        },
      );
      const status = await statusResponse.json();
      if (!statusResponse.ok) {
        return json({ error: 'Status transaksi Midtrans belum tersedia' }, 502);
      }

      const transactionStatus = status.transaction_status?.toString().toLowerCase();
      const fraudStatus = status.fraud_status?.toString().toLowerCase() ?? '';
      const paid = transactionStatus === 'settlement' ||
        (transactionStatus === 'capture' && fraudStatus === 'accept');
      const paymentStatus = paid ? 'lunas' : 'belumBayar';
      const now = new Date().toISOString();
      await firestorePatch(`payments/${encodeURIComponent(orderId)}`, {
        orderId,
        amount: grossAmount,
        paymentStatus,
        transactionStatus: transactionStatus ?? 'unknown',
        fraudStatus,
        transactionId: status.transaction_id?.toString() ?? '',
        statusCode: status.status_code?.toString() ?? '',
        lastNotificationAt: now,
        updatedAt: now,
      });
      if (paid) {
        await firestorePatch(`orders/${encodeURIComponent(orderId)}`, {
          paymentStatus: 'lunas',
        });
      }
      return json({ ok: true, paymentStatus });
    }

    const existing = await firestoreGet(`payments/${encodeURIComponent(orderId)}`);
    if (existing?.snapToken && ['pending', 'settlement', 'capture'].includes(existing.transactionStatus)) {
      return json({ orderId, snapToken: existing.snapToken, redirectUrl: existing.redirectUrl });
    }

    const serverKey = Deno.env.get('MIDTRANS_SERVER_KEY');
    if (!serverKey) throw new Error('Midtrans secret is not configured');
    const midtransResponse = await fetch('https://app.sandbox.midtrans.com/snap/v1/transactions', {
      method: 'POST',
      headers: {
        Authorization: `Basic ${btoa(`${serverKey}:` )}`,
        'Content-Type': 'application/json',
        Accept: 'application/json',
      },
      body: JSON.stringify({
        transaction_details: { order_id: orderId, gross_amount: grossAmount },
        customer_details: {
          first_name: order.customerName ?? claims.name ?? 'Customer CleanPick',
          email: claims.email,
        },
      }),
    });
    const result = await midtransResponse.json();
    if (!midtransResponse.ok || !result.token || !result.redirect_url) {
      console.error('Midtrans rejected transaction', {
        status: midtransResponse.status,
        error: result.error_messages ?? result.status_message ?? 'unknown',
      });
      return json({ error: 'Midtrans menolak transaksi. Periksa konfigurasi Sandbox dan nominal order.' }, 502);
    }

    await firestorePatch(`payments/${encodeURIComponent(orderId)}`, {
      orderId,
      userId: claims.sub,
      amount: grossAmount,
      paymentStatus: 'pending',
      transactionStatus: 'pending',
      snapToken: result.token,
      redirectUrl: result.redirect_url,
      updatedAt: new Date().toISOString(),
      createdAt: existing?.createdAt ?? new Date().toISOString(),
    });
    return json({ orderId, snapToken: result.token, redirectUrl: result.redirect_url });
  } catch (error) {
    const message = error instanceof Error ? error.message : 'unknown error';
    console.error('create-midtrans-transaction failed', message);
    if (message.includes('Firebase service account secrets')) {
      return json({ error: 'Backend Firebase belum dikonfigurasi di Supabase' }, 503);
    }
    if (message.includes('Could not obtain Firebase access token')) {
      return json({ error: 'Backend tidak dapat mengakses Firestore' }, 503);
    }
    if (message.includes('Firestore read failed')) {
      return json({ error: 'Backend gagal membaca order dari Firestore' }, 503);
    }
    return json({ error: 'Gagal membuat transaksi pembayaran' }, 500);
  }
});

function json(body: Record<string, unknown>, status = 200) {
  return new Response(JSON.stringify(body), { status, headers: jsonHeaders });
}
