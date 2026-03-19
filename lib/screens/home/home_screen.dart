import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:matchly/screens/activity/activity_list_screen.dart';
import '../../services/auth_service.dart';
import '../activity/choose_sports.dart';

String formatDate(Timestamp? timestamp) {
  if (timestamp == null) return "";

  final date = timestamp.toDate();
  return "${date.day}/${date.month}/${date.year}";
}

String formatTime(Timestamp? timestamp) {
  if (timestamp == null) return "";

  final date = timestamp.toDate();
  final hour = date.hour > 12 ? date.hour - 12 : date.hour;
  final suffix = date.hour >= 12 ? "PM" : "AM";

  return "$hour:${date.minute.toString().padLeft(2, '0')} $suffix";
}

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

    final currentUserId = AuthService().getCurrentUser()?.uid;

    if (currentUserId == null) return;

    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(currentUserId)
        .get();

    setState(() {
      name = doc.data()?["name"] ?? "Player";
    });
  }

  @override
  Widget build(BuildContext context) {

    final currentUserId = AuthService().getCurrentUser()?.uid;

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
                "YOUR UPCOMING ACTIVITIES",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 10),

              SizedBox(
                height: 310,
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection("activities")
                      // Simply check if the user is in the participants array!
                      // This handles both games they created AND games they joined.
                      .where("participants", arrayContains: currentUserId)
                      .orderBy("createdAt", descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    
                    // Add a loading indicator so you know it's working
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    List<Widget> cards = [];

                    /// Create activity card (always first)
                    cards.add(createActivityCard());

                    if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                      for (var doc in snapshot.data!.docs) {
                        cards.add(activityCard(doc));
                      }
                    } else if (snapshot.hasData && snapshot.data!.docs.isEmpty) {
                       // Optional: Add a message if they have no upcoming games
                       cards.add(
                         const Center(
                           child: Padding(
                             padding: EdgeInsets.only(left: 20),
                             child: Text("No upcoming games yet!"),
                           ),
                         )
                       );
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

                  gameItem(context,"assets/badminton.png", "Badminton"),
                  gameItem(context,"assets/pickleball.png", "Pickleball"),
                  gameItem(context,"assets/tennis.png", "Tennis"),
                  gameItem(context,"assets/paintball.png", "Paintball"),

                  gameItem(context,"assets/basketball.png", "Basketball"),
                  gameItem(context,"assets/football.png", "Football"),
                  gameItem(context,"assets/futsal.png", "Futsal"),
                  gameItem(context,"assets/golf.png", "Golf"),
                  gameItem(context,"assets/pilates.png", "Pilates"),
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
        margin: const EdgeInsets.only(right: 12, top: 4, bottom: 4), // Added margin for shadow
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0C3169), Color(0xFF134A9E)], // Subtle premium gradient
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0C3169).withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_circle_outline, color: Colors.white, size: 36),
              SizedBox(height: 10),
              Text(
                "Create\nActivity",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white, 
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  letterSpacing: 0.5,
                ),
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

    final sport = data["sport"] ?? "";
    final name = data["name"] ?? "Game";
    final location = data["location"] ?? "";
    final gameType = data["gameType"] ?? "";

    final max = data["maxPeople"] ?? 0;
    final price = data["price"] ?? 0;

    final start = data["startTime"] as Timestamp?;
    final end = data["endTime"] as Timestamp?;

    // Grab participants to show accurate player count like the list screen
    final participants = List<String>.from(data["participants"] ?? []);

    // Dynamically build the details string (Players + Type + Price)
    String detailsText = "${participants.length}/$max players • $gameType";
    if (price > 0) {
      detailsText += " • RM $price";
    }

    // --- AVATAR LOGIC SETUP ---
    int maxDisplay = 6; // Maximum number of circles to draw before showing "+X"
    int currentCount = participants.length;
    
    int filledCircles = currentCount > maxDisplay ? maxDisplay : currentCount;
    int emptyCircles = max > maxDisplay ? maxDisplay - filledCircles : max - filledCircles;
    
    // Prevent negative empty circles if data is ever weird
    if (emptyCircles < 0) emptyCircles = 0; 

    return Container(
      width: 310,
      margin: const EdgeInsets.only(right: 14, top: 4, bottom: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// 🔵 SPORT TAG
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF0C3169).withOpacity(0.1), // Soft background
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              sport.toUpperCase(),
              style: const TextStyle(
                color: Color(0xFF0C3169), // Primary colored text
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 12),

          /// 🏸 GAME NAME
          Text(
            name,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),

          /// 👥 AVATARS ROW (NOW FETCHES FROM FIRESTORE)
          FutureBuilder<List<DocumentSnapshot>>(
            // Fetch the user documents for the participants (up to the maxDisplay limit)
            future: Future.wait(
              participants.take(maxDisplay).map(
                (uid) => FirebaseFirestore.instance.collection("users").doc(uid).get()
              )
            ),
            builder: (context, snapshot) {
              List<Widget> avatarWidgets = [];

              // 1. Generate Filled Avatars (Loading State)
              if (snapshot.connectionState == ConnectionState.waiting) {
                for (int i = 0; i < filledCircles; i++) {
                  avatarWidgets.add(
                    Align(
                      widthFactor: 0.75,
                      child: Container(
                        width: 40, height: 40,
                        margin: const EdgeInsets.only(right: 6),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle, 
                          color: Colors.grey.shade200,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      )
                    )
                  );
                }
              } 
              // 1. Generate Filled Avatars (Loaded State)
              else if (snapshot.hasData) {
                for (int i = 0; i < filledCircles; i++) {
                  var userDoc = snapshot.data![i].data() as Map<String, dynamic>?;
                  String profilePicUrl = userDoc?["profilePicUrl"] ?? "";

                  avatarWidgets.add(
                    Container(
                      margin: const EdgeInsets.only(right: 6), // Creates the gap
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                      ),
                      child: CircleAvatar(
                        radius: 18, // INCREASED RADIUS
                        backgroundColor: const Color(0xFF0C3169).withOpacity(0.1),
                        backgroundImage: profilePicUrl.isNotEmpty ? NetworkImage(profilePicUrl) : null,
                        child: profilePicUrl.isEmpty 
                            ? const Icon(Icons.person, size: 20, color: Color(0xFF0C3169))
                            : null, 
                      ),
                    ),
                  );
                }
              }

              // 2. Generate Empty Avatars
              for (int i = 0; i < emptyCircles; i++) {
                avatarWidgets.add(
                  Container(
                    width: 40, // Increased to match new radius size
                    height: 40,
                    margin: const EdgeInsets.only(right: 6), // Creates the gap
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey.shade50,
                      border: Border.all(color: Colors.grey.shade300, width: 1.5, strokeAlign: BorderSide.strokeAlignInside),
                    ),
                  ),
                );
              }
              return Row(children: avatarWidgets);
            },
          ),
          
          const SizedBox(height: 20),

          /// 📌 TYPE + PRICE
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(Icons.people_outline, size: 16, color: Color(0xFF0C3169)),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  detailsText,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis, 
                ),
              ),
            ],
          ),
            
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F0)),
          ),

          /// 📅 DATE
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8)
                ),
                child: const Icon(Icons.calendar_today, size: 14, color: Color(0xFF0C3169)),
              ),
              const SizedBox(width: 8),
              Text(
                formatDate(start),
                style: const TextStyle(fontSize: 12,  color: Colors.black87),
              ),
            ],
          ),
          const SizedBox(height: 5),

          /// ⏰ TIME
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8)
                ),
                child: const Icon(Icons.access_time, size: 14, color: Color(0xFF0C3169)),
              ),
              const SizedBox(width: 8),
              Text(
                "${formatTime(start)} - ${formatTime(end)}", // Start to End time
                style: const TextStyle(fontSize: 12,  color: Colors.black87),
              ),
            ],
          ),
          const SizedBox(height: 5),

          /// 📍 LOCATION
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8)
                ),
                child: const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF0C3169)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    location,
                    style: TextStyle(fontSize: 12, color: Colors.black87, height: 1.2),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  /// Stats Box
  Widget statBox(IconData icon, String text) {
    return Container(
      width: 105, // Slightly adjusted width to fit perfectly on standard screens
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF0C3169).withOpacity(0.08), // Primary color tint
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 22, color: const Color(0xFF0C3169)), // Primary color icon
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12, 
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          )
        ],
      ),
    );
  }

  /// Game Category Item
  Widget gameItem(BuildContext context, String image, String name) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ActivityListScreen(sport: name), 
          ),
        );
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(3), // Creates a thin border effect
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 32,
              backgroundColor: Colors.grey.shade100, // Light background for transparent PNGs
              backgroundImage: AssetImage(image),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            name.toUpperCase(),
            style: const TextStyle(
              fontSize: 10, 
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}