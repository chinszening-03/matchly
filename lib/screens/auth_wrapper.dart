import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:matchly/screens/main/main_screen.dart';
import 'package:matchly/screens/onboarding_screen.dart';
import 'auth/login_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),

      builder: (context, snapshot) {

        /// Loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        /// Not logged in
        if (!snapshot.hasData) {
          return const LoginScreen();
        }

        final user = snapshot.data!;

        /// Check Firestore user document
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection("users")
              .doc(user.uid)
              .get(),

          builder: (context, docSnapshot) {

            if (docSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final data = docSnapshot.data?.data() as Map<String, dynamic>?;

            /// First time login → onboarding
            if (data == null || data["profileCompleted"] != true) {
              return const OnboardingScreen();
            }

            /// Profile completed → main
            return const MainScreen();
          },
        );
      },
    );
  }
}