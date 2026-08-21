const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const {getFirestore} = require("firebase-admin/firestore");
const {getMessaging} = require("firebase-admin/messaging");

/**
 * Sends a high-priority FCM notification when a one-to-one audio call starts.
 *
 * Add this single line to functions/index.js:
 * exports.onCallCreated = require("./call_notifications").onCallCreated;
 *
 * The existing index.js remains responsible for Firebase Admin initialization.
 */
exports.onCallCreated = onDocumentCreated("calls/{callId}", async (event) => {
  const snapshot = event.data;
  if (!snapshot) return;

  const call = snapshot.data() || {};
  if (
    call.type !== "audio" ||
    call.status !== "ringing" ||
    typeof call.calleeId !== "string" ||
    !call.calleeId
  ) {
    return;
  }

  const db = getFirestore();
  const deviceSnapshot = await db
    .collection("users")
    .doc(call.calleeId)
    .collection("devices")
    .get();

  const tokens = [
    ...new Set(
      deviceSnapshot.docs
        .map((document) => {
          const data = document.data() || {};
          return data.token || data.fcmToken || data.messagingToken || null;
        })
        .filter((token) => typeof token === "string" && token.length > 20),
    ),
  ];

  if (tokens.length === 0) return;

  const callerName =
    typeof call.callerName === "string" && call.callerName.trim()
      ? call.callerName.trim()
      : "VonoTalky user";

  const callerPhotoUrl =
    typeof call.callerPhotoUrl === "string" ? call.callerPhotoUrl : "";

  const response = await getMessaging().sendEachForMulticast({
    tokens,
    data: {
      type: "incoming_call",
      callId: snapshot.id,
      callerId: String(call.callerId || ""),
      callerName,
      callerPhotoUrl,
    },
    android: {
      priority: "high",
      ttl: 60000,
    },
  });

  const invalidTokens = [];
  response.responses.forEach((result, index) => {
    if (result.success) return;

    const code = result.error && result.error.code;
    if (
      code === "messaging/registration-token-not-registered" ||
      code === "messaging/invalid-registration-token"
    ) {
      invalidTokens.push(tokens[index]);
    }
  });

  if (invalidTokens.length === 0) return;

  const batch = db.batch();
  for (const document of deviceSnapshot.docs) {
    const data = document.data() || {};
    const token = data.token || data.fcmToken || data.messagingToken;
    if (invalidTokens.includes(token)) {
      batch.delete(document.ref);
    }
  }
  await batch.commit();
});
