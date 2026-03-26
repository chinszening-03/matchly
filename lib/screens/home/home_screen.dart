import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:matchly/screens/activity/activity_list_screen.dart';
import '../../services/auth_service.dart';
import '../activity/choose_sports.dart';
import '../activity/activitiy_details_screen.dart'; 
import '../activity/activity_history_screen.dart';
import '../activity/location_search_screen.dart';
import '../club/my_club_screen.dart';

String formatDate(Timestamp? timestamp) {
  if (timestamp == null) return "";
  
  final date = timestamp.toDate();
  final now = DateTime.now();
  
  // Strip out the hours/minutes to accurately compare just the calendar days
  final today = DateTime(now.year, now.month, now.day);
  final tomorrow = today.add(const Duration(days: 1));
  final targetDate = DateTime(date.year, date.month, date.day);

  String dayName;
  
  if (targetDate == today) {
    dayName = "Today";
  } else if (targetDate == tomorrow) {
    dayName = "Tomorrow";
  } else {
    // If it's not today or tomorrow, get the full day name
    List<String> days = [
      "Monday", "Tuesday", "Wednesday", "Thursday", 
      "Friday", "Saturday", "Sunday"
    ];
    dayName = days[date.weekday - 1];
  }

  // Returns formats like: "Today, 19/3/2026" or "Monday, 23/3/2026"
  return "$dayName, ${date.day}/${date.month}/${date.year}";
}

String formatTime(Timestamp? timestamp) {
  if (timestamp == null) return "";

  final date = timestamp.toDate();
  final hour = date.hour > 12 ? date.hour - 12 : date.hour;
  final suffix = date.hour >= 12 ? "PM" : "AM";

  return "$hour:${date.minute.toString().padLeft(2, '0')} $suffix";
}

String formatDuration(Timestamp? start, Timestamp? end) {
  if (start == null || end == null) return "";
  
  final difference = end.toDate().difference(start.toDate());
  final hours = difference.inHours;
  final minutes = difference.inMinutes % 60;
  
  if (hours > 0 && minutes > 0) {
    return "${hours}h ${minutes}m";
  } else if (hours > 0) {
    return "$hours hr${hours > 1 ? 's' : ''}";
  } else {
    return "$minutes mins";
  }
}

class HomeScreen extends StatefulWidget {
  
  const HomeScreen({super.key});

  
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  String name = "";
  int joinedGamesCount = 0;
  String locationName = "Fetching location...";
  double radiusKm = 10.0;
  double? userLat;
  double? userLng;
  final Color primaryColor = const Color(0xFF0C3169);
  bool _showAllGames = false;

  final List<Map<String, String>> allSports = [
    {"name": "Badminton", "image": "assets/badminton.png"},
    {"name": "Pickleball", "image": "assets/pickleball.png"},
    {"name": "Basketball", "image": "assets/basketball.png"},
    {"name": "Tennis", "image": "assets/tennis.png"},
    {"name": "Pilates", "image": "assets/pilates.png"},
    {"name": "Paintball", "image": "assets/paintball.png"},
    {"name": "Golf", "image": "assets/golf.png"},
    {"name": "Hiking", "image": "assets/hiking.png"},
    {"name": "Football", "image": "assets/football.png"},
    {"name": "Futsal", "image": "assets/futsal.png"},
    {"name": "Bowling", "image": "assets/bowling.png"},
    {"name": "Bouldering", "image": "assets/bouldering.png"},
    {"name": "Dodgeball", "image": "assets/dodgeball.png"}, 
    {"name": "Running", "image": "assets/running.png"},
    {"name": "Squash", "image": "assets/squash.png"},
    {"name": "Table Tennis", "image": "assets/tabletennis.png"},
    {"name": "Frisbee", "image": "assets/frisbee.png"},
    {"name": "Volleyball", "image": "assets/volleyball.png"},
  ];

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  Future<void> loadUserData() async {
    final currentUserId = AuthService().getCurrentUser()?.uid;
    if (currentUserId == null) return;

    // Fetch the user's name
    final userDoc = await FirebaseFirestore.instance
        .collection("users")
        .doc(currentUserId)
        .get();

    // 👇 2. Fetch the COUNT of past joined games
    final countSnapshot = await FirebaseFirestore.instance
        .collection("activities")
        .where("participants", arrayContains: currentUserId)
        .where("startTime", isLessThan: DateTime.now()) 
        .count()
        .get();

    setState(() {
      name = userDoc.data()?["name"] ?? "Player";
      joinedGamesCount = countSnapshot.count ?? 0; // Update the count

      locationName = userDoc.data()?["location"] ?? "Set your location";
      radiusKm = (userDoc.data()?["radiusKm"] ?? 10.0).toDouble();
      userLat = userDoc.data()?["lat"];
      userLng = userDoc.data()?["lng"];
    });
  }

  void _showLocationBottomSheet(BuildContext context) {
    // Temporary variables to hold state while the bottom sheet is open
    String tempLocName = locationName;
    double tempRadius = radiusKm;
    double? tempLat = userLat;
    double? tempLng = userLng;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, 
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                top: 24, left: 20, right: 20
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Location & Radius", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  
                  // --- Location Picker Field ---
                  const Text("Area / City", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 8),
                  TextField(
                    readOnly: true, // Prevents typing, acts like a button
                    controller: TextEditingController(text: tempLocName),
                    onTap: () async {
                       // Open the Location Search Screen
                       final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => const LocationSearchScreen()));
                       
                       // If they picked a place, update the temporary variables
                       if (result != null && result is Map<String, dynamic>) {
                         setModalState(() {
                           tempLocName = result["name"] ?? "";
                           tempLat = result["lat"];
                           tempLng = result["lng"];
                         });
                       }
                    },
                    decoration: InputDecoration(
                      hintText: "Tap to search places",
                      prefixIcon: Icon(Icons.search, color: primaryColor),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),

                  const SizedBox(height: 30),
                  
                  // --- Radius Slider ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Distance Radius", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text("${tempRadius.toInt()} km", style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Slider(
                    value: tempRadius,
                    min: 1,
                    max: 50,
                    divisions: 49,
                    activeColor: primaryColor,
                    onChanged: (val) {
                      setModalState(() => tempRadius = val);
                    }
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("1 km", style: TextStyle(color: Colors.grey, fontSize: 12)),
                        Text("50 km", style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // --- Apply Button ---
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                      ),
                      onPressed: () async {
                        // 1. Save new location data to Firestore
                        final currentUserId = AuthService().getCurrentUser()?.uid;
                        if (currentUserId != null) {
                          await FirebaseFirestore.instance.collection("users").doc(currentUserId).update({
                            "location": tempLocName,
                            "radiusKm": tempRadius,
                            "lat": tempLat,
                            "lng": tempLng,
                          });
                        }
                        
                        // 2. Update the Home Screen State
                        setState(() {
                          locationName = tempLocName;
                          radiusKm = tempRadius;
                          userLat = tempLat;
                          userLng = tempLng;
                        });
                        
                        // 3. Close the bottom sheet
                        if (context.mounted) Navigator.pop(context);
                      },
                      child: const Text("Apply", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    )
                  )
                ]
              )
            );
          }
        );
      }
    );
  }
  @override
  Widget build(BuildContext context) {

    final currentUserId = AuthService().getCurrentUser()?.uid;

    return Scaffold(
      backgroundColor: Colors.grey[50],

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: GestureDetector(
          onTap: () => _showLocationBottomSheet(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.location_on, color: primaryColor, size: 20),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      locationName, 
                      style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(Icons.keyboard_arrow_down, color: Colors.black, size: 18),
                   
                ],
              ),
            ],
          ),
        ),
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

                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ActivityHistoryScreen()),
                      );
                    },
                    child: statBox(Icons.favorite_border, "Joined Game: $joinedGamesCount"),
                  ),
                  statBox(Icons.timelapse, "Points"),
                  GestureDetector(
                    onTap: () => {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const MyClubScreen()))
                    },
                    child: statBox(Icons.group, "My Club"),
                  )
                  

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
                      .where("participants", arrayContains: currentUserId)
                      .where("startTime", isGreaterThan: DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day))
                      .orderBy("startTime", descending: false)
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

              _buildExploreAllButton(context),

              const SizedBox(height: 15),

              Builder(
                builder: (context) {
                  List<Widget> gridItems = [];
                  
                  if (!_showAllGames) {
                    // Show first 7 games + View All Button
                    for (int i = 0; i < 7; i++) {
                      gridItems.add(gameItem(context, allSports[i]["image"]!, allSports[i]["name"]!));
                    }
                    gridItems.add(_buildToggleViewButton(isExpanded: false));
                  } else {
                    // Show all games + Show Less Button
                    for (int i = 0; i < allSports.length; i++) {
                      gridItems.add(gameItem(context, allSports[i]["image"]!, allSports[i]["name"]!));
                    }
                    gridItems.add(_buildToggleViewButton(isExpanded: true));
                  }

                  return GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 4,
                    crossAxisSpacing: 5,
                    mainAxisSpacing: 5,
                    childAspectRatio: 0.8,
                    children: gridItems,
                  );
                }
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
    final reservedSpots = List<String>.from(data["reservedSpots"] ?? []);
    final totalJoined = participants.length + reservedSpots.length; 
    
    // Dynamically build the details string (Players + Type + Price)
    String detailsText = "$totalJoined/$max players • $gameType";
    if (price > 0) {
      detailsText += " • RM $price";
    }

    // --- AVATAR LOGIC SETUP ---
    int maxDisplay = 6; // Maximum number of circles to draw before showing "+X"
    
    int filledCircles = totalJoined > maxDisplay ? maxDisplay : totalJoined;
    int emptyCircles = max > maxDisplay ? maxDisplay - filledCircles : max - filledCircles;
    
    // Prevent negative empty circles if data is ever weird
    if (emptyCircles < 0) emptyCircles = 0; 

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ActivityDetailsScreen(activityId: doc.id),
          ),
        );
      },
      child: Container(
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

          /// 👥 AVATARS ROW
          FutureBuilder<List<DocumentSnapshot>>(
            future: Future.wait(
              participants.take(maxDisplay).map(
                (uid) => FirebaseFirestore.instance.collection("users").doc(uid).get()
              )
            ),
            builder: (context, snapshot) {
              List<Widget> avatarWidgets = [];

              // 1. Generate Actual Users
              if (snapshot.connectionState == ConnectionState.waiting) {
                // Loading placeholders
                for (int i = 0; i < (participants.length > maxDisplay ? maxDisplay : participants.length); i++) {
                  avatarWidgets.add(
                    Container(
                      width: 40, height: 40, margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.grey.shade200, border: Border.all(color: Colors.white, width: 2)),
                    )
                  );
                }
              } else if (snapshot.hasData) {
                for (int i = 0; i < snapshot.data!.length; i++) {
                  var userDoc = snapshot.data![i].data() as Map<String, dynamic>?;
                  String profilePicUrl = userDoc?["profilePicUrl"] ?? "";

                  avatarWidgets.add(
                    Container(
                      margin: const EdgeInsets.only(right: 6), 
                      decoration: BoxDecoration(
                        shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                      ),
                      child: CircleAvatar(
                        radius: 18, 
                        backgroundColor: const Color(0xFF0C3169).withOpacity(0.1),
                        backgroundImage: profilePicUrl.isNotEmpty ? NetworkImage(profilePicUrl) : null,
                        child: profilePicUrl.isEmpty ? const Icon(Icons.person, size: 20, color: Color(0xFF0C3169)) : null, 
                      ),
                    ),
                  );
                }
              }

              // 2. Generate Reserved Spots (Orange Avatars)
              int spotsLeftToDisplay = maxDisplay - avatarWidgets.length;
              for (int i = 0; i < reservedSpots.length && i < spotsLeftToDisplay; i++) {
                avatarWidgets.add(
                  Container(
                    margin: const EdgeInsets.only(right: 6), 
                    decoration: BoxDecoration(
                      shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                    ),
                    child: CircleAvatar(
                      radius: 18, 
                      backgroundColor:  Color(0xFF0C3169).withOpacity(0.1),
                      child: const Icon(Icons.person, size: 20, color: Color(0xFF0C3169)), 
                    ),
                  ),
                );
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

          /// ⏰ TIME & DURATION
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
                "${formatTime(start)} - ${formatTime(end)}  •  ${formatDuration(start, end)}", 
                style: const TextStyle(fontSize: 12, color: Colors.black87),
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
    ));
  }
  /// Stats Box
  Widget statBox(IconData icon, String text) {
    return Container(
      width: 112, 
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
            textAlign: TextAlign.center,
            maxLines: 2,
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

  Widget _buildExploreAllButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Navigate to the list screen, passing "All" so it doesn't filter by sport
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ActivityListScreen(sport: "All"), 
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        decoration: BoxDecoration(
          color: primaryColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Explore All Games", 
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)
                ),
                const SizedBox(height: 4),
                Text(
                  "Find matches happening around you", 
                  style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildToggleViewButton({required bool isExpanded}) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _showAllGames = !isExpanded;
        });
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
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
              backgroundColor: Colors.grey.shade100,
              child: Icon(
                isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, 
                color: primaryColor, 
                size: 28
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isExpanded ? "SHOW LESS" : "VIEW ALL",
            style: TextStyle(
              fontSize: 10, 
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
              color: primaryColor,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
          ),
        ],
      ),
    );
  }
}

/// 👇 NEW: Toggle Button for View All / Show Less
  