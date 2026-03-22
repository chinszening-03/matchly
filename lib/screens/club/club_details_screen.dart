import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io';

import '../../services/auth_service.dart';

class ClubDetailsScreen extends StatefulWidget {
  final String clubId;

  const ClubDetailsScreen({super.key, required this.clubId});

  @override
  State<ClubDetailsScreen> createState() => _ClubDetailsScreenState();
}

class _ClubDetailsScreenState extends State<ClubDetailsScreen> {
  final Color primaryColor = const Color(0xFF0C3169);
  
  String _selectedSection = 'Activities'; 
  final ImagePicker _picker = ImagePicker();
  bool _isUploadingCover = false;
  bool _isUploadingProfile = false; 

  // ================= FIRESTORE ACTIONS =================

  Future<void> _joinClub(String joinApproval) async {
    final uid = AuthService().getCurrentUser()?.uid;
    if (uid == null) return;

    try {
      if (joinApproval == "Auto approve") {
        // Join instantly
        await FirebaseFirestore.instance.collection("clubs").doc(widget.clubId).update({
          "members": FieldValue.arrayUnion([uid])
        });
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("You joined the club!")));
      } else {
        // Send Request (Add to pending array)
        await FirebaseFirestore.instance.collection("clubs").doc(widget.clubId).update({
          "pendingMembers": FieldValue.arrayUnion([uid])
        });
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Join request sent to Admin!")));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Future<void> _cancelRequest() async {
    final uid = AuthService().getCurrentUser()?.uid;
    if (uid == null) return;

    await FirebaseFirestore.instance.collection("clubs").doc(widget.clubId).update({
      "pendingMembers": FieldValue.arrayRemove([uid])
    });
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

  // --- ADMIN APPROVAL ACTIONS ---
  Future<void> _approveMember(String targetUid) async {
    await FirebaseFirestore.instance.collection("clubs").doc(widget.clubId).update({
      "pendingMembers": FieldValue.arrayRemove([targetUid]),
      "members": FieldValue.arrayUnion([targetUid]),
    });
  }

  Future<void> _rejectMember(String targetUid) async {
    await FirebaseFirestore.instance.collection("clubs").doc(widget.clubId).update({
      "pendingMembers": FieldValue.arrayRemove([targetUid]),
    });
  }

  // ================= IMAGE UPLOADS =================
  
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

      await FirebaseFirestore.instance.collection("clubs").doc(widget.clubId).update({"coverPicUrl": downloadUrl});
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Upload error: $e")));
    } finally {
      if (mounted) setState(() => _isUploadingCover = false);
    }
  }

  Future<void> _pickAndUploadProfilePhoto() async {
    final ImageSource? source = await showCupertinoModalPopup<ImageSource>(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text("Edit Profile Picture"),
        actions: [
          CupertinoActionSheetAction(onPressed: () => Navigator.pop(context, ImageSource.camera), child: const Text("Camera")),
          CupertinoActionSheetAction(onPressed: () => Navigator.pop(context, ImageSource.gallery), child: const Text("Photo Gallery")),
        ],
        cancelButton: CupertinoActionSheetAction(isDestructiveAction: true, onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
      ),
    );

    if (source == null) return;

    final XFile? pickedFile = await _picker.pickImage(source: source, maxWidth: 512, maxHeight: 512, imageQuality: 70);
    if (pickedFile == null) return;

    setState(() => _isUploadingProfile = true);

    try {
      final ref = FirebaseStorage.instance.ref().child('clubs').child(widget.clubId).child('profile.jpg');
      await ref.putFile(File(pickedFile.path));
      final downloadUrl = await ref.getDownloadURL();

      await FirebaseFirestore.instance.collection("clubs").doc(widget.clubId).update({"profilePicUrl": downloadUrl});
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Upload error: $e")));
    } finally {
      if (mounted) setState(() => _isUploadingProfile = false);
    }
  }

  // ================= MAIN BUILD =================

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
        
        // --- Core Data ---
        final String adminId = data["admin"] ?? "";
        final List<String> members = List<String>.from(data["members"] ?? []);
        final List<String> pendingMembers = List<String>.from(data["pendingMembers"] ?? []); // NEW
        final maxMembers = data["maxMembers"]; 
        
        // --- Logic Checks ---
        final bool isMember = members.contains(currentUserId);
        final bool isPending = pendingMembers.contains(currentUserId); // NEW
        final bool isAdmin = currentUserId == adminId;
        final bool isFull = maxMembers != null && members.length >= maxMembers;

        return Scaffold(
          backgroundColor: Colors.grey.shade50,
          
          floatingActionButton: isMember 
              ? FloatingActionButton(
                  backgroundColor: primaryColor,
                  onPressed: () {}, // FAB action logic here later
                  child: const Icon(Icons.add, color: Colors.white),
                )
              : null,
          
          body: Column(
            children: [
              // --- STACK: COVER & PROFILE ---
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.bottomCenter,
                children: [
                  Container(height: 225, width: double.infinity),
                  
                  // Cover
                  Positioned(
                    top: 0, left: 0, right: 0, height: 180,
                    child: Container(
                      color: Colors.grey.shade300,
                      child: data["coverPicUrl"] != null && data["coverPicUrl"].toString().isNotEmpty
                          ? Image.network(data["coverPicUrl"], fit: BoxFit.cover)
                          : Icon(Icons.broken_image_outlined, size: 50, color: Colors.grey.shade500),
                    ),
                  ),
                  
                  Positioned(top: MediaQuery.of(context).padding.top + 10, left: 10, child: const BackButton(color: Colors.white)),

                  if (isAdmin)
                    Positioned(
                      top: 130, right: 12, 
                      child: GestureDetector(
                        onTap: _pickAndUploadCoverPhoto,
                        child: Container(padding: const EdgeInsets.all(8), decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle), child: const Icon(Icons.camera_alt, color: Colors.white, size: 20)),
                      ),
                    ),

                  if (_isUploadingCover)
                    Positioned(top: 0, left: 0, right: 0, height: 180, child: Container(color: Colors.black45, child: const Center(child: CircularProgressIndicator(color: Colors.white)))),

                  // Profile
                  Positioned(
                    bottom: 0, 
                    child: GestureDetector(
                      onTap: isAdmin ? _pickAndUploadProfilePhoto : null,
                      child: Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 4), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8)]),
                            child: CircleAvatar(
                              radius: 45, backgroundColor: Colors.white,
                              child: CircleAvatar(
                                radius: 43, backgroundColor: primaryColor.withOpacity(0.1),
                                backgroundImage: data["profilePicUrl"] != null && data["profilePicUrl"].toString().isNotEmpty ? NetworkImage(data["profilePicUrl"]) : null,
                                child: _isUploadingProfile ? CircularProgressIndicator(color: primaryColor) : (data["profilePicUrl"] == null || data["profilePicUrl"].toString().isEmpty ? Icon(Icons.shield, size: 40, color: primaryColor) : null),
                              ),
                            ),
                          ),
                          if (isAdmin)
                            Positioned(bottom: 0, right: 0, child: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: Colors.black54, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)), child: const Icon(Icons.camera_alt, color: Colors.white, size: 14))),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              
              // --- CLUB SUMMARY ---
              // Passed isPending down to the summary section
              _buildClubSummarySection(data, isMember, isPending, isAdmin, members, isFull),

              // --- LOGO NAVIGATION ---
              _buildLogoNavigation(),

              // --- CONTENT SWITCH ---
              Expanded(child: _buildSelectedContent(members, pendingMembers, adminId, isAdmin)),
            ],
          ),
        );
      }
    );
  }

  // ================= CONTENT SWITCHER =================
  Widget _buildSelectedContent(List<String> members, List<String> pendingMembers, String adminId, bool isAdmin) {
    switch (_selectedSection) {
      case 'Activities': return const Center(child: Text("No club activities yet."));
      case 'Members': return _buildMembersTab(members, pendingMembers, adminId, isAdmin); 
      case 'Gallery': return const Center(child: Text("Gallery coming soon!")); 
      case 'Chat': return const Center(child: Text("Club Chat coming soon!")); 
      default: return const SizedBox.shrink();
    }
  }

  // ================= MEMBERS TAB (UPDATED WITH PENDING LOGIC) =================
  Widget _buildMembersTab(List<String> members, List<String> pendingMembers, String adminId, bool isAdmin) {
    // Combine both lists so we only have to make ONE Firebase call to get all profiles
    final allUids = [...pendingMembers, ...members];

    return FutureBuilder<List<DocumentSnapshot>>(
      future: Future.wait(allUids.map((uid) => FirebaseFirestore.instance.collection("users").doc(uid).get())),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text("No members found."));
        
        // Separate the loaded profiles back into Pending and Active groups
        final pendingDocs = snapshot.data!.where((doc) => pendingMembers.contains(doc.id)).toList();
        final memberDocs = snapshot.data!.where((doc) => members.contains(doc.id)).toList();

        return ListView(
          padding: const EdgeInsets.all(16), 
          children: [
            // --- PENDING REQUESTS SECTION (ADMIN ONLY) ---
            if (isAdmin && pendingDocs.isNotEmpty) ...[
              const Text("Pending Requests", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 8),
              ...pendingDocs.map((userDoc) {
                var data = userDoc.data() as Map<String, dynamic>?;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: primaryColor.withOpacity(0.1),
                    backgroundImage: data?["profilePicUrl"]?.isNotEmpty == true ? NetworkImage(data!["profilePicUrl"]) : null,
                    child: data?["profilePicUrl"]?.isEmpty == true ? Icon(Icons.person, color: primaryColor) : null,
                  ),
                  title: Text(data?["name"] ?? "Player", style: const TextStyle(fontWeight: FontWeight.bold)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () => _rejectMember(userDoc.id), // Reject
                      ),
                      IconButton(
                        icon: const Icon(Icons.check_circle, color: Colors.green),
                        onPressed: () => _approveMember(userDoc.id), // Approve
                      ),
                    ],
                  ),
                );
              }),
              const Divider(height: 32),
            ],

            // --- ACTIVE MEMBERS SECTION ---
            Text("Active Members (${memberDocs.length})", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 8),
            ...memberDocs.map((userDoc) {
              var data = userDoc.data() as Map<String, dynamic>?;
              bool isHost = userDoc.id == adminId;

              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: primaryColor.withOpacity(0.1), 
                  backgroundImage: data?["profilePicUrl"]?.isNotEmpty == true ? NetworkImage(data!["profilePicUrl"]) : null, 
                  child: data?["profilePicUrl"]?.isEmpty == true ? Icon(Icons.person, color: primaryColor) : null
                ), 
                title: Text(data?["name"] ?? "Player", style: const TextStyle(fontWeight: FontWeight.bold)), 
                trailing: isHost 
                  ? Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: primaryColor, borderRadius: BorderRadius.circular(12)), child: const Text("Admin", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))) 
                  : null
              );
            }),
          ],
        );
      }
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

  Widget _buildClubSummarySection(Map<String, dynamic> data, bool isMember, bool isPending, bool isAdmin, List<String> members, bool isFull) {
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
          
          // --- DYNAMIC ACTION BUTTONS ---
          
          // 1. Not a member and hasn't requested yet
          if (!isMember && !isPending) 
            SizedBox(
              width: double.infinity, height: 45, 
              child: ElevatedButton(
                onPressed: isFull ? null : () => _joinClub(joinApproval), 
                style: ElevatedButton.styleFrom(backgroundColor: primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), elevation: 0), 
                child: Text(isFull ? "Club is Full" : (joinApproval == "Auto approve" ? "Join Club" : "Request to Join"), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15))
              )
            ),

          // 2. Not a member, but request is pending
          if (!isMember && isPending)
            SizedBox(
              width: double.infinity, height: 45, 
              child: OutlinedButton(
                onPressed: _cancelRequest, 
                style: OutlinedButton.styleFrom(foregroundColor: Colors.grey.shade700, side: BorderSide(color: Colors.grey.shade300), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), 
                child: const Text("Cancel Request", style: TextStyle(fontWeight: FontWeight.bold))
              )
            ),
          
          // 3. Is a regular member
          if (isMember && !isAdmin) 
            SizedBox(
              width: double.infinity, height: 45, 
              child: OutlinedButton(
                onPressed: _leaveClub, 
                style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), 
                child: const Text("Leave Club", style: TextStyle(fontWeight: FontWeight.bold))
              )
            ),
          
          // 4. Is the Admin
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