import 'package:flutter/material.dart';
import 'package:matchly/screens/auth/login_screen.dart';
import '../../services/auth_service.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool loading = false;

  Future<void> signUp() async {
    setState(() => loading = true);

    await AuthService().signUpWithEmail(
      emailController.text.trim(),
      passwordController.text.trim(),
    );

    setState(() => loading = false);
  }

  Future<void> googleSignIn() async {
    await AuthService().signInWithGoogle();
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
                height: 200,
              ),

              const SizedBox(height: 40),

              /// Email
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: "Email",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              /// Password
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: "Password",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              /// Sign Up Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: darkBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: loading ? null : signUp,
                  child: loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Sign Up",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Already have an account?"),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                    ); // go back to login screen
                    },
                    child: const Text("Login"),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              const Text("OR"),

              const SizedBox(height: 20),

              /// Google Sign In
              SizedBox(
                width: double.infinity,
                height: 50,

                child: OutlinedButton.icon(

                  onPressed: googleSignIn,

                  icon: Image.network(
                    "https://developers.google.com/identity/images/g-logo.png",
                    height: 24,
                  ),

                  label: const Text(
                    "Continue with Google",
                    style: TextStyle(fontSize: 16),
                  ),

                  style: OutlinedButton.styleFrom(
                    foregroundColor: darkBlue,
                    side: const BorderSide(color: darkBlue),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }
}