import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  AuthService(this._auth);

  final FirebaseAuth _auth;
  late final Stream<User?> changes = _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<void> register(String email, String password) async {
    await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signIn(String email, String password) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signOut() => _auth.signOut();

  Future<void> updatePassword(
    String password, {
    String? currentPassword,
  }) async {
    final user = currentUser;
    if (user == null) throw FirebaseAuthException(code: 'user-not-found');
    if (currentPassword != null) {
      final email = user.email;
      if (email == null) {
        throw FirebaseAuthException(code: 'invalid-credential');
      }
      await user.reauthenticateWithCredential(
        EmailAuthProvider.credential(email: email, password: currentPassword),
      );
    }
    await user.updatePassword(password);
  }
}

String authMessage(String code) => switch (code) {
  'invalid-email' => 'Check the email address and try again.',
  'weak-password' =>
    'Choose a password that meets the project’s password policy.',
  'email-already-in-use' => 'Could not create an account. Try signing in.',
  'invalid-credential' ||
  'wrong-password' ||
  'user-not-found' => 'Check your credentials and try again.',
  'network-request-failed' => 'Check your internet connection and try again.',
  'too-many-requests' =>
    'Too many attempts. Wait a moment before trying again.',
  _ => 'That action could not be completed. Please try again.',
};
