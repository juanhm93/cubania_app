/// The signed-in student, as returned by `GET /me` and `POST /auth/verify-code`.
class StudentProfile {
  const StudentProfile({
    required this.id,
    required this.name,
    required this.email,
    this.dni,
    this.phone,
    this.birthday,
    this.currentLevel,
  });

  factory StudentProfile.fromJson(Map<String, dynamic> json) {
    final birthday = json['birthday'] as String?;
    final level = json['current_level'] as Map<String, dynamic>?;

    return StudentProfile(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      dni: json['dni'] as String?,
      phone: json['phone'] as String?,
      birthday: birthday == null ? null : DateTime.parse(birthday),
      currentLevel: level == null ? null : Level.fromJson(level),
    );
  }

  final int id;
  final String name;
  final String email;
  final String? dni;
  final String? phone;
  final DateTime? birthday;

  /// Level of the student's active course; null when the enrollment ended.
  final Level? currentLevel;

  /// First name, for greetings.
  String get firstName => name.trim().split(RegExp(r'\s+')).first;
}

class Level {
  const Level({
    required this.id,
    required this.name,
    required this.slug,
    this.danceType,
  });

  factory Level.fromJson(Map<String, dynamic> json) {
    final danceType = json['dance_type'] as Map<String, dynamic>?;

    return Level(
      id: json['id'] as int,
      name: json['name'] as String,
      slug: json['slug'] as String,
      danceType: danceType == null ? null : DanceType.fromJson(danceType),
    );
  }

  final int id;
  final String name;
  final String slug;
  final DanceType? danceType;
}

class DanceType {
  const DanceType({required this.id, required this.name});

  factory DanceType.fromJson(Map<String, dynamic> json) {
    return DanceType(id: json['id'] as int, name: json['name'] as String);
  }

  final int id;
  final String name;
}
