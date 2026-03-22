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

    // Using DefaultTabController to manage the two tabs
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        
        // --- FLOATING ACTION BUTTON ---
        // Always visible so users can easily create a club from either tab
        floatingActionButton: FloatingActionButton(
          backgroundColor: primaryColor,
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const CreateClubScreen()));
          },
          child: const Icon(Icons.add, color: Colors.white),
        ),

        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
          title: const Text("Clubs", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          bottom: TabBar(
            labelColor: primaryColor,
            unselectedLabelColor: Colors.grey.shade500,
            indicatorColor: primaryColor,
            indicatorWeight: 3,
            tabs: const [
              Tab(text: "My Clubs"),
              Tab(text: "Discover"),
            ],
          ),
        ),
        
        body: TabBarView(
          children: [
            // TAB 1: MY CLUBS
            _buildMyClubsTab(currentUserId),

            // TAB 2: DISCOVER
            _buildDiscoverTab(currentUserId),
          ],
        ),
      ),
    );
  }

  // ================= TAB 1: MY CLUBS =================
  Widget _buildMyClubsTab(String currentUserId) {
    return StreamBuilder<QuerySnapshot>(
      // Query: Find clubs where this user is explicitly in the 'members' array
      stream: FirebaseFirestore.instance
          .collection("clubs")
          .where("members", arrayContains: currentUserId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: primaryColor));
        }

        // Empty State
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
                    "Check out the Discover tab to find communities, or create your own!",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600, height: 1.5),
                  ),
                ],
              ),
            ),
          );
        }

        // Filled State
        return ListView.builder(
          padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 80), // Bottom padding for FAB
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var doc = snapshot.data!.docs[index];
            return _buildClubCard(context, doc);
          },
        );
      },
    );
  }

  // ================= TAB 2: DISCOVER =================
  Widget _buildDiscoverTab(String currentUserId) {
    return StreamBuilder<QuerySnapshot>(
      // We grab public clubs, then locally filter out ones the user is already in
      stream: FirebaseFirestore.instance
          .collection("clubs")
          .where("clubType", isEqualTo: "Public") // Only discover public clubs
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: primaryColor));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No public clubs found to discover."));
        }

        // LOCAL FILTERING: Remove clubs where the user is already a member
        final discoverClubs = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final members = List<String>.from(data["members"] ?? []);
          return !members.contains(currentUserId);
        }).toList();

        // Empty State (If they are already in every single public club)
        if (discoverClubs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline, size: 60, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text("You've joined all available public clubs!", style: TextStyle(color: Colors.grey.shade600)),
              ],
            ),
          );
        }

        // Filled State
        return ListView.builder(
          padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 80),
          itemCount: discoverClubs.length,
          itemBuilder: (context, index) {
            return _buildClubCard(context, discoverClubs[index]);
          },
        );
      },
    );
  }

  // ================= REUSABLE CLUB CARD =================
  Widget _buildClubCard(BuildContext context, QueryDocumentSnapshot doc) {
    var clubData = doc.data() as Map<String, dynamic>;
    
    String name = clubData["name"] ?? "Club";
    String sport = clubData["sport"] ?? "Sport";
    int memberCount = (clubData["members"] as List?)?.length ?? 1;
    String profilePicUrl = clubData["profilePicUrl"] ?? "";

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: primaryColor.withOpacity(0.1),
          backgroundImage: profilePicUrl.isNotEmpty ? NetworkImage(profilePicUrl) : null,
          child: profilePicUrl.isEmpty ? Icon(Icons.shield, color: primaryColor) : null,
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Text("$memberCount members • $sport", style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          // Navigate to Club Details Screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ClubDetailsScreen(clubId: doc.id),
            ),
          );
        },
      ),
    );
  }
}