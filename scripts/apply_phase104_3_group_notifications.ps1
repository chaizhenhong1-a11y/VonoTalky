param(
    [string]$ProjectRoot = "C:\flutter project\vonotalky"
)

$ErrorActionPreference = 'Stop'
$indexPath = Join-Path $ProjectRoot 'functions\index.js'

if (-not (Test-Path $indexPath)) {
    throw "Missing file: $indexPath"
}

$content = Get-Content -Raw -Encoding UTF8 $indexPath

if ($content -match 'exports\.onGroupMessageCreated\s*=') {
    Write-Host 'onGroupMessageCreated already exists; no functions/index.js patch needed.' -ForegroundColor Yellow
    exit 0
}

$function = @'

exports.onGroupMessageCreated = onDocumentCreated(
  "groups/{groupId}/messages/{messageId}",
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) return;

    const message = snapshot.data();
    const senderId = message.senderId;
    const groupId = event.params.groupId;
    const messageId = event.params.messageId;

    if (typeof senderId !== "string" || senderId.length === 0) {
      logger.warn("Group message has no valid senderId.", {
        groupId,
        messageId,
      });
      return;
    }

    const groupSnapshot = await db.collection("groups").doc(groupId).get();
    if (!groupSnapshot.exists) {
      logger.warn("Group message references a missing group.", {
        groupId,
        messageId,
      });
      return;
    }

    const group = groupSnapshot.data();
    const members = Array.isArray(group.memberIds) ? group.memberIds : [];

    if (!members.includes(senderId)) {
      logger.warn("Group message sender is not a group member.", {
        groupId,
        messageId,
        senderId,
      });
      return;
    }

    const receivers = [...new Set(members)].filter(
      (uid) => typeof uid === "string" && uid.length > 0 && uid !== senderId,
    );
    if (receivers.length === 0) return;

    const groupName =
      typeof group.name === "string" && group.name.trim().length > 0
        ? group.name.trim()
        : "Group chat";

    let senderName =
      typeof message.senderName === "string" &&
      message.senderName.trim().length > 0
        ? message.senderName.trim()
        : "VonoTalky user";

    if (senderName === "VonoTalky user") {
      const senderSnapshot = await db.collection("users").doc(senderId).get();
      const sender = senderSnapshot.exists ? senderSnapshot.data() : {};
      senderName =
        typeof sender.name === "string" && sender.name.trim().length > 0
          ? sender.name.trim()
          : typeof sender.displayName === "string" &&
              sender.displayName.trim().length > 0
            ? sender.displayName.trim()
            : typeof sender.username === "string" &&
                sender.username.trim().length > 0
              ? sender.username.trim()
              : "VonoTalky user";
    }

    const type =
      typeof message.type === "string" ? message.type.toLowerCase() : "text";
    let preview;
    switch (type) {
      case "image":
        preview = "📷 Photo";
        break;
      case "voice":
      case "audio":
        preview = "🎤 Voice message";
        break;
      case "file":
        preview =
          typeof message.fileName === "string" &&
          message.fileName.trim().length > 0
            ? `📎 ${message.fileName.trim()}`
            : "📎 File";
        break;
      default: {
        const text =
          typeof message.text === "string" ? message.text.trim() : "";
        preview = text.length > 0 ? text.slice(0, 140) : "New message";
      }
    }

    const results = await Promise.allSettled(
      receivers.map((receiverId) =>
        sendToUser({
          userId: receiverId,
          title: groupName,
          body: `${senderName}: ${preview}`,
          excludeConversationId: `group_${groupId}`,
          data: {
            type: "group_message",
            groupId,
            messageId,
            senderId,
            conversationId: `group_${groupId}`,
            friendId: "",
            petId: "",
            inviteId: "",
            careRequestId: "",
          },
        }),
      ),
    );

    const failed = results.filter((result) => result.status === "rejected");
    if (failed.length > 0) {
      logger.error("Some group notifications failed.", {
        groupId,
        messageId,
        senderId,
        receiverCount: receivers.length,
        failureCount: failed.length,
      });
    } else {
      logger.info("Group notification fan-out completed.", {
        groupId,
        messageId,
        senderId,
        receiverCount: receivers.length,
      });
    }
  },
);
'@

$newContent = $content.TrimEnd() + "`r`n" + $function.TrimStart() + "`r`n"
[System.IO.File]::WriteAllText(
    $indexPath,
    $newContent,
    [System.Text.UTF8Encoding]::new($false)
)

Write-Host 'Added onGroupMessageCreated to functions/index.js.' -ForegroundColor Green
Write-Host 'IMPORTANT: deploy Functions after applying this patch.' -ForegroundColor Yellow
