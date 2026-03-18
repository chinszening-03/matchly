import 'package:flutter/material.dart';
import 'package:matchly/screens/home/home_screen.dart';
import '../../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {

  bool loading = false;

  Future<void> googleLogin() async {
    setState(() {
      loading = true;
    });

    final user = await AuthService().signInWithGoogle();

    // 🛑 Add this check before calling setState after an 'await'
    if (!mounted) return;

    setState(() {
      loading = false;
    });

    if (user != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const HomeScreen(),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Google sign-in failed"),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {

    const darkBlue = Color(0xFF0D47A1);

    return Scaffold(
      backgroundColor: Colors.white,

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),

          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              /// Logo
              Image.asset(
                "assets/logo.png",
                height: 160,
              ),

              const SizedBox(height: 30),

              /// Title
              const Text(
                "Welcome to Matchly",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              /// Subtitle
              const Text(
                "Find teammates, host games, and play together.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),

              const SizedBox(height: 40),

              /// Google Button
              SizedBox(
                width: double.infinity,
                height: 55,

                child: ElevatedButton.icon(

                  onPressed: loading ? null : googleLogin,

                  icon: Image.network(
                    "https://developers.google.com/identity/images/g-logo.png",
                    height: 24,
                  ),

                  label: loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Continue with Google",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),

                  style: ElevatedButton.styleFrom(
                    backgroundColor: darkBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                "By continuing you agree to our Terms of Service",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }
}