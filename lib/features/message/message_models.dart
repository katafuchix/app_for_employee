// -----------------------------------------------------------------------------
// Message Model
// -----------------------------------------------------------------------------

import 'package:cloud_firestore/cloud_firestore.dart';

import '../operation/models/meta_data_model.dart';

class Message {
  final String id;
  final String senderId;
  final List<String> receiverIds;

  // 未読・未チェック管理 (MD仕様: array-contains用)
  final List<String> unreadWorkerIds;
  final List<String> uncheckedWorkerIds;

  // スケジュール関連
  final bool isScheduled;
  final DateTime scheduleDate;

  final String content;

  // チェック・制約設定
  final bool isCheckRequired;
  final bool isCheckShared;
  final DateTime? checkDeadline;
  final bool isImageRequiredWhileCheck;
  final bool isOperationAnnouncementRequired;

  // 記録データ
  final Map<String, DateTime> readTimeMap;
  final Map<String, DateTime> checkedTimeMap;
  final String? sharedCheckedWorkerId; // 共有チェック完了者ID (未完了時はnull)

  // アナウンス関連
  final List<String> announcedWorkerIds;
  final Map<String, DateTime> announcedTimeMap;

  final int imageCount; // 画像枚数
  final int replyCount; // 返信数

  // メタデータ (作成日・更新日等)
  final Metadata metadata;

  const Message({
    required this.id,
    required this.senderId,
    required this.receiverIds,
    required this.unreadWorkerIds,
    required this.uncheckedWorkerIds,
    required this.isScheduled,
    required this.scheduleDate,
    required this.content,
    required this.isCheckRequired,
    required this.isCheckShared,
    this.checkDeadline,
    required this.isImageRequiredWhileCheck,
    required this.isOperationAnnouncementRequired,
    required this.readTimeMap,
    required this.checkedTimeMap,
    this.sharedCheckedWorkerId,
    required this.announcedWorkerIds,
    required this.announcedTimeMap,
    required this.imageCount,
    required this.replyCount,
    required this.metadata,
  });

  static Map<String, DateTime> _convertTimestampMap(
    Map<String, dynamic>? data,
  ) {
    if (data == null) return {};
    return data.map((key, value) {
      if (value is Timestamp) {
        return MapEntry(key, value.toDate());
      } else {
        return MapEntry(key, DateTime.fromMillisecondsSinceEpoch(0));
      }
    });
  }

  factory Message.fromMap(Map<String, dynamic> data, String docId) {
    return Message(
      id: docId,
      senderId: data['sender_id'] ?? '',
      receiverIds: List<String>.from(data['receiver_ids'] ?? []),
      unreadWorkerIds: List<String>.from(data['unread_worker_ids'] ?? []),
      uncheckedWorkerIds: List<String>.from(data['unchecked_worker_ids'] ?? []),
      isScheduled: data['is_scheduled'] ?? false,
      scheduleDate: (data['schedule_date'] as Timestamp).toDate(),
      content: data['content'] ?? '',
      isCheckRequired: data['is_check_required'] ?? false,
      isCheckShared: data['is_check_shared'] ?? false,
      checkDeadline: (data['check_deadline'] as Timestamp?)?.toDate(),
      isImageRequiredWhileCheck: data['is_image_required_while_check'] ?? false,
      isOperationAnnouncementRequired:
          data['is_operation_announcement_required'] ?? false,
      readTimeMap: _convertTimestampMap(data['read_time_map']),
      checkedTimeMap: _convertTimestampMap(data['checked_time_map']),
      sharedCheckedWorkerId: data['shared_checked_worker_id'] != ""
          ? data['shared_checked_worker_id']
          : null,
      announcedWorkerIds: List<String>.from(data['announced_worker_ids'] ?? []),
      announcedTimeMap: _convertTimestampMap(data['announced_time_map']),
      imageCount: data['image_count'] ?? 0,
      replyCount: data['reply_count'] ?? 0,
      metadata: Metadata.fromMap(data['metadata'] ?? Metadata.empty()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sender_id': senderId,
      'receiver_ids': receiverIds,
      'unread_worker_ids': unreadWorkerIds,
      'unchecked_worker_ids': uncheckedWorkerIds,
      'is_scheduled': isScheduled,
      'schedule_date': Timestamp.fromDate(scheduleDate),
      'content': content,
      'is_check_required': isCheckRequired,
      'is_check_shared': isCheckShared,
      'check_deadline': checkDeadline != null
          ? Timestamp.fromDate(checkDeadline!)
          : null,
      'is_image_required_while_check': isImageRequiredWhileCheck,
      'is_operation_announcement_required': isOperationAnnouncementRequired,
      'read_time_map': readTimeMap.map(
        (key, value) => MapEntry(key, Timestamp.fromDate(value)),
      ),
      'checked_time_map': checkedTimeMap.map(
        (key, value) => MapEntry(key, Timestamp.fromDate(value)),
      ),
      'shared_checked_worker_id': sharedCheckedWorkerId ?? "",
      'announced_worker_ids': announcedWorkerIds,
      'announced_time_map': announcedTimeMap.map(
        (key, value) => MapEntry(key, Timestamp.fromDate(value)),
      ),
      'image_count': imageCount,
      'reply_count': replyCount,
      'metadata': metadata.toMap(),
    };
  }

  Message copyWith({
    String? id,
    String? senderId,
    List<String>? receiverIds,
    List<String>? unreadWorkerIds,
    List<String>? uncheckedWorkerIds,
    bool? isScheduled,
    DateTime? scheduleDate,
    String? content,
    bool? isCheckRequired,
    bool? isCheckShared,
    DateTime? checkDeadline,
    bool? isImageRequiredWhileCheck,
    bool? isOperationAnnouncementRequired,
    Map<String, DateTime>? readTimeMap,
    Map<String, DateTime>? checkedTimeMap,
    String? sharedCheckedWorkerId,
    List<String>? announcedWorkerIds,
    Map<String, DateTime>? announcedTimeMap,
    int? imageCount,
    int? replyCount,
    Metadata? metadata,
  }) {
    return Message(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverIds: receiverIds ?? this.receiverIds,
      unreadWorkerIds: unreadWorkerIds ?? this.unreadWorkerIds,
      uncheckedWorkerIds: uncheckedWorkerIds ?? this.uncheckedWorkerIds,
      isScheduled: isScheduled ?? this.isScheduled,
      scheduleDate: scheduleDate ?? this.scheduleDate,
      content: content ?? this.content,
      isCheckRequired: isCheckRequired ?? this.isCheckRequired,
      isCheckShared: isCheckShared ?? this.isCheckShared,
      checkDeadline: checkDeadline ?? this.checkDeadline,
      isImageRequiredWhileCheck:
          isImageRequiredWhileCheck ?? this.isImageRequiredWhileCheck,
      isOperationAnnouncementRequired:
          isOperationAnnouncementRequired ??
          this.isOperationAnnouncementRequired,
      readTimeMap: readTimeMap ?? this.readTimeMap,
      checkedTimeMap: checkedTimeMap ?? this.checkedTimeMap,
      sharedCheckedWorkerId:
          sharedCheckedWorkerId ?? this.sharedCheckedWorkerId,
      announcedWorkerIds: announcedWorkerIds ?? this.announcedWorkerIds,
      announcedTimeMap: announcedTimeMap ?? this.announcedTimeMap,
      imageCount: imageCount ?? this.imageCount,
      replyCount: replyCount ?? this.replyCount,
      metadata: metadata ?? this.metadata,
    );
  }
}

// -----------------------------------------------------------------------------
// Message Action Model
// -----------------------------------------------------------------------------

class MessageAction {
  final String id;
  final String messageId;
  final String messageSenderId;
  final String actorId;
  final List<String> actionTypes; // (check, reply, image)
  final String? replyFromReceiver;
  final bool isRead;
  final Metadata metadata;

  const MessageAction({
    required this.id,
    required this.messageId,
    required this.messageSenderId,
    required this.actorId,
    required this.actionTypes,
    this.replyFromReceiver,
    required this.isRead,
    required this.metadata,
  });

  factory MessageAction.fromMap(Map<String, dynamic> data, String docId) {
    return MessageAction(
      id: docId,
      messageId: data['message_id'] ?? '',
      messageSenderId: data['message_sender_id'] ?? '',
      actorId: data['actor_id'] ?? '',
      actionTypes: List<String>.from(data['action_types'] ?? []),
      replyFromReceiver: data['reply_from_receiver'],
      isRead: data['is_read'] ?? false,
      metadata: Metadata.fromMap(data['metadata'] ?? Metadata.empty()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'message_id': messageId,
      'message_sender_id': messageSenderId,
      'actor_id': actorId,
      'action_types': actionTypes,
      'reply_from_receiver': replyFromReceiver,
      'is_read': isRead,
      'metadata': metadata.toMap(),
    };
  }

  MessageAction copyWith({
    String? id,
    String? messageId,
    String? messageSenderId,
    String? actorId,
    List<String>? actionTypes,
    String? replyFromReceiver,
    bool? isRead,
    Metadata? metadata,
  }) {
    return MessageAction(
      id: id ?? this.id,
      messageId: messageId ?? this.messageId,
      messageSenderId: messageSenderId ?? this.messageSenderId,
      actorId: actorId ?? this.actorId,
      actionTypes: actionTypes ?? this.actionTypes,
      replyFromReceiver: replyFromReceiver ?? this.replyFromReceiver,
      isRead: isRead ?? this.isRead,
      metadata: metadata ?? this.metadata,
    );
  }
}

class UserProfile {
  final String id;
  final String displayName;

  const UserProfile({required this.id, required this.displayName});
}
