import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  String name = "";

  @override
  void initState() {
    super.initState();
    loadUserName();
  }

  Future<void> loadUserName() async {

    final uid = AuthService().getCurrentUser()?.uid;

    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .get();

    setState(() {
      name = doc.data()?["name"] ?? "Player";
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.grey[200],

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [

          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black),
            onPressed: () {
              AuthService().logout();
            },
          )

        ],
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              const SizedBox(height: 10),

              Center(
                child: Column(
                  children: [
                    const Text(
                      "Welcome Back,",
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),

                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [

                  statBox(Icons.favorite_border, "Joined Game"),
                  statBox(Icons.timelapse, "Points"),
                  statBox(Icons.group, "My Club"),

                ],
              ),

              const SizedBox(height: 20),

              const Text(
                "TOP NEWS/EVENT",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 10),

              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  "assets/badminton.jpeg",
                  height: 90,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                "GAMES",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 10),

              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 4,
                crossAxisSpacing: 10,
                mainAxisSpacing: 12,
                children: [

                  gameItem("assets/badminton.jpeg", "PICKLEBALL"),
                  gameItem("assets/badminton.jpeg", "TENNIS"),
                  gameItem("assets/badminton.jpeg", "PAINTBALL"),
                  gameItem("assets/badminton.jpeg", "BASKETBALL"),

                  gameItem("assets/badminton.jpeg", "FOOTBALL"),
                  gameItem("assets/badminton.jpeg", "FUTSAL"),
                  gameItem("assets/badminton.jpeg", "GOLF"),
                  gameItem("assets/badminton.jpeg", "PILATES"),
                ],
              ),

            ],
          ),
        ),
      ),
    );
  }

  Widget statBox(IconData icon, String text) {
    return Container(
      width: 110,
      padding: const EdgeInsets.symmetric(vertical: 10),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),

      child: Column(
        children: [
          Icon(icon, size: 18),
          const SizedBox(height: 4),
          Text(text, style: const TextStyle(fontSize: 12))
        ],
      ),
    );
  }

  Widget gameItem(String image, String name) {
    return Column(
      children: [

        CircleAvatar(
          radius: 28,
          backgroundImage: AssetImage(image),
        ),

        const SizedBox(height: 6),

        Text(
          name,
          style: const TextStyle(fontSize: 10),
          textAlign: TextAlign.center,
        )
      ],
    );
  }
}