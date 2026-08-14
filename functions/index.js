const {onDocumentCreated} = require('firebase-functions/v2/firestore');
const {initializeApp} = require('firebase-admin/app');
const {getFirestore, FieldValue} = require('firebase-admin/firestore');
const {getMessaging} = require('firebase-admin/messaging');

initializeApp();
const db = getFirestore();

exports.notifyDirectMessage = onDocumentCreated(
  'conversations/{conversationId}/messages/{messageId}',
  async (event) => {
    const message = event.data?.data();
    if (!message || !message.receiverId || message.isDeleted) return;
    const receiverRef = db.collection('users').doc(message.receiverId);
    const [sender, receiver, preference] = await Promise.all([
      db.collection('users').doc(message.senderId).get(),
      receiverRef.get(),
      receiverRef.collection('contactPreferences').doc(message.senderId).get(),
    ]);
    const settings = receiver.data()?.settings || {};
    if (settings.pushNotifications === false || preference.data()?.muted === true) {
      return;
    }
    const senderName = sender.data()?.displayName || 'VonoTalky user';
    await sendToUsers(
      [message.receiverId],
      {
        title: senderName,
        body: settings.messagePreview === false
          ? 'New message'
          : preview(message),
      },
      {
        type: 'direct',
        senderId: String(message.senderId),
        conversationId: String(event.params.conversationId),
      },
    );
  },
);

exports.notifyGroupMessage = onDocumentCreated(
  'groups/{groupId}/messages/{messageId}',
  async (event) => {
    const message = event.data?.data();
    if (!message || message.isDeleted) return;
    const group = await db.collection('groups').doc(event.params.groupId).get();
    if (!group.exists) return;
    const groupData = group.data();
    const receivers = (groupData.memberIds || []).filter(
      (uid) => uid !== message.senderId,
    );
    await sendToUsers(
      receivers,
      {
        title: groupData.name || 'Group message',
        body: `${message.senderName || 'Member'}: ${preview(message)}`,
      },
      {
        type: 'group',
        groupId: String(event.params.groupId),
        senderId: String(message.senderId),
      },
    );
  },
);

function preview(message) {
  if (message.type === 'image') return '📷 Photo';
  if (message.type === 'voice') return '🎤 Voice message';
  if (message.type === 'file') return `📎 ${message.fileName || 'File'}`;
  const text = String(message.text || '').trim();
  return text.length > 120 ? `${text.slice(0, 117)}...` : text || 'New message';
}

async function sendToUsers(userIds, notification, data) {
  const uniqueIds = [...new Set(userIds)].filter(Boolean);
  if (!uniqueIds.length) return;
  const deviceSnapshots = await Promise.all(
    uniqueIds.map((uid) =>
      db.collection('users').doc(uid).collection('devices')
        .where('enabled', '==', true).get(),
    ),
  );
  const devices = [];
  for (const snapshot of deviceSnapshots) {
    for (const document of snapshot.docs) {
      const token = document.data().token;
      if (token) devices.push({token, reference: document.ref});
    }
  }
  for (let start = 0; start < devices.length; start += 500) {
    const chunk = devices.slice(start, start + 500);
    const response = await getMessaging().sendEachForMulticast({
      tokens: chunk.map((device) => device.token),
      notification,
      data,
      android: {
        priority: 'high',
        notification: {channelId: 'messages'},
      },
      apns: {
        payload: {aps: {sound: 'default', badge: 1}},
      },
    });
    const staleWrites = [];
    response.responses.forEach((result, index) => {
      const code = result.error?.code || '';
      if (
        code.includes('registration-token-not-registered') ||
        code.includes('invalid-registration-token')
      ) {
        staleWrites.push(chunk[index].reference.delete());
      }
    });
    await Promise.all(staleWrites);
  }
  await Promise.all(
    uniqueIds.map((uid) =>
      db.collection('users').doc(uid).set(
        {lastNotificationAt: FieldValue.serverTimestamp()},
        {merge: true},
      ),
    ),
  );
}
