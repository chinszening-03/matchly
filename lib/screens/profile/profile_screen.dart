import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
      ),

      body: Center(
        child: ElevatedButton(
          onPressed: () {
            AuthService().logout();
          },
          child: const Text("Logout"),
        ),
      ),
    );
  }
}