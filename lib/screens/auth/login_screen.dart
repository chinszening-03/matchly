import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'signup_screen.dart';
import '../home/home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool loading = false;

  Future<void> login() async {

  setState(() => loading = true);

  final user = await AuthService().signInWithEmail(
    emailController.text.trim(),
    passwordController.text.trim(),
  );

  setState(() => loading = false);

  if (user != null) {

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const HomeScreen(),
      ),
    );

  } else {

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Login failed. Please check your email and password."),
      ),
    );

  }
}

  Future<void> googleLogin() async {

  final user = await AuthService().signInWithGoogle();

  if (user != null) {

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const HomeScreen(),
      ),
    );

  } else {

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Google login failed"),
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
                height: 120,
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

              /// Login Button
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

                  onPressed: loading ? null : login,

                  child: loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Login",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 20),

              const Text("OR"),

              const SizedBox(height: 20),

              /// Google Login
              SizedBox(
                width: double.infinity,
                height: 50,

                child: OutlinedButton.icon(

                  onPressed: googleLogin,

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

              const SizedBox(height: 25),

              /// Navigate to Sign Up
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [

                  const Text("Don't have an account?"),

                  TextButton(

                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SignUpScreen(),
                        ),
                      );
                    },

                    child: const Text(
                      "Sign Up",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  )
                ],
              ),

            ],
          ),
        ),
      ),
    );
  }
}