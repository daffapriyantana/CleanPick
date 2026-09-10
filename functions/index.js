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
  const officers = await db.collection('officers').where('status', '==', 'aktif').get();
  const tokens = [];

  for (const officer of officers.docs) {
    const data = officer.data();
    const uid = data.uid || data.officerId || data.officerid || officer.id;
    const profile = await db.collection('users').doc(uid).get();
    const token = profile.data()?.fcmToken;
    if (typeof token === 'string' && token.trim()) tokens.push(token);
  }

  return [...new Set(tokens)];
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
  const token = customer.data()?.fcmToken;
  if (typeof token !== 'string' || !token.trim()) return;

  await sendToTokens(
    [token],
    'Pesanan Diambil Petugas',
    'Pesanan Anda telah diambil oleh petugas.',
    {
      type: 'order_taken',
      orderId: event.params.orderId,
    },
  );
});
