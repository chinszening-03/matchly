import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import 'create_club_screen.dart';
import 'club_details_screen.dart';

class MyClubScreen extends StatelessWidget {
  const MyClubScreen({super.key});

  final Color primaryColor = const Color(0xFF0C3169);

  @override
  Widget build(BuildContext context) {
    final currentUserId = AuthService().getCurrentUser()?.uid;

    if (currentUserId == null) {
      return const Scaffold(body: Center(child: Text("Please log in.")));
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text("My Clubs", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Query: Find clubs where this user is in the 'members' array
        stream: FirebaseFirestore.instance
            .collection("clubs")
            .where("members", arrayContains: currentUserId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: primaryColor));
          }

          // --- EMPTY STATE: User has no clubs ---
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(color: primaryColor.withOpacity(0.1), shape: BoxShape.circle),
                      child: Icon(Icons.groups_outlined, size: 80, color: primaryColor),
                    ),
                    const SizedBox(height: 24),
                    const Text("You haven't joined any clubs yet.", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Text(
                      "Create your own club to organize games, invite friends, and build your community.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600, height: 1.5),
                    ),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.add, color: Colors.white),
                        label: const Text("Create a Club", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const CreateClubScreen()));
                        },
                      ),
                    )
                  ],
                ),
              ),
            );
          }

          // --- FILLED STATE: List their clubs ---
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var clubData = snapshot.data!.docs[index].data() as Map<String, dynamic>;
              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: CircleAvatar(
                    radius: 28,
                    backgroundColor: primaryColor.withOpacity(0.1),
                    backgroundImage: clubData["profilePicUrl"] != null && clubData["profilePicUrl"].toString().isNotEmpty 
                        ? NetworkImage(clubData["profilePicUrl"]) 
                        : null,
                    child: clubData["profilePicUrl"] == null || clubData["profilePicUrl"].toString().isEmpty 
                        ? Icon(Icons.shield, color: primaryColor) 
                        : null,
                  ),
                  title: Text(clubData["name"] ?? "Club", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  subtitle: Text("${clubData["members"]?.length ?? 1} members • ${clubData["sport"]}", style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                      final String clickedClubId = snapshot.data!.docs[index].id;
                      
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ClubDetailsScreen(clubId: clickedClubId),
                        ),
                      );
                    },
                ),
              );
            },
          );
        },
      ),
    );
  }
}