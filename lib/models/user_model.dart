class UserModel {
  final String uid;
  final String email;
  final String parentName;
  final String studentName;
  final String className;
  final String role;
  final double saldo;

  UserModel({
    required this.uid, required this.email, required this.parentName,
    required this.studentName, required this.className, required this.role,
    required this.saldo,
  });

  factory UserModel.fromSupabase(Map<String, dynamic> data) {
    return UserModel(
      uid: data['id'] ?? '',
      email: data['email'] ?? '',
      parentName: data['parent_name'] ?? '',
      studentName: data['student_name'] ?? '',
      className: data['class_name'] ?? '',
      role: data['role'] ?? 'user',
      saldo: (data['saldo'] as num?)?.toDouble() ?? 0.0,
    );
  }
}