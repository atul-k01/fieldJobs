import 'dart:convert';

class SyncQueueItem {
  final String id;
  final String jobId;
  final String actionType; // update_status, cannot_complete, update_checklist, save_notes, attach_photo
  final Map<String, dynamic> payload;
  final int baseVersion; // Version at the time of modification on the client
  final String createdAt;
  final int retryCount;
  final String status; // pending, in_flight, failed, completed

  const SyncQueueItem({
    required this.id,
    required this.jobId,
    required this.actionType,
    required this.payload,
    required this.baseVersion,
    required this.createdAt,
    this.retryCount = 0,
    this.status = 'pending',
  });

  SyncQueueItem copyWith({
    String? id,
    String? jobId,
    String? actionType,
    Map<String, dynamic>? payload,
    int? baseVersion,
    String? createdAt,
    int? retryCount,
    String? status,
  }) {
    return SyncQueueItem(
      id: id ?? this.id,
      jobId: jobId ?? this.jobId,
      actionType: actionType ?? this.actionType,
      payload: payload ?? this.payload,
      baseVersion: baseVersion ?? this.baseVersion,
      createdAt: createdAt ?? this.createdAt,
      retryCount: retryCount ?? this.retryCount,
      status: status ?? this.status,
    );
  }

  factory SyncQueueItem.fromMap(Map<String, dynamic> map) {
    Map<String, dynamic> decodedPayload = {};
    if (map['payload'] is String) {
      try {
        decodedPayload = jsonDecode(map['payload'] as String) as Map<String, dynamic>;
      } catch (_) {}
    } else if (map['payload'] is Map<String, dynamic>) {
      decodedPayload = map['payload'] as Map<String, dynamic>;
    }

    return SyncQueueItem(
      id: map['id'] as String,
      jobId: map['job_id'] as String,
      actionType: map['action_type'] as String,
      payload: decodedPayload,
      baseVersion: map['base_version'] as int? ?? 1,
      createdAt: map['created_at'] as String,
      retryCount: map['retry_count'] as int? ?? 0,
      status: map['status'] as String? ?? 'pending',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'job_id': jobId,
      'action_type': actionType,
      'payload': jsonEncode(payload),
      'base_version': baseVersion,
      'created_at': createdAt,
      'retry_count': retryCount,
      'status': status,
    };
  }
}
