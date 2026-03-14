import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () {
                AuthService().logout();
              },
            ),

              const SizedBox(height: 10),

              /// Welcome
              const Center(
                child: Column(
                  children: [
                    Text(
                      "Welcome Back,",
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      "Paul Paolo",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  ],
                ),
              ),

              

              const SizedBox(height: 20),

              /// Stats Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [

                  statBox(Icons.favorite_border, "Joined Game"),
                  statBox(Icons.timelapse, "Points"),
                  statBox(Icons.timelapse, "My Club"),

                ],
              ),

              const SizedBox(height: 20),

              /// Top News/Event
              const Text(
                "TOP NEWS/EVENT",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 10),

              Container(
                height: 90,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    "assets/badminton.jpeg",
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              /// Games
              const Text(
                "GAMES",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 10),

              Stack(
                children: [

                  Container(
                    height: 100,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        "assets/badminton.jpeg",
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),

                  const Positioned(
                    left: 16,
                    top: 35,
                    child: Text(
                      "BADMINTON",
                      style: TextStyle(
                        color: Colors.cyanAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),

                  const Positioned(
                    right: 12,
                    bottom: 10,
                    child: Text(
                      "Most Player",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              /// Game Grid
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

              const SizedBox(height: 20),

              /// Highlight
              const Text(
                "HIGHLIGHT",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 10),

              SizedBox(
                height: 90,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [

                    highlightItem("assets/badminton.jpeg"),
                    highlightItem("assets/badminton.jpeg"),
                    highlightItem("assets/badminton.jpeg"),
                    highlightItem("assets/badminton.jpeg"),

                  ],
                ),
              ),

              const SizedBox(height: 20),

            ],
          ),
        ),
      ),
    );
  }

  /// Stat Box
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
          Text(
            text,
            style: const TextStyle(fontSize: 12),
          )
        ],
      ),
    );
  }

  /// Game Icon
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

  /// Highlight Card
  Widget highlightItem(String image) {
    return Container(
      width: 80,
      margin: const EdgeInsets.only(right: 10),

      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
      ),

      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.asset(
          image,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}