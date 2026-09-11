const { onDocumentCreated, onDocumentUpdated } = require('firebase-functions/v2/firestore');
const { setGlobalOptions } = require('firebase-functions/v2');
const admin = require('firebase-admin');

admin.initializeApp();
setGlobalOptions({ region: 'asia-southeast2', maxInstances: 10 });

const db = admin.firestore();
const messaging = admin.messaging();

async function claimNotification(eventKey) {
  const reference = db.collection('notificationEvents').doc(eventKey);
  return db.runTransaction(async (transaction) => {
    const snapshot = await transaction.get(reference);
    if (snapshot.exists) return false;
    transaction.create(reference, {
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    return true;
  });
}

async function getTokensForActiveOfficers() {
  const officers = await db.collection('users').where('role', '==', 'petugas').get();
  const tokens = [];

  for (const officer of officers.docs) {
    tokens.push(...tokensFromProfile(officer.data()));
  }

  return [...new Set(tokens)];
}

function tokensFromProfile(profile) {
  const tokens = Array.isArray(profile.fcmTokens) ? profile.fcmTokens : [];
  if (typeof profile.fcmToken === 'string') tokens.push(profile.fcmToken);
  return tokens.filter((token) => typeof token === 'string' && token.trim());
}

async function sendToTokens(tokens, title, body, data) {
  if (tokens.length === 0) return;

  await messaging.sendEachForMulticast({
    tokens,
    notification: { title, body },
    data,
    android: {
      notification: {
        channelId: 'cleanpick_notifications',
        clickAction: 'FLUTTER_NOTIFICATION_CLICK',
      },
    },
  });
}

exports.notifyOfficersOnOrderCreated = onDocumentCreated('orders/{orderId}', async (event) => {
  const snapshot = event.data;
  if (!snapshot) return;

  const order = snapshot.data();
  if (order.status !== 'menunggu') return;
  if (order.paymentMethod !== 'codTunai' && order.paymentStatus !== 'lunas') return;

  const claimed = await claimNotification(`new_order_${event.id}`);
  if (!claimed) return;

  const tokens = await getTokensForActiveOfficers();
  await sendToTokens(
    tokens,
    'Pesanan Baru',
    'Ada pesanan baru yang tersedia. Buka aplikasi untuk melihat detailnya.',
    {
      type: 'new_order',
      orderId: event.params.orderId,
    },
  );
});

exports.notifyCustomerOnOrderTaken = onDocumentUpdated('orders/{orderId}', async (event) => {
  const before = event.data?.before.data();
  const after = event.data?.after.data();
  if (!before || !after) return;

  const wasTaken = before.status === 'menunggu';
  const isTaken = after.status === 'diproses' && typeof after.officerId === 'string';
  if (!wasTaken || !isTaken || before.officerId === after.officerId) return;

  const claimed = await claimNotification(`order_taken_${event.id}`);
  if (!claimed || typeof after.customerId !== 'string') return;

  const customer = await db.collection('users').doc(after.customerId).get();
  const tokens = tokensFromProfile(customer.data() || {});
  if (tokens.length === 0) return;

  await sendToTokens(
    tokens,
    'Pesanan Diambil Petugas',
    'Pesanan Anda telah diambil oleh petugas.',
    {
      type: 'order_taken',
      orderId: event.params.orderId,
    },
  );
});

exports.notifyCustomerOnOrderStatusChanged = onDocumentUpdated('orders/{orderId}', async (event) => {
  const before = event.data?.before.data();
  const after = event.data?.after.data();
  if (!before || !after || before.status === after.status) return;
  if (after.status === 'diproses') return;
  if (typeof after.customerId !== 'string') return;

  const claimed = await claimNotification(`order_status_${event.id}`);
  if (!claimed) return;
  const customer = await db.collection('users').doc(after.customerId).get();
  const tokens = tokensFromProfile(customer.data() || {});
  if (tokens.length === 0) return;

  const labels = {
    menunggu: 'Menunggu petugas',
    dijadwalkan: 'Pesanan dijadwalkan',
    selesai: 'Pesanan selesai',
    dibatalkan: 'Pesanan dibatalkan',
  };
  const label = labels[after.status] || 'Status pesanan berubah';
  await sendToTokens(tokens, 'Status Pesanan Diperbarui', label, {
    type: 'order_status',
    orderId: event.params.orderId,
    status: after.status,
  });
});

exports.notifyCustomerOnPaymentUpdated = onDocumentUpdated('payments/{orderId}', async (event) => {
  const before = event.data?.before.data();
  const after = event.data?.after.data();
  if (!before || !after || before.paymentStatus === after.paymentStatus) return;
  if (after.paymentStatus !== 'lunas' && after.paymentStatus !== 'belumBayar') return;

  const order = await db.collection('orders').doc(event.params.orderId).get();
  const orderData = order.data() || {};
  const customerId = orderData.customerId;
  if (typeof customerId !== 'string') return;
  const claimed = await claimNotification(`payment_status_${event.id}`);
  if (!claimed) return;
  const customer = await db.collection('users').doc(customerId).get();
  const tokens = tokensFromProfile(customer.data() || {});

  const paid = after.paymentStatus === 'lunas';
  if (tokens.length > 0) {
    await sendToTokens(
      tokens,
      paid ? 'Pembayaran Berhasil' : 'Status Pembayaran',
      paid ? 'Pembayaran pesanan Anda berhasil.' : 'Pembayaran pesanan belum berhasil.',
      { type: paid ? 'payment_success' : 'payment_failed', orderId: event.params.orderId },
    );
  }

  if (paid && orderData.paymentMethod !== 'codTunai') {
    const officerClaimed = await claimNotification(
      `paid_order_officers_${event.params.orderId}_${event.id}`,
    );
    if (!officerClaimed) return;
    const officerTokens = await getTokensForActiveOfficers();
    await sendToTokens(
      officerTokens,
      'Pesanan Siap Diambil',
      'Pembayaran berhasil. Pesanan baru tersedia untuk diproses.',
      { type: 'new_order', orderId: event.params.orderId },
    );
  }
});
