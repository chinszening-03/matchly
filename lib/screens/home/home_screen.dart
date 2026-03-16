import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../activity/create_activity_screen.dart';

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

    if (uid == null) return;

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

              /// Welcome
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

              /// Stats
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [

                  statBox(Icons.favorite_border, "Joined Game"),
                  statBox(Icons.timelapse, "Points"),
                  statBox(Icons.group, "My Club"),

                ],
              ),

              const SizedBox(height: 20),

              /// Upcoming Activities
              const Text(
                "UPCOMING ACTIVITIES",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 10),

              SizedBox(
                height: 170,
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection("activities")
                      .orderBy("createdAt", descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {

                    List<Widget> cards = [];

                    /// Create activity card
                    cards.add(createActivityCard());

                    if (snapshot.hasData) {

                      for (var doc in snapshot.data!.docs) {
                        cards.add(activityCard(doc));
                      }

                    }

                    return ListView(
                      scrollDirection: Axis.horizontal,
                      children: cards,
                    );
                  },
                ),
              ),

              const SizedBox(height: 20),

              /// Games Section
              const Text(
                "GAMES",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 10),

              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 4,
                crossAxisSpacing: 5,
                mainAxisSpacing: 5,
                childAspectRatio: 0.8,
                children: [

                  gameItem("assets/badminton.png", "Badminton"),
                  gameItem("assets/pickleball.png", "Pickleball"),
                  gameItem("assets/tennis.png", "Tennis"),
                  gameItem("assets/paintball.png", "Paintball"),

                  gameItem("assets/basketball.png", "Basketball"),
                  gameItem("assets/football.png", "Football"),
                  gameItem("assets/futsal.png", "Futsal"),
                  gameItem("assets/golf.png", "Golf"),

                  gameItem("assets/pilates.png", "Pilates"),
                ],
              ),

              const SizedBox(height: 20),

            ],
          ),
        ),
      ),
    );
  }

  /// Create Activity Card
  Widget createActivityCard() {

    return GestureDetector(
      onTap: () {

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const CreateActivityScreen(),
          ),
        );

      },

      child: Container(
        width: 150,
        margin: const EdgeInsets.only(right: 10),

        decoration: BoxDecoration(
          color: const Color(0xFF0D47A1),
          borderRadius: BorderRadius.circular(12),
        ),

        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              Icon(Icons.add, color: Colors.white, size: 30),

              SizedBox(height: 8),

              Text(
                "Create\nActivity",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white),
              )

            ],
          ),
        ),
      ),
    );
  }

  /// Activity Card
  Widget activityCard(QueryDocumentSnapshot doc) {

    final data = doc.data() as Map<String, dynamic>;

    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 10),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),

      padding: const EdgeInsets.all(10),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Text(
            data["sport"] ?? "",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          Text("📅 ${data["date"] ?? ""}"),
          Text("⏰ ${data["startTime"] ?? ""} - ${data["endTime"] ?? ""}"),
          Text("📍 ${data["location"] ?? ""}"),

        ],
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

          Text(
            text,
            style: const TextStyle(fontSize: 12),
          )

        ],
      ),
    );
  }

  Widget gameItem(String image, String name) {

    return Column(
      children: [

        CircleAvatar(
          radius: 36,
          backgroundImage: AssetImage(image),
        ),

        const SizedBox(height: 6),

        Text(
          name.toUpperCase(),
          style: const TextStyle(fontSize: 10),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),

      ],
    );
  }
}