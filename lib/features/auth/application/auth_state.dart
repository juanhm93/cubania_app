import '../domain/student_profile.dart';

/// Where the app stands with the student's session.
sealed class AuthState {
  const AuthState();
}

/// Launching: checking whether a stored token is still valid.
class AuthChecking extends AuthState {
  const AuthChecking();
}

class AuthSignedOut extends AuthState {
  const AuthSignedOut({this.message});

  /// Optional reason to show on the login screen (for example, an expired session).
  final String? message;
}

class AuthSignedIn extends AuthState {
  const AuthSignedIn(this.student);

  final StudentProfile student;
}

/// There is a stored token, but the profile could not be loaded (no connection,
/// server down). The token is kept so the student can retry without signing in again.
class AuthRestoreFailed extends AuthState {
  const AuthRestoreFailed(this.message);

  final String message;
}
