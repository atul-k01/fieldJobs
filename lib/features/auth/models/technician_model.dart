class TechnicianModel {
  final String id;
  final String email;
  final String name;

  const TechnicianModel({
    required this.id,
    required this.email,
    required this.name,
  });

  factory TechnicianModel.fromMap(Map<String, dynamic> map) {
    return TechnicianModel(
      id: map['id'] as String,
      email: map['email'] as String,
      name: map['name'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'name': name,
    };
  }
}
