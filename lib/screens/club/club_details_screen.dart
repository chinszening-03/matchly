import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io';

import '../../services/auth_service.dart';
// import 'activitiy_details_screen.dart'; // Uncomment if you need to navigate to an activity

class ClubDetailsScreen extends StatefulWidget {
  final String clubId;

  const ClubDetailsScreen({super.key, required this.clubId});

  @override
  State<ClubDetailsScreen> createState() => _ClubDetailsScreenState();
}

class _ClubDetailsScreenState extends State<ClubDetailsScreen> {
  final Color primaryColor = const Color(0xFF0C3169);
  
  // --- STATE VARIABLES ---
  String _selectedSection = 'Activities'; 
  final ImagePicker _picker = ImagePicker();
  bool _isUploadingCover = false;

  // --- FIRESTORE ACTIONS ---
  Future<void> _joinClub(String joinApproval) async {
    final uid = AuthService().getCurrentUser()?.uid;
    if (uid == null) return;

    try {
      if (joinApproval == "Auto approve") {
        await FirebaseFirestore.instance.collection("clubs").doc(widget.clubId).update({
          "members": FieldValue.arrayUnion([uid])
        });
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("You joined the club!")));
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Join request sent to Admin!")));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Future<void> _leaveClub() async {
    final uid = AuthService().getCurrentUser()?.uid;
    if (uid == null) return;

    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Leave Club?", style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text("Are you sure you want to leave this club?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Leave", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
        ],
      ),
    ) ?? false;

    if (confirm) {
      await FirebaseFirestore.instance.collection("clubs").doc(widget.clubId).update({
        "members": FieldValue.arrayRemove([uid])
      });
      if (mounted) Navigator.pop(context); 
    }
  }

  // --- COVER PHOTO UPLOAD LOGIC ---
  Future<void> _pickAndUploadCoverPhoto() async {
    final ImageSource? source = await showCupertinoModalPopup<ImageSource>(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text("Edit Cover Photo"),
        actions: [
          CupertinoActionSheetAction(onPressed: () => Navigator.pop(context, ImageSource.camera), child: const Text("Camera")),
          CupertinoActionSheetAction(onPressed: () => Navigator.pop(context, ImageSource.gallery), child: const Text("Photo Gallery")),
        ],
        cancelButton: CupertinoActionSheetAction(isDestructiveAction: true, onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
      ),
    );

    if (source == null) return;

    final XFile? pickedFile = await _picker.pickImage(source: source, maxWidth: 1024, maxHeight: 512, imageQuality: 70);
    if (pickedFile == null) return;

    setState(() => _isUploadingCover = true);

    try {
      final ref = FirebaseStorage.instance.ref().child('clubs').child(widget.clubId).child('cover.jpg');
      await ref.putFile(File(pickedFile.path));
      final downloadUrl = await ref.getDownloadURL();

      await FirebaseFirestore.instance.collection("clubs").doc(widget.clubId).update({
        "coverPicUrl": downloadUrl
      });
      
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Cover photo updated!")));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Upload error: $e")));
    } finally {
      if (mounted) setState(() => _isUploadingCover = false);
    }
  }

  // --- FAB ACTIONS MODAL ---
  void _showFabActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Create or Invite", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildFabModalOption(Icons.add_circle, "Create\nActivity", () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Create Activity linking coming soon!")));
                    }),
                    _buildFabModalOption(Icons.campaign, "Post\nAnnouncement", () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Announcements coming soon!")));
                    }),
                    _buildFabModalOption(Icons.person_add, "Invite\nMembers", () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Invites coming soon!")));
                    }),
                  ],
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFabModalOption(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: primaryColor.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, size: 30, color: primaryColor),
          ),
          const SizedBox(height: 12),
          Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, height: 1.2)),
        ],
      ),
    );
  }

  // =========================================================================

  @override
  Widget build(BuildContext context) {
    final currentUserId = AuthService().getCurrentUser()?.uid;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection("clubs").doc(widget.clubId).snapshots(),
      builder: (context, snapshot) {
        
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Scaffold(body: Center(child: Text("Club not found.")));
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final String adminId = data["admin"] ?? "";
        final List<String> members = List<String>.from(data["members"] ?? []);
        final maxMembers = data["maxMembers"]; 
        
        final bool isMember = members.contains(currentUserId);
        final bool isAdmin = currentUserId == adminId;
        final bool isFull = maxMembers != null && members.length >= maxMembers;

        return Scaffold(
          backgroundColor: Colors.white,
          
          // Floating Action Button
          floatingActionButton: isMember 
              ? FloatingActionButton(
                  backgroundColor: primaryColor,
                  onPressed: () => _showFabActions(context),
                  child: const Icon(Icons.add, color: Colors.white),
                )
              : null,
          
          body: Column(
            children: [
              // --- OVERLAPPING COVER & PROFILE PHOTO STACK ---
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.bottomCenter,
                children: [
                  // Total height container (Cover 180 + half of profile 45 = 225)
                  Container(height: 225, width: double.infinity),
                  
                  // 1. COVER PHOTO
                  Positioned(
                    top: 0, left: 0, right: 0, height: 180,
                    child: Container(
                      color: Colors.grey.shade300,
                      child: data["coverPicUrl"] != null && data["coverPicUrl"].toString().isNotEmpty
                          ? Image.network(data["coverPicUrl"], fit: BoxFit.cover)
                          : Icon(Icons.broken_image_outlined, size: 50, color: Colors.grey.shade500),
                    ),
                  ),
                  
                  // Back Button 
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 10,
                    left: 10,
                    child: const BackButton(color: Colors.white),
                  ),

                  // Edit Cover Button (Admin only)
                  if (isAdmin)
                    Positioned(
                      top: 130, right: 12, 
                      child: GestureDetector(
                        onTap: _pickAndUploadCoverPhoto,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                        ),
                      ),
                    ),

                  // Uploading Indicator for Cover
                  if (_isUploadingCover)
                    Positioned(
                      top: 0, left: 0, right: 0, height: 180,
                      child: Container(
                        color: Colors.black45,
                        child: const Center(child: CircularProgressIndicator(color: Colors.white)),
                      ),
                    ),

                  // 2. PROFILE PICTURE
                  Positioned(
                    bottom: 0, 
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4), 
                      ),
                      child: CircleAvatar(
                        radius: 45,
                        backgroundColor: Colors.white,
                        child: CircleAvatar(
                          radius: 45, 
                          backgroundColor: primaryColor.withOpacity(0.1),
                          backgroundImage: data["profilePicUrl"] != null && data["profilePicUrl"].toString().isNotEmpty 
                              ? NetworkImage(data["profilePicUrl"]) 
                              : null,
                          child: data["profilePicUrl"] == null || data["profilePicUrl"].toString().isEmpty 
                              ? Icon(Icons.shield, size: 40, color: primaryColor) 
                              : null,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              
              // --- CLUB SUMMARY ---
              _buildClubSummarySection(data, isMember, isAdmin, members, isFull),

              // --- LOGO NAVIGATION ---
              _buildLogoNavigation(),

              // --- CONTENT SWITCH ---
              Expanded(child: _buildSelectedContent(members, adminId)),
            ],
          ),
        );
      }
    );
  }

  // ================= CONTENT SWITCHER =================
  Widget _buildSelectedContent(List<String> members, String adminId) {
    switch (_selectedSection) {
      case 'Activities': return _buildActivitiesTab();
      case 'Members': return _buildMembersTab(members, adminId); 
      case 'Gallery': return _buildPlaceholderTab("Gallery coming soon!"); 
      case 'Chat': return _buildPlaceholderTab("Club Chat coming soon!"); 
      default: return const SizedBox.shrink();
    }
  }

  Widget _buildPlaceholderTab(String text) {
     return Center(child: Padding(padding: const EdgeInsets.all(32), child: Text(text, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600))));
  }

  Widget _buildMembersTab(List<String> members, String adminId) {
    return FutureBuilder<List<DocumentSnapshot>>(
      future: Future.wait(members.map((uid) => FirebaseFirestore.instance.collection("users").doc(uid).get())),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text("No members found."));
        
        return ListView.builder(
          padding: const EdgeInsets.all(16), 
          itemCount: snapshot.data!.length, 
          itemBuilder: (context, index) {
            var userDoc = snapshot.data![index].data() as Map<String, dynamic>?;
            String name = userDoc?["name"] ?? "Player";
            String picUrl = userDoc?["profilePicUrl"] ?? "";
            String uid = snapshot.data![index].id;
            bool isHost = uid == adminId;
            
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: primaryColor.withOpacity(0.1), 
                backgroundImage: picUrl.isNotEmpty ? NetworkImage(picUrl) : null, 
                child: picUrl.isEmpty ? Icon(Icons.person, color: primaryColor) : null
              ), 
              title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)), 
              trailing: isHost 
                ? Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: primaryColor, borderRadius: BorderRadius.circular(12)), child: const Text("Admin", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))) 
                : null
            );
        });
      });
  }

  Widget _buildActivitiesTab() {
     return Center(
       child: Column(
         mainAxisAlignment: MainAxisAlignment.center,
         children: [
           Icon(Icons.event_busy, size: 48, color: Colors.grey.shade300),
           const SizedBox(height: 16),
           Text("No club activities yet.", style: TextStyle(color: Colors.grey.shade600)),
         ],
       ),
     );
  }

  // ================= UI HELPERS =================
  Widget _buildLogoNavigation() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildLogoNavItem(Icons.event_available, "Activities"),
          _buildLogoNavItem(Icons.groups_outlined, "Members"),
          _buildLogoNavItem(Icons.photo_library_outlined, "Gallery"),
          _buildLogoNavItem(Icons.forum_outlined, "Chat"),
        ],
      ),
    );
  }

  Widget _buildLogoNavItem(IconData icon, String label) {
    bool isSelected = _selectedSection == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedSection = label),
      child: Container(
        padding: const EdgeInsets.all(12),
        width: 75,
        decoration: BoxDecoration(
          color: isSelected ? primaryColor.withOpacity(0.1) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: isSelected ? Border.all(color: primaryColor) : Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? primaryColor : Colors.grey.shade700, size: 24),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: isSelected ? primaryColor : Colors.grey.shade700)),
          ],
        ),
      ),
    );
  }

  Widget _buildClubSummarySection(Map<String, dynamic> data, bool isMember, bool isAdmin, List<String> members, bool isFull) {
     final name = data["name"] ?? "Club Name";
     final description = data["description"] ?? "No description.";
     final location = data["location"] ?? "Unknown Location";
     final sport = data["sport"] ?? "Sport";
     final clubIdentity = data["clubIdentity"] ?? "Casual Club";
     final clubType = data["clubType"] ?? "Public";
     final joinApproval = data["joinApproval"] ?? "Auto approve";

    return Container(
      color: Colors.white, 
      width: double.infinity, 
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20), 
      child: Column(
        children: [
          const SizedBox(height: 12), 
          Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          
          Wrap(spacing: 8, alignment: WrapAlignment.center, children: [_buildBadge(sport, Icons.sports_tennis), _buildBadge(clubIdentity, Icons.local_fire_department), _buildBadge(clubType, clubType == "Public" ? Icons.public : Icons.lock)]),
          const SizedBox(height: 16),
          
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.location_on_outlined, size: 16, color: Colors.grey.shade600), const SizedBox(width: 4), Text(location, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)), const SizedBox(width: 16), Icon(Icons.people_outline, size: 16, color: Colors.grey.shade600), const SizedBox(width: 4), Text("${members.length} Members", style: TextStyle(color: Colors.grey.shade600, fontSize: 13))]),
          const SizedBox(height: 20),
          
          Text(description, textAlign: TextAlign.center, style: TextStyle(color: Colors.black87, fontSize: 14, height: 1.4)),
          const SizedBox(height: 24),
          
          // Action Buttons
          if (!isMember) 
            SizedBox(
              width: double.infinity, height: 45, 
              child: ElevatedButton(
                onPressed: isFull ? null : () => _joinClub(joinApproval), 
                style: ElevatedButton.styleFrom(backgroundColor: primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), elevation: 0), 
                child: Text(isFull ? "Club is Full" : (joinApproval == "Auto approve" ? "Join Club" : "Request to Join"), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15))
              )
            ),
          
          if (isMember && !isAdmin) 
            SizedBox(
              width: double.infinity, height: 45, 
              child: OutlinedButton(
                onPressed: _leaveClub, 
                style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), 
                child: const Text("Leave Club", style: TextStyle(fontWeight: FontWeight.bold))
              )
            ),
          
          if (isAdmin) 
            SizedBox(
              width: double.infinity, height: 45, 
              child: ElevatedButton(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Manage settings coming soon!"))), 
                style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade200, foregroundColor: Colors.black, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), 
                child: const Text("Manage Club", style: TextStyle(fontWeight: FontWeight.bold))
              )
            ),
      ]
    ));
  }

  Widget _buildBadge(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), 
      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(20)), 
      child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 12, color: Colors.grey.shade700), const SizedBox(width: 4), Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade700))])
    );
  }
}