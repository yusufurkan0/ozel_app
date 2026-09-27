/// Kullanıcı Rolü: Öğrenci (AAC Kullanıcısı) veya Veli (Ebeveyn/Terapist).
enum UserRole {
  student,
  parent;

  String get displayName {
    switch (this) {
      case UserRole.student:
        return 'Öğrenci (Çocuk)';
      case UserRole.parent:
        return 'Veli (Ebeveyn / Terapist)';
    }
  }

  static UserRole fromString(String? val) {
    if (val == 'parent') return UserRole.parent;
    return UserRole.student;
  }
}

/// 👤 Kullanıcı Hesabı Modeli
class UserAccount {
  final String username;
  final String password;
  final UserRole role;
  final String displayName;
  final String avatar;
  final String? linkedStudentUsername; // Veli için: Bağlı olduğu öğrencinin kullanıcı adı
  final DateTime createdAt;

  UserAccount({
    required this.username,
    required this.password,
    required this.role,
    required this.displayName,
    this.avatar = '🦁',
    this.linkedStudentUsername,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isStudent => role == UserRole.student;
  bool get isParent => role == UserRole.parent;

  Map<String, dynamic> toJson() => {
        'username': username,
        'password': password,
        'role': role.name,
        'displayName': displayName,
        'avatar': avatar,
        'linkedStudentUsername': linkedStudentUsername,
        'createdAt': createdAt.toIso8601String(),
      };

  factory UserAccount.fromJson(Map<String, dynamic> json) {
    return UserAccount(
      username: json['username'] as String,
      password: json['password'] as String,
      role: UserRole.fromString(json['role'] as String?),
      displayName: json['displayName'] as String? ?? json['username'] as String,
      avatar: json['avatar'] as String? ?? '🦁',
      linkedStudentUsername: json['linkedStudentUsername'] as String?,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }

  UserAccount copyWith({
    String? password,
    String? displayName,
    String? avatar,
    String? linkedStudentUsername,
  }) {
    return UserAccount(
      username: username,
      password: password ?? this.password,
      role: role,
      displayName: displayName ?? this.displayName,
      avatar: avatar ?? this.avatar,
      linkedStudentUsername: linkedStudentUsername ?? this.linkedStudentUsername,
      createdAt: createdAt,
    );
  }
}
