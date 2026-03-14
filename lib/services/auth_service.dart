import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  User? getCurrentUser() {
    return _auth.currentUser;
  }

  /// GOOGLE SIGN IN
  Future<User?> signInWithGoogle() async {
    try {

      final GoogleSignInAccount? googleUser =
          await _googleSignIn.signIn();

      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      final user = userCredential.user;

      if (user != null) {
        await _createUserIfNotExists(user);
      }

      return user;

    } catch (e) {
      print("Google Sign-In Error: $e");
      return null;
    }
  }

  /// AUTO CREATE USER PROFILE
  Future<void> _createUserIfNotExists(User user) async {

    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .get();

    if (!doc.exists) {

      await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .set({

        "name": user.displayName ?? "Player",
        "email": user.email ?? "",
        "points": 0,
        "club": "",
        "createdAt": Timestamp.now(),

      });
    }
  }

  /// LOGOUT
  Future<void> logout() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}