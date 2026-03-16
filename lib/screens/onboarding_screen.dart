import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home/home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {

  int step = 0;

  final TextEditingController nameController = TextEditingController();

  List<String> selectedSports = [];

  String skillLevel = "";
  String playTime = "";

  final List<String> sports = [
    "Badminton",
    "Football",
    "Basketball",
    "Tennis",
    "Futsal",
    "Golf",
    "Pickleball",
    "Pilates"
  ];

  final List<String> skillLevels = [
    "Beginner",
    "Intermediate",
    "Advanced"
  ];

  final List<String> playTimes = [
    "Weekdays",
    "Weekends",
    "Both"
  ];

  Future<void> saveProfile() async {

    final uid = FirebaseAuth.instance.currentUser!.uid;

    await FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .set({

      "name": nameController.text.isEmpty
          ? FirebaseAuth.instance.currentUser!.displayName ?? "Player"
          : nameController.text,

      "sports": selectedSports,
      "skillLevel": skillLevel,
      "playTime": playTime,
      "profileCompleted": true,
      "createdAt": Timestamp.now(),

    }, SetOptions(merge: true));

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const HomeScreen(),
      ),
    );
  }

  void toggleSport(String sport) {

    setState(() {

      if (selectedSports.contains(sport)) {
        selectedSports.remove(sport);
      } else {
        selectedSports.add(sport);
      }

    });
  }

  Widget buildStep() {

    const darkBlue = Color(0xFF0D47A1);

    /// STEP 1 NAME
    if (step == 0) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          const Text(
            "What should we call you?",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 10),

          const Text(
            "Your teammates will see this name.",
            style: TextStyle(color: Colors.grey),
          ),

          const SizedBox(height: 30),

          TextField(
            controller: nameController,
            decoration: InputDecoration(
              hintText: "Display Name",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

        ],
      );
    }

    /// STEP 2 SPORTS
    if (step == 1) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          const Text(
            "What sports do you play?",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 10),

          const Text(
            "Choose the sports you are interested in.",
            style: TextStyle(color: Colors.grey),
          ),

          const SizedBox(height: 30),

          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: sports.map((sport) {

              final selected = selectedSports.contains(sport);

              return GestureDetector(
                onTap: () => toggleSport(sport),

                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),

                  decoration: BoxDecoration(
                    color: selected ? darkBlue : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(25),
                  ),

                  child: Text(
                    sport,
                    style: TextStyle(
                      color: selected ? Colors.white : Colors.black,
                    ),
                  ),
                ),
              );

            }).toList(),
          ),
        ],
      );
    }

    /// STEP 3 SKILL LEVEL
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        const Text(
          "Tell us about your play style",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 20),

        const Text("Skill Level"),

        const SizedBox(height: 10),

        Wrap(
          spacing: 10,
          children: skillLevels.map((level) {

            final selected = skillLevel == level;

            return ChoiceChip(
              label: Text(level),
              selected: selected,
              onSelected: (_) {
                setState(() {
                  skillLevel = level;
                });
              },
            );

          }).toList(),
        ),

        const SizedBox(height: 30),

        const Text("Preferred Play Time"),

        const SizedBox(height: 10),

        Wrap(
          spacing: 10,
          children: playTimes.map((time) {

            final selected = playTime == time;

            return ChoiceChip(
              label: Text(time),
              selected: selected,
              onSelected: (_) {
                setState(() {
                  playTime = time;
                });
              },
            );

          }).toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {

    const darkBlue = Color(0xFF0D47A1);

    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [

          TextButton(
            onPressed: saveProfile,
            child: const Text("Skip"),
          )

        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// Progress indicator
            LinearProgressIndicator(
              value: (step + 1) / 3,
              color: darkBlue,
            ),

            const SizedBox(height: 30),

            Expanded(child: buildStep()),

            const SizedBox(height: 20),

            Row(
              children: [

                if (step > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          step--;
                        });
                      },
                      child: const Text("Back"),
                    ),
                  ),

                if (step > 0) const SizedBox(width: 10),

                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: darkBlue,
                    ),
                    onPressed: () {

                      if (step < 2) {
                        setState(() {
                          step++;
                        });
                      } else {
                        saveProfile();
                      }

                    },
                    child: Text(step == 2 ? "Finish" : "Next"),
                  ),
                ),

              ],
            )

          ],
        ),
      ),
    );
  }
}