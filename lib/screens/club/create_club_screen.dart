import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io';
import '../activity/location_search_screen.dart'; 

class CreateClubScreen extends StatefulWidget {
  const CreateClubScreen({super.key});

  @override
  State<CreateClubScreen> createState() => _CreateClubScreenState();
}

class _CreateClubScreenState extends State<CreateClubScreen> {
  final Color primaryColor = const Color(0xFF0C3169);
  int currentStep = 0;
  bool isUploading = false;

  // --- Step 1: Basic Info ---
  File? clubImage;
  final ImagePicker _picker = ImagePicker();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descController = TextEditingController();

  // --- Step 2: Location ---
  String locationName = "";
  double? lat;
  double? lng;
  double radiusKm = 10.0;

  // --- Step 3: Sport & Level ---
  String selectedSport = "Badminton"; // Default
  final List<String> sports = ["Badminton", "Pickleball", "Tennis", "Futsal", "Basketball", "Football"];
  String skillLevel = "Open to all";
  final List<String> skillLevels = ["Open to all", "Beginner", "Intermediate", "Advanced"];

  // --- Step 4-6: Privacy, Settings, Identity ---
  String clubType = "Public"; // Public, Private
  String joinApproval = "Auto approve"; // Auto approve, Admin approval
  final TextEditingController maxMembersController = TextEditingController();
  String eventCreation = "Only admin"; // Only admin, Everyone
  String clubIdentity = "Casual Club"; // Competitive, Casual, Training, Social
  final List<String> identities = ["Competitive Club", "Casual Club", "Training Club", "Social Club"];

  // --- Image Picker ---
  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source, maxWidth: 512, maxHeight: 512, imageQuality: 80);
    if (pickedFile != null) setState(() => clubImage = File(pickedFile.path));
  }

  void _showImageSourceSheet() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text("Club Picture"),
        actions: [
          CupertinoActionSheetAction(onPressed: () { Navigator.pop(context); _pickImage(ImageSource.camera); }, child: const Text("Camera")),
          CupertinoActionSheetAction(onPressed: () { Navigator.pop(context); _pickImage(ImageSource.gallery); }, child: const Text("Photo Gallery")),
        ],
        cancelButton: CupertinoActionSheetAction(isDestructiveAction: true, onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
      ),
    );
  }

  // --- SAVE TO FIREBASE ---
  Future<void> saveClub() async {
    if (nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Club Name is required!")));
      return;
    }

    setState(() => isUploading = true);
    final uid = FirebaseAuth.instance.currentUser!.uid;
    String? imageUrl;

    try {
      // 1. Upload Image (If exists)
      if (clubImage != null) {
        Reference ref = FirebaseStorage.instance.ref().child('clubs').child('${DateTime.now().millisecondsSinceEpoch}.jpg');
        UploadTask uploadTask = ref.putFile(clubImage!);
        TaskSnapshot snapshot = await uploadTask;
        imageUrl = await snapshot.ref.getDownloadURL();
      }

      // 2. Save to Firestore
      int? maxMem = int.tryParse(maxMembersController.text.trim());

      await FirebaseFirestore.instance.collection("clubs").add({
        "name": nameController.text.trim(),
        "description": descController.text.trim(),
        "profilePicUrl": imageUrl ?? "",
        
        "location": locationName,
        "lat": lat,
        "lng": lng,
        "radiusKm": radiusKm,
        
        "sport": selectedSport,
        "skillLevel": skillLevel,
        
        "clubType": clubType,
        "joinApproval": joinApproval,
        "maxMembers": maxMem, // Can be null if left blank
        "eventCreation": eventCreation,
        "clubIdentity": clubIdentity,

        "admin": uid,
        "members": [uid], // Admin is the first member
        "createdAt": FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      Navigator.pop(context); // Go back to My Club screen
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Club created successfully!")));

    } catch (e) {
      setState(() => isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text("Create Club", style: TextStyle(color: Colors.black)),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Progress Bar
                LinearProgressIndicator(value: (currentStep + 1) / 4, backgroundColor: Colors.grey.shade200, color: primaryColor),
                
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: _buildCurrentStep(),
                  ),
                ),

                // Bottom Buttons
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey.shade200))),
                  child: Row(
                    children: [
                      if (currentStep > 0)
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                            onPressed: () => setState(() => currentStep--),
                            child: const Text("Back", style: TextStyle(color: Colors.black)),
                          ),
                        ),
                      if (currentStep > 0) const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: primaryColor, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                          onPressed: () {
                            if (currentStep == 0 && nameController.text.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter a Club Name")));
                              return;
                            }
                            if (currentStep < 3) {
                              setState(() => currentStep++);
                            } else {
                              saveClub();
                            }
                          },
                          child: Text(currentStep == 3 ? "Create Club" : "Next", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),

            // Loading Overlay
            if (isUploading)
              Container(
                color: Colors.black45,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: primaryColor),
                        const SizedBox(height: 16),
                        const Text("Creating Club...", style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (currentStep) {
      case 0: return _buildStep1();
      case 1: return _buildStep2();
      case 2: return _buildStep3();
      case 3: return _buildStep4();
      default: return const SizedBox.shrink();
    }
  }

  // ================= UI STEPS =================
  Widget _buildLabel(String text) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)));

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Basic Info", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text("Give your club an identity.", style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 30),
        
        Center(
          child: GestureDetector(
            onTap: _showImageSourceSheet,
            child: CircleAvatar(
              radius: 50,
              backgroundColor: primaryColor.withOpacity(0.1),
              backgroundImage: clubImage != null ? FileImage(clubImage!) : null,
              child: clubImage == null ? Icon(Icons.camera_alt, size: 40, color: primaryColor) : null,
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Center(child: Text("Club Logo (Optional)", style: TextStyle(color: Colors.grey, fontSize: 12))),
        const SizedBox(height: 30),

        _buildLabel("Club Name *"),
        TextField(
          controller: nameController,
          decoration: InputDecoration(hintText: "e.g., Weekend Smashers KL", filled: true, fillColor: Colors.grey.shade100, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
        ),
        const SizedBox(height: 20),

        _buildLabel("Description"),
        TextField(
          controller: descController,
          maxLines: 3,
          decoration: InputDecoration(hintText: "What is this club about?", filled: true, fillColor: Colors.grey.shade100, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Location", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text("Where does your club usually play?", style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 30),

        _buildLabel("Primary Location"),
        TextField(
          readOnly: true,
          controller: TextEditingController(text: locationName),
          onTap: () async {
            final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => const LocationSearchScreen()));
            if (result != null && result is Map<String, dynamic>) {
              setState(() {
                locationName = result["name"] ?? "";
                lat = result["lat"];
                lng = result["lng"];
              });
            }
          },
          decoration: InputDecoration(hintText: "Search area or city", prefixIcon: Icon(Icons.location_on, color: primaryColor), filled: true, fillColor: Colors.grey.shade100, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
        ),
        const SizedBox(height: 30),

        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          _buildLabel("Play Area Radius"),
          Text("${radiusKm.toInt()} km", style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
        ]),
        Slider(value: radiusKm, min: 1, max: 50, activeColor: primaryColor, onChanged: (val) => setState(() => radiusKm = val)),
      ],
    );
  }

  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Sport & Level", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 30),

        _buildLabel("Primary Sport"),
        Wrap(
          spacing: 10, runSpacing: 10,
          children: sports.map((s) => ChoiceChip(
            label: Text(s),
            selected: selectedSport == s,
            selectedColor: primaryColor.withOpacity(0.2),
            onSelected: (val) { if(val) setState(() => selectedSport = s); },
          )).toList(),
        ),
        const SizedBox(height: 30),

        _buildLabel("Skill Level Requirement"),
        Wrap(
          spacing: 10, runSpacing: 10,
          children: skillLevels.map((lvl) => ChoiceChip(
            label: Text(lvl),
            selected: skillLevel == lvl,
            selectedColor: primaryColor.withOpacity(0.2),
            onSelected: (val) { if(val) setState(() => skillLevel = lvl); },
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildStep4() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Rules & Settings", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 24),

        _buildLabel("Club Identity"),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: identities.map((id) => ChoiceChip(
            label: Text(id, style: TextStyle(fontSize: 12, color: clubIdentity == id ? Colors.white : Colors.black)),
            selected: clubIdentity == id,
            selectedColor: primaryColor,
            onSelected: (val) { if(val) setState(() => clubIdentity = id); },
          )).toList(),
        ),
        const SizedBox(height: 24),

        _buildLabel("Privacy"),
        Row(children: [
          Expanded(child: RadioListTile<String>(title: const Text("Public"), subtitle: const Text("Anyone can join", style: TextStyle(fontSize: 11)), value: "Public", groupValue: clubType, onChanged: (v) => setState(() => clubType = v!))),
          Expanded(child: RadioListTile<String>(title: const Text("Private"), subtitle: const Text("Invite only", style: TextStyle(fontSize: 11)), value: "Private", groupValue: clubType, onChanged: (v) => setState(() => clubType = v!))),
        ]),
        
        const Divider(height: 30),

        _buildLabel("Join Approval"),
        DropdownButtonFormField<String>(
          value: joinApproval,
          decoration: InputDecoration(filled: true, fillColor: Colors.grey.shade100, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
          items: ["Auto approve", "Admin approval"].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (v) => setState(() => joinApproval = v!),
        ),
        const SizedBox(height: 20),

        _buildLabel("Who can create games?"),
        DropdownButtonFormField<String>(
          value: eventCreation,
          decoration: InputDecoration(filled: true, fillColor: Colors.grey.shade100, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
          items: ["Only admin", "Everyone"].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (v) => setState(() => eventCreation = v!),
        ),
        const SizedBox(height: 20),

        _buildLabel("Max Members (Optional)"),
        TextField(
          controller: maxMembersController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(hintText: "Leave blank for unlimited", filled: true, fillColor: Colors.grey.shade100, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
        ),
      ],
    );
  }
}