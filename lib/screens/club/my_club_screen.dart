import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import 'create_club_screen.dart';
import 'club_details_screen.dart';

class MyClubScreen extends StatefulWidget {
  const MyClubScreen({super.key});

  @override
  State<MyClubScreen> createState() => _MyClubScreenState();
}

class _MyClubScreenState extends State<MyClubScreen> {
  final Color primaryColor = const Color(0xFF0C3169);
  
  // 👇 STATE VARIABLE FOR SEARCH 👇
  String searchQuery = "";

  @override
  Widget build(BuildContext context) {
    final currentUserId = AuthService().getCurrentUser()?.uid;

    if (currentUserId == null) {
      return const Scaffold(body: Center(child: Text("Please log in.")));
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        
        // --- FLOATING ACTION BUTTON ---
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
      stream: FirebaseFirestore.instance
          .collection("clubs")
          .where("members", arrayContains: currentUserId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: primaryColor));
        }

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

        return ListView.builder(
          padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 80), 
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var doc = snapshot.data!.docs[index];
            return _buildClubCard(context, doc);
          },
        );
      },
    );
  }

  // ================= TAB 2: DISCOVER (WITH SEARCH) =================
  Widget _buildDiscoverTab(String currentUserId) {
    return Column(
      children: [
        // --- 👇 NEW SEARCH BAR 👇 ---
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: TextField(
            onChanged: (value) {
              // Update state when user types to instantly filter the list below
              setState(() {
                searchQuery = value.toLowerCase();
              });
            },
            decoration: InputDecoration(
              hintText: "Search clubs by name...",
              hintStyle: TextStyle(color: Colors.grey.shade400),
              prefixIcon: Icon(Icons.search, color: primaryColor),
              filled: true,
              fillColor: Colors.grey.shade100,
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        
        // --- THE LIST ---
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection("clubs")
                .where("clubType", isEqualTo: "Public")
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator(color: primaryColor));
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text("No public clubs found to discover."));
              }

              // 👇 LOCAL FILTERING LOGIC 👇
              final discoverClubs = snapshot.data!.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final members = List<String>.from(data["members"] ?? []);
                final clubName = (data["name"] ?? "").toString().toLowerCase();

                // 1. Is the user NOT a member?
                final isNotMember = !members.contains(currentUserId);
                
                // 2. Does the club name match the search query?
                final matchesSearch = searchQuery.isEmpty || clubName.contains(searchQuery);

                // Return true only if both conditions are met
                return isNotMember && matchesSearch;
              }).toList();

              if (discoverClubs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(searchQuery.isNotEmpty ? Icons.search_off : Icons.check_circle_outline, size: 60, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text(
                        searchQuery.isNotEmpty ? "No clubs found matching '$searchQuery'" : "You've joined all available public clubs!", 
                        style: TextStyle(color: Colors.grey.shade600)
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.only(top: 8, left: 16, right: 16, bottom: 80),
                itemCount: discoverClubs.length,
                itemBuilder: (context, index) {
                  return _buildClubCard(context, discoverClubs[index]);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // ================= REUSABLE CLUB CARD =================
  Widget _buildClubCard(BuildContext context, QueryDocumentSnapshot doc) {
    var clubData = doc.data() as Map<String, dynamic>;
    
    String name = clubData["name"] ?? "Club";
    String sport = clubData["sport"] ?? "Sport";
    int memberCount = (clubData["members"] as List?)?.length ?? 1;
    String profilePicUrl = clubData["profilePicUrl"] ?? "";
    String location = clubData["location"] ?? "Unknown Location";
    String clubIdentity = clubData["clubIdentity"] ?? "Casual";
    List<dynamic> skillList = clubData["skillLevels"] ?? ["Open to all"];    
    String skillsString = skillList.join(", ");
    String sportAsset = "assets/${sport.toLowerCase()} icon.png";

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
        
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- 👇 NEW: RichText for perfectly aligned inline icons and text ---
              RichText(
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                text: TextSpan(
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 12, fontWeight: FontWeight.w500, height: 1.4),
                  children: [
                    // 👥 Team Icon
                    WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 4, bottom: 2),
                        child: Icon(Icons.groups, size: 16, color: Colors.grey.shade700),
                      ),
                    ),
                    TextSpan(text: "$memberCount members  •  "),
                    
                    // 🏸 Sport Icon
                    WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 2, bottom: 0),
                        child: Image.asset(sportAsset, width: 30, height: 30),
                      ),
                    ),
                    TextSpan(text: "$skillsString  •  $clubIdentity"),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              
              // --- Location Row ---
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.location_on_outlined, size: 14, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      location, 
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
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