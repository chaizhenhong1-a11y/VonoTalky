import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

import 'chat_service.dart';

class ChatBackgroundService {
  ChatBackgroundService({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
    ImagePicker? imagePicker,
    ChatService? chatService,
  }) : _firestore =
           firestore ?? FirebaseFirestore.instance,
       _storage =
           storage ?? FirebaseStorage.instance,
       _imagePicker =
           imagePicker ?? ImagePicker(),
       _chatService =
           chatService ?? ChatService();

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final ImagePicker _imagePicker;
  final ChatService _chatService;

  String get myId => _chatService.myId;

  String roomId(
    String otherId,
  ) {
    return _chatService.roomId(
      otherId,
    );
  }

  DocumentReference<Map<String, dynamic>>
  _privateRef(
    String otherId,
  ) {
    return _firestore
        .collection('users')
        .doc(myId)
        .collection('contactPreferences')
        .doc(otherId);
  }

  DocumentReference<Map<String, dynamic>>
  _sharedRef({
    required String otherId,
    required String ownerId,
  }) {
    return _firestore
        .collection('conversations')
        .doc(roomId(otherId))
        .collection('backgroundShares')
        .doc(ownerId);
  }

  /// 当前用户为「这个聊天」设置的背景。
  ///
  /// 只有当前用户自己能够读取。
  Stream<ChatBackgroundInfo> watchMine(
    String otherId,
  ) {
    return _privateRef(
      otherId,
    ).snapshots().map(
      (snapshot) {
        return ChatBackgroundInfo.fromPrivateData(
          snapshot.data(),
        );
      },
    );
  }

  /// 对方主动分享给我的背景。
  ///
  /// 如果对方没有分享，这个 document 不存在，
  /// 因此返回 null。
  Stream<SharedChatBackground?> watchOther(
    String otherId,
  ) {
    return _sharedRef(
      otherId: otherId,
      ownerId: otherId,
    ).snapshots().map(
      (snapshot) {
        if (!snapshot.exists) {
          return null;
        }

        final data = snapshot.data();

        if (data == null) {
          return null;
        }

        final imageUrl =
            data['imageUrl'];

        if (imageUrl is! String ||
            imageUrl.trim().isEmpty) {
          return null;
        }

        return SharedChatBackground(
          ownerId: otherId,
          imageUrl: imageUrl,
        );
      },
    );
  }

  /// 为「当前这个聊天」选择并上传背景。
  Future<void> pickAndUpload(
    String otherId,
  ) async {
    final file =
        await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 88,
      maxWidth: 2400,
    );

    if (file == null) {
      return;
    }

    final bytes =
        await file.readAsBytes();

    const maxBytes =
        12 * 1024 * 1024;

    if (bytes.length > maxBytes) {
      throw const ChatBackgroundException(
        'Background image must be smaller than 12 MB.',
      );
    }

    // Storage Rules 要确认当前用户属于该 conversation，
    // 所以上传之前先确保 conversation 已经存在。
    await _chatService.ensureConversation(
      otherId,
    );

    final conversationId =
        roomId(otherId);

    final contentType =
        _contentType(file);

    final extension =
        _extension(contentType);

    final storagePath =
        'chat_backgrounds/'
        '$conversationId/'
        '$myId/'
        'background.$extension';

    final privateSnapshot =
        await _privateRef(
      otherId,
    ).get();

    final oldData =
        privateSnapshot.data();

    final oldStoragePath =
        oldData?['chatBackgroundStoragePath']
            as String?;

    final currentlyShared =
        oldData?['chatBackgroundShared']
            as bool? ??
        false;

    final reference =
        _storage.ref(
      storagePath,
    );

    await reference.putData(
      bytes,
      SettableMetadata(
        contentType: contentType,
        cacheControl:
            'public,max-age=3600',
      ),
    );

    final downloadUrl =
        await reference.getDownloadURL();

    final separator =
        downloadUrl.contains('?')
        ? '&'
        : '?';

    final versionedUrl =
        '$downloadUrl'
        '${separator}v='
        '${DateTime.now().millisecondsSinceEpoch}';

    final batch =
        _firestore.batch();

    batch.set(
      _privateRef(
        otherId,
      ),
      {
        'chatBackgroundImageUrl':
            versionedUrl,
        'chatBackgroundStoragePath':
            storagePath,
        'chatBackgroundShared':
            currentlyShared,
        'chatBackgroundUpdatedAt':
            FieldValue.serverTimestamp(),
      },
      SetOptions(
        merge: true,
      ),
    );

    // 如果用户之前已经允许对方查看，
    // 那么更换图片之后保持分享状态。
    if (currentlyShared) {
      batch.set(
        _sharedRef(
          otherId: otherId,
          ownerId: myId,
        ),
        {
          'ownerId': myId,
          'imageUrl': versionedUrl,
          'updatedAt':
              FieldValue.serverTimestamp(),
        },
      );
    }

    await batch.commit();

    // 如果图片格式改变，例如 png -> jpg，
    // 删除旧的 Storage 文件。
    if (oldStoragePath != null &&
        oldStoragePath !=
            storagePath) {
      try {
        await _storage
            .ref(oldStoragePath)
            .delete();
      } catch (_) {
        // 旧文件清理失败不能影响新背景。
      }
    }
  }

  /// 设置：
  /// 是否允许「当前聊天的对方」查看我的背景。
  Future<void> setShared({
    required String otherId,
    required bool shared,
  }) async {
    await _chatService.ensureConversation(
      otherId,
    );

    final privateSnapshot =
        await _privateRef(
      otherId,
    ).get();

    final data =
        privateSnapshot.data();

    if (shared) {
      final imageUrl =
          data?['chatBackgroundImageUrl'];

      if (imageUrl is! String ||
          imageUrl.trim().isEmpty) {
        throw const ChatBackgroundException(
          'Choose a background before sharing it.',
        );
      }

      final batch =
          _firestore.batch();

      batch.set(
        _privateRef(
          otherId,
        ),
        {
          'chatBackgroundShared':
              true,
          'chatBackgroundUpdatedAt':
              FieldValue.serverTimestamp(),
        },
        SetOptions(
          merge: true,
        ),
      );

      batch.set(
        _sharedRef(
          otherId: otherId,
          ownerId: myId,
        ),
        {
          'ownerId': myId,
          'imageUrl': imageUrl,
          'updatedAt':
              FieldValue.serverTimestamp(),
        },
      );

      await batch.commit();

      return;
    }

    final batch =
        _firestore.batch();

    batch.set(
      _privateRef(
        otherId,
      ),
      {
        'chatBackgroundShared':
            false,
        'chatBackgroundUpdatedAt':
            FieldValue.serverTimestamp(),
      },
      SetOptions(
        merge: true,
      ),
    );

    batch.delete(
      _sharedRef(
        otherId: otherId,
        ownerId: myId,
      ),
    );

    await batch.commit();
  }

  /// 删除「这个聊天」自己的背景。
  Future<void> remove(
    String otherId,
  ) async {
    final snapshot =
        await _privateRef(
      otherId,
    ).get();

    final data =
        snapshot.data();

    final storagePath =
        data?['chatBackgroundStoragePath']
            as String?;

    // 先从数据库撤销分享，
    // 对方会立即失去这个背景。
    final batch =
        _firestore.batch();

    batch.set(
      _privateRef(
        otherId,
      ),
      {
        'chatBackgroundImageUrl':
            FieldValue.delete(),
        'chatBackgroundStoragePath':
            FieldValue.delete(),
        'chatBackgroundShared':
            false,
        'chatBackgroundUpdatedAt':
            FieldValue.serverTimestamp(),
      },
      SetOptions(
        merge: true,
      ),
    );

    batch.delete(
      _sharedRef(
        otherId: otherId,
        ownerId: myId,
      ),
    );

    await batch.commit();

    if (storagePath == null ||
        storagePath.isEmpty) {
      return;
    }

    try {
      await _storage
          .ref(storagePath)
          .delete();
    } catch (_) {
      // Firestore 权限已经撤销，
      // Storage 清理失败不应该让 UI 删除失败。
    }
  }

  String _contentType(
    XFile file,
  ) {
    final reported =
        file.mimeType;

    if (reported != null &&
        reported.startsWith(
          'image/',
        )) {
      return reported;
    }

    final path =
        file.path.toLowerCase();

    if (path.endsWith('.png')) {
      return 'image/png';
    }

    if (path.endsWith('.webp')) {
      return 'image/webp';
    }

    if (path.endsWith('.heic') ||
        path.endsWith('.heif')) {
      return 'image/heic';
    }

    return 'image/jpeg';
  }

  String _extension(
    String contentType,
  ) {
    return switch (contentType) {
      'image/png' => 'png',
      'image/webp' => 'webp',
      'image/heic' ||
      'image/heif' => 'heic',
      _ => 'jpg',
    };
  }
}

class ChatBackgroundInfo {
  const ChatBackgroundInfo({
    required this.imageUrl,
    required this.shared,
  });

  final String? imageUrl;

  /// 是否把「这个聊天的背景」
  /// 分享给聊天另一方。
  final bool shared;

  bool get hasImage {
    return imageUrl != null &&
        imageUrl!.trim().isNotEmpty;
  }

  factory ChatBackgroundInfo.fromPrivateData(
    Map<String, dynamic>? data,
  ) {
    final rawUrl =
        data?['chatBackgroundImageUrl'];

    return ChatBackgroundInfo(
      imageUrl:
          rawUrl is String &&
              rawUrl.trim().isNotEmpty
          ? rawUrl
          : null,
      shared:
          data?['chatBackgroundShared']
              as bool? ??
          false,
    );
  }
}

class SharedChatBackground {
  const SharedChatBackground({
    required this.ownerId,
    required this.imageUrl,
  });

  final String ownerId;
  final String imageUrl;
}

class ChatBackgroundException
    implements Exception {
  const ChatBackgroundException(
    this.message,
  );

  final String message;

  @override
  String toString() {
    return message;
  }
}