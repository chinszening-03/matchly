import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {

  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Email Sign Up
  Future<User?> signUpWithEmail(String email, String password) async {

    try {

      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      return userCredential.user; 

    } catch (e) {
      print(e);
      return null;
    }
  }

  Future<void> logout() async {
  await FirebaseAuth.instance.signOut();
}

  Future<User?> signInWithEmail(String email, String password) async {
  
  try {

    UserCredential userCredential =
        await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    return userCredential.user;

  } catch (e) {
    print("Login Error: $e");
    return null;
  }
}

  /// Google Sign In
  Future<User?> signInWithGoogle() async {

    try {

      final GoogleSignInAccount? googleUser =
          await GoogleSignIn().signIn();

      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      return userCredential.user;

    } catch (e) {
      print(e);
      return null;
    }
  }
}