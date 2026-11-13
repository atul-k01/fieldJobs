import 'checklist_item_model.dart';
import 'job_photo_model.dart';

class JobModel {
  final String id;
  final String assignedTo;
  final String customerName;
  final String customerPhone;
  final String address;
  final String scheduledDate; // YYYY-MM-DD
  final String timeWindow; // e.g. "09:00 - 11:00 AM"
  final String appliance;
  final String problemDescription;
  final String status; // assigned, travelling, on_site, completed, could_not_complete, cancelled
  final String? cannotCompleteReason;
  final String? technicianNotes;
  final int version; // Server optimistic lock version
  final String syncStatus; // synced, pending, conflict
  final String updatedAt;
  final List<ChecklistItemModel> checklists;
  final List<JobPhotoModel> photos;

  const JobModel({
    required this.id,
    required this.assignedTo,
    required this.customerName,
    required this.customerPhone,
    required this.address,
    required this.scheduledDate,
    required this.timeWindow,
    required this.appliance,
    required this.problemDescription,
    required this.status,
    this.cannotCompleteReason,
    this.technicianNotes,
    this.version = 1,
    this.syncStatus = 'synced',
    required this.updatedAt,
    this.checklists = const [],
    this.photos = const [],
  });

  bool get isCompleted => status == 'completed';
  bool get isCouldNotComplete => status == 'could_not_complete';
  bool get isCancelled => status == 'cancelled';
  bool get isDone => isCompleted || isCouldNotComplete || isCancelled;

  /// True if job was scheduled before today and is still unfinished (needs technician attention)
  bool get isOverdue {
    if (isDone) return false;
    try {
      final parsed = DateTime.parse(scheduledDate);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final jobDate = DateTime(parsed.year, parsed.month, parsed.day);
      return jobDate.isBefore(today);
    } catch (_) {
      return false;
    }
  }

  /// True if job is scheduled for a future date (tomorrow or later)
  bool get isUpcoming {
    if (isDone) return false;
    try {
      final parsed = DateTime.parse(scheduledDate);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final jobDate = DateTime(parsed.year, parsed.month, parsed.day);
      return jobDate.isAfter(today);
    } catch (_) {
      return false;
    }
  }

  bool get isPendingSync => syncStatus == 'pending';
  bool get hasConflict => syncStatus == 'conflict';

  JobModel copyWith({
    String? id,
    String? assignedTo,
    String? customerName,
    String? customerPhone,
    String? address,
    String? scheduledDate,
    String? timeWindow,
    String? appliance,
    String? problemDescription,
    String? status,
    String? cannotCompleteReason,
    String? technicianNotes,
    int? version,
    String? syncStatus,
    String? updatedAt,
    List<ChecklistItemModel>? checklists,
    List<JobPhotoModel>? photos,
  }) {
    return JobModel(
      id: id ?? this.id,
      assignedTo: assignedTo ?? this.assignedTo,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      address: address ?? this.address,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      timeWindow: timeWindow ?? this.timeWindow,
      appliance: appliance ?? this.appliance,
      problemDescription: problemDescription ?? this.problemDescription,
      status: status ?? this.status,
      cannotCompleteReason: cannotCompleteReason ?? this.cannotCompleteReason,
      technicianNotes: technicianNotes ?? this.technicianNotes,
      version: version ?? this.version,
      syncStatus: syncStatus ?? this.syncStatus,
      updatedAt: updatedAt ?? this.updatedAt,
      checklists: checklists ?? this.checklists,
      photos: photos ?? this.photos,
    );
  }

  factory JobModel.fromMap(
    Map<String, dynamic> map, {
    List<ChecklistItemModel> checklists = const [],
    List<JobPhotoModel> photos = const [],
  }) {
    return JobModel(
      id: map['id'] as String,
      assignedTo: map['assigned_to'] as String,
      customerName: map['customer_name'] as String,
      customerPhone: map['customer_phone'] as String? ?? '',
      address: map['address'] as String,
      scheduledDate: map['scheduled_date'] as String,
      timeWindow: map['time_window'] as String,
      appliance: map['appliance'] as String,
      problemDescription: map['problem_description'] as String,
      status: map['status'] as String,
      cannotCompleteReason: map['cannot_complete_reason'] as String?,
      technicianNotes: map['technician_notes'] as String?,
      version: map['version'] as int? ?? 1,
      syncStatus: map['sync_status'] as String? ?? 'synced',
      updatedAt: map['updated_at'] as String,
      checklists: checklists,
      photos: photos,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'assigned_to': assignedTo,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'address': address,
      'scheduled_date': scheduledDate,
      'time_window': timeWindow,
      'appliance': appliance,
      'problem_description': problemDescription,
      'status': status,
      'cannot_complete_reason': cannotCompleteReason,
      'technician_notes': technicianNotes,
      'version': version,
      'sync_status': syncStatus,
      'updated_at': updatedAt,
    };
  }
}
