import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import 'activitiy_details_screen.dart';

class ActivityHistoryScreen extends StatelessWidget {
  const ActivityHistoryScreen({super.key});

  // --- HELPER FUNCTIONS ---
  String formatDate(Timestamp? timestamp) {
    if (timestamp == null) return "";
    
    final date = timestamp.toDate();
    final now = DateTime.now();
    
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final targetDate = DateTime(date.year, date.month, date.day);
    
    String dayName;
    
    if (targetDate == today) {
      dayName = "Today";
    } else if (targetDate == tomorrow) {
      dayName = "Tomorrow";
    } else {
      List<String> days = [
        "Monday", "Tuesday", "Wednesday", "Thursday", 
        "Friday", "Saturday", "Sunday"
      ];
      dayName = days[date.weekday - 1];
    }

    return "$dayName, ${date.day}/${date.month}/${date.year}";
  }

  String formatTime(Timestamp? timestamp) {
    if (timestamp == null) return "";
    final date = timestamp.toDate();
    final hour = date.hour > 12 ? date.hour - 12 : date.hour == 0 ? 12 : date.hour;
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

  @override
  Widget build(BuildContext context) {
    final currentUserId = AuthService().getCurrentUser()?.uid;

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text("Past Activities", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("activities")
            .where("participants", arrayContains: currentUserId)
            .where("startTime", isLessThan: DateTime.now()) // 👈 PAST GAMES
            .orderBy("startTime", descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text("No past activities yet.", style: TextStyle(color: Colors.grey))
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var doc = snapshot.data!.docs[index];
              return activityCard(context, doc);
            },
          );
        },
      ),
    );
  }

  // --- EXACT SAME CARD UI FROM ACTIVITY LIST ---
  Widget activityCard(BuildContext context, QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    final sport = data["sport"] ?? "";
    final name = data["name"] ?? "Game";
    final location = data["location"] ?? "";
    final gameType = data["gameType"] ?? "";

    final max = data["maxPeople"] ?? 0;
    final price = data["price"] ?? 0;

    final start = data["startTime"] as Timestamp?;
    final end = data["endTime"] as Timestamp?;

    // --- AUTH & PARTICIPANT LOGIC ---
    final currentUserId = AuthService().getCurrentUser()?.uid;
    final createdBy = data["createdBy"] ?? "";
    final participants = List<String>.from(data["participants"] ?? []);
    
    final isCreator = currentUserId == createdBy;
    final reservedSpots = List<String>.from(data["reservedSpots"] ?? []);
    final totalJoined = participants.length + reservedSpots.length; 

    // Dynamically build the details string (Players + Type + Price)
    String detailsText = "$totalJoined/$max players • $gameType";
    if (price > 0) {
      detailsText += " • RM $price";
    }

    // --- AVATAR LOGIC SETUP ---
    int maxDisplay = 7; 
    
    int filledCircles = totalJoined > maxDisplay ? maxDisplay : totalJoined;
    int emptyCircles = max > maxDisplay ? maxDisplay - filledCircles : max - filledCircles;
    
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
      width: double.infinity, 
      margin: const EdgeInsets.only(bottom: 16), 
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
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
              color: const Color(0xFF0C3169).withValues(alpha: 0.1), 
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              sport.toUpperCase(),
              style: const TextStyle(
                color: Color(0xFF0C3169), 
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

              // 2. Generate Reserved Spots (Dark blue Avatars)
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
                    style: const TextStyle(fontSize: 12, color: Colors.black87, height: 1.2),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          /// 🔵 HISTORY BUTTON UI (Replaces the "Join" button)
          if (!isCreator)
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: null, // Disabled because it's in the past
                style: ElevatedButton.styleFrom(
                  disabledBackgroundColor: Colors.grey.shade200,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  "Game Finished",
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            
          if (isCreator)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  "You were the host",
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
        ],
      ),
    ));
  }
}