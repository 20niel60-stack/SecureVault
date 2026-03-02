class UserModel {
  final String uid;
  final String? displayName;
  final String? email;

  const UserModel({
    required this.uid,
    required this.displayName,
    required this.email,
  });

  UserModel copyWith({
    String? uid,
    String? displayName,
    String? email,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
    );
  }
}