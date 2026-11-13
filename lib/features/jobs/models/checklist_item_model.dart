class ChecklistItemModel {
  final String id;
  final String jobId;
  final String title;
  final bool isCompleted;
  final int sortOrder;

  const ChecklistItemModel({
    required this.id,
    required this.jobId,
    required this.title,
    required this.isCompleted,
    this.sortOrder = 0,
  });

  ChecklistItemModel copyWith({
    String? id,
    String? jobId,
    String? title,
    bool? isCompleted,
    int? sortOrder,
  }) {
    return ChecklistItemModel(
      id: id ?? this.id,
      jobId: jobId ?? this.jobId,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  factory ChecklistItemModel.fromMap(Map<String, dynamic> map) {
    return ChecklistItemModel(
      id: map['id'] as String,
      jobId: map['job_id'] as String,
      title: map['title'] as String,
      isCompleted: (map['is_completed'] is bool)
          ? map['is_completed'] as bool
          : (map['is_completed'] as int? ?? 0) == 1,
      sortOrder: map['sort_order'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'job_id': jobId,
      'title': title,
      'is_completed': isCompleted ? 1 : 0,
      'sort_order': sortOrder,
    };
  }
}
