class JobPhotoModel {
  final String id;
  final String jobId;
  final String localPath;
  final String? remoteUrl;
  final String createdAt;

  const JobPhotoModel({
    required this.id,
    required this.jobId,
    required this.localPath,
    this.remoteUrl,
    required this.createdAt,
  });

  JobPhotoModel copyWith({
    String? id,
    String? jobId,
    String? localPath,
    String? remoteUrl,
    String? createdAt,
  }) {
    return JobPhotoModel(
      id: id ?? this.id,
      jobId: jobId ?? this.jobId,
      localPath: localPath ?? this.localPath,
      remoteUrl: remoteUrl ?? this.remoteUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory JobPhotoModel.fromMap(Map<String, dynamic> map) {
    return JobPhotoModel(
      id: map['id'] as String,
      jobId: map['job_id'] as String,
      localPath: map['local_path'] as String,
      remoteUrl: map['remote_url'] as String?,
      createdAt: map['created_at'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'job_id': jobId,
      'local_path': localPath,
      'remote_url': remoteUrl,
      'created_at': createdAt,
    };
  }
}
