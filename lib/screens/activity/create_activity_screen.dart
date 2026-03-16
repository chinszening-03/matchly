import 'package:flutter/material.dart';

class CreateActivityScreen extends StatefulWidget {
  const CreateActivityScreen({super.key});

  @override
  State<CreateActivityScreen> createState() => _CreateActivityScreenState();
}

class _CreateActivityScreenState extends State<CreateActivityScreen> {

  String selectedSport = "";
  String searchQuery = "";

  final List<Map<String, String>> sports = [

    {"name": "Badminton", "icon": "assets/badminton.png"},
    {"name": "Pickleball", "icon": "assets/pickleball.png"},
    {"name": "Basketball", "icon": "assets/basketball.png"},
    {"name": "Tennis", "icon": "assets/tennis.png"},
    {"name": "Pilates", "icon": "assets/pilates.png"},
    {"name": "Paintball", "icon": "assets/paintball.png"},
    {"name": "Golf", "icon": "assets/golf.png"},
    {"name": "Hiking", "icon": "assets/hiking.png"},
    {"name": "Football", "icon": "assets/football.png"},
    {"name": "Futsal", "icon": "assets/futsal.png"},
    {"name": "Bowling", "icon": "assets/bowling.png"},
    {"name": "Bouldering", "icon": "assets/bouldering.png"},
    {"name": "Dodgeball", "icon": "assets/dodgeball.png"},
    {"name": "Running", "icon": "assets/running.png"},
    {"name": "Squash", "icon": "assets/squash.png"},
    {"name": "Table Tennis", "icon": "assets/table_tennis.png"},
    {"name": "Frisbee", "icon": "assets/frisbee.png"},
    {"name": "Volleyball", "icon": "assets/volleyball.png"},
  ];

  @override
  Widget build(BuildContext context) {

    final filteredSports = sports.where((sport) {

      final name = sport["name"]!.toLowerCase();
      final query = searchQuery.toLowerCase();

      return name.contains(query);

    }).toList();

    return Scaffold(

      appBar: AppBar(
        title: const Text("Create Activity"),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const Text(
              "SPORT",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            /// Search Bar
            TextField(

              decoration: InputDecoration(

                hintText: "Search sport",

                prefixIcon: const Icon(Icons.search),

                filled: true,
                fillColor: Colors.white,

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),

              ),

              onChanged: (value) {

                setState(() {
                  searchQuery = value;
                });

              },
            ),

            const SizedBox(height: 16),

            /// Sports Grid
            Expanded(
              child: GridView.builder(

                itemCount: filteredSports.length,

                gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 1,
                ),

                itemBuilder: (context, index) {

                  final sport = filteredSports[index];

                  return sportCard(
                    sport["name"]!,
                    sport["icon"]!,
                  );
                },
              ),
            ),

            const SizedBox(height: 10),

            /// Next Button
            SizedBox(
              width: double.infinity,
              height: 50,

              child: ElevatedButton(

                onPressed: selectedSport.isEmpty
                    ? null
                    : () {

                  Navigator.pop(context, selectedSport);

                },

                style: ButtonStyle(

                backgroundColor: MaterialStateProperty.resolveWith((states) {

                  if (states.contains(MaterialState.disabled)) {
                    return Colors.grey.shade400;
                  }

                  if (states.contains(MaterialState.hovered)) {
                    return const Color(0xFF1565C0); // darker blue on hover
                  }

                  return const Color(0xFF0D47A1); // normal blue
                }),

                shape: MaterialStateProperty.all(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),


                child: const Text("Next", style:TextStyle(color: Colors.white,)) 
              
      
              ),
            ),

          ],
        ),
      ),
    );
  }

  Widget sportCard(String sport, String icon) {

    final selected = sport == selectedSport;

    return GestureDetector(

      onTap: () {

        setState(() {
          selectedSport = sport;
        });

      },

      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),

        decoration: BoxDecoration(

          color: selected
              ? const Color(0xFF34C759)
              : Colors.white,

          borderRadius: BorderRadius.circular(20),

          border: Border.all(
            color: selected
                ? const Color(0xFF34C759)
                : Colors.grey.shade300,
            width: 2,
          ),

          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
            )
          ],
        ),

        padding: const EdgeInsets.all(20),

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            Image.asset(
              icon,
              height: 40,
            ),

            const SizedBox(height: 12),

            Text(
              sport,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: selected
                    ? Colors.white
                    : Colors.black,
              ),
            ),

          ],
        ),
      ),
    );
  }
}