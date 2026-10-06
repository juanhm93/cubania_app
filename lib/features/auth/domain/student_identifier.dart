/// How the student identifies themselves: by email or by cédula (DNI).
class StudentIdentifier {
  const StudentIdentifier.email(String value) : email = value, dni = null;

  const StudentIdentifier.dni(String value) : dni = value, email = null;

  final String? email;
  final String? dni;

  bool get isEmail => email != null;

  /// What the student typed, to show it back to them.
  String get value => email ?? dni!;

  Map<String, dynamic> toJson() => isEmail ? {'email': email} : {'dni': dni};
}
