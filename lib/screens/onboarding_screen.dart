import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart'; // Added for CupertinoActionSheet
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart'; // Uncommented
import 'package:image_picker/image_picker.dart'; // Uncommented
import 'dart:io'; // Uncommented
import 'home/home_screen.dart';
import '../screens/activity/location_search_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

double? userLat;
double? userLng;

class _OnboardingScreenState extends State<OnboardingScreen> {
  int step = 0;
  final Color darkBlue = const Color(0xFF0D47A1);
  bool isUploading = false; // Loading state for final step

  // --- STEP 1: BASIC INFO ---
  final TextEditingController nameController = TextEditingController();
  final TextEditingController bioController = TextEditingController();
  String gender = "";
  final List<String> genders = ["Male", "Female", "Prefer not to say"];
  
  // 👇 NEW STATE VARIABLES 👇
  File? profileImage; // To hold the locally picked image
  final ImagePicker _picker = ImagePicker(); // ImagePicker instance


  // --- STEP 2: SPORTS PROFILE ---
  List<Map<String, String>> userSports = [];
  final List<String> availableSports = [
    "Badminton", "Football", "Basketball", "Tennis", 
    "Futsal", "Golf", "Pickleball", "Pilates"
  ];
  final List<String> skillLevels = [
    "Beginner", "Intermediate", "Advanced", "Competitive"
  ];

  // --- STEP 3: LOCATION ---
  final TextEditingController locationController = TextEditingController();
  double radius = 10.0; 

  // --- STEP 4: AVAILABILITY ---
  List<String> selectedDays = [];
  List<String> selectedTimes = [];
  
  final List<String> daysOptions = [
    "Weekdays", "Weekends", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"
  ];
  final List<String> timeOptions = [
    "Morning", "Afternoon", "Night"
  ];

  // ================= 👇 IMAGE PICKING LOGIC 👇 =================
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 512, // Compress the image to save bandwidth/storage
        maxHeight: 512,
        imageQuality: 80, // Slightly lower quality
      );

      if (pickedFile != null) {
        setState(() {
          profileImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error picking image: $e")),
      );
    }
  }

  // Helper function to show native-style selection sheet
  void _showImageSourceActionSheet(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text("Select Profile Picture Source"),
        actions: [
          CupertinoActionSheetAction(
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.camera_alt, color: CupertinoColors.activeBlue),
                SizedBox(width: 10),
                Text("Camera"),
              ],
            ),
            onPressed: () {
              Navigator.pop(context);
              _pickImage(ImageSource.camera);
            },
          ),
          CupertinoActionSheetAction(
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.photo_library, color: CupertinoColors.activeBlue),
                SizedBox(width: 10),
                Text("Photo Gallery"),
              ],
            ),
            onPressed: () {
              Navigator.pop(context);
              _pickImage(ImageSource.gallery);
            },
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDestructiveAction: true,
          child: const Text("Cancel"),
          onPressed: () => Navigator.pop(context),
        ),
      ),
    );
  }
  // ================= 👆 IMAGE PICKING LOGIC 👆 =================

  // ================= SAVE TO FIREBASE =================
  Future<void> saveProfile() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    setState(() => isUploading = true); // Start loading spinner

    String? profilePicUrl;

    // 👇 NEW UPLOAD LOGIC 👇
    if (profileImage != null) {
      try {
        // Create storage reference: users/USER_ID/profile_pic.jpg
        Reference storageRef = FirebaseStorage.instance
            .ref()
            .child('users')
            .child(uid)
            .child('profile_pic.jpg');

        // Upload file
        UploadTask uploadTask = storageRef.putFile(profileImage!);
        TaskSnapshot snapshot = await uploadTask;

        // Get download URL
        profilePicUrl = await snapshot.ref.getDownloadURL();
      } catch (e) {
        // Handle upload errors
        print("Storage upload error: $e");
      }
    }
    // 👆 ================= 👆

    // If "Skip" was pressed, use display name. If mandatory step, it's validated already.
    final finalDisplayName = nameController.text.isEmpty
          ? FirebaseAuth.instance.currentUser!.displayName ?? "Player"
          : nameController.text.trim();

    await FirebaseFirestore.instance.collection("users").doc(uid).set({
      "name": finalDisplayName,
      "gender": gender,
      "bio": bioController.text.trim(),
      "lat": userLat, 
      "lng": userLng,
      // 👇 Save the new URL 👇
      "profilePicUrl": profilePicUrl, 

      "sportsProfile": userSports, 
      "location": locationController.text.trim(),
      "radiusKm": radius,
      "availableDays": selectedDays,
      "availableTimes": selectedTimes,
      "profileCompleted": true,
      "createdAt": Timestamp.now(),
    }, SetOptions(merge: true));

    setState(() => isUploading = false); // Stop loading spinner

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  // ================= UI HELPERS =================
  Widget requiredLabel(String text) {
    return RichText(
      text: TextSpan(
        text: text,
        style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
        children: const [
          TextSpan(text: " *", style: TextStyle(color: Colors.red)),
        ],
      ),
    );
  }

  // ================= STEP 1: BASIC INFO =================
  Widget buildStep1() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Let's set up your profile", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text("Tell us a bit about yourself. Name and gender are required.", style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),

          // 👇 UPDATED Profile Picture Widget 👇
          Center(
            child: GestureDetector(
              onTap: () => _showImageSourceActionSheet(context), // Open selection sheet
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey.shade100,
                    // If image picked, show it. Otherwise show default grey person icon.
                    backgroundImage: profileImage != null ? FileImage(profileImage!) : null,
                    child: profileImage == null 
                        ? Icon(Icons.person, size: 50, color: Colors.grey.shade400)
                        : null,
                  ),
                  Positioned(
                    bottom: 0, right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(color: Color(0xFF0D47A1), shape: BoxShape.circle),
                      child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                    ),
                  )
                ],
              ),
            ),
          ),
          const SizedBox(height: 30),

          // Name
          requiredLabel("Display Name"),
          const SizedBox(height: 8),
          TextField(
            controller: nameController,
            decoration: InputDecoration(
              hintText: "What should teammates call you?",
              filled: true, fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 20),

          // Gender
          requiredLabel("Gender"),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            children: genders.map((g) {
              final isSelected = gender == g;
              return ChoiceChip(
                label: Text(g, style: TextStyle(color: isSelected ? Colors.white : Colors.black87)),
                selected: isSelected,
                selectedColor: darkBlue,
                backgroundColor: Colors.grey.shade100,
                onSelected: (_) => setState(() => gender = g),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Bio
          const Text("Short Bio (Optional)", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: bioController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: "E.g., I love playing doubles on weekends!",
              filled: true, fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
        ],
      ),
    );
  }

  // ================= STEP 2: SPORTS =================
  Widget buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Sports Profile", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text("Add the sports you play and your skill level.", style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 20),

        Expanded(
          child: ListView.builder(
            itemCount: userSports.length,
            itemBuilder: (context, index) {
              final sportData = userSports[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: darkBlue.withOpacity(0.1), shape: BoxShape.circle),
                      child: Icon(Icons.sports_esports, color: darkBlue),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(sportData["sport"]!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 4),
                          DropdownButton<String>(
                            value: sportData["level"],
                            isDense: true,
                            underline: const SizedBox(),
                            style: TextStyle(color: darkBlue, fontSize: 14, fontWeight: FontWeight.w600),
                            icon: Icon(Icons.keyboard_arrow_down, color: darkBlue, size: 16),
                            items: skillLevels.map((lvl) => DropdownMenuItem(value: lvl, child: Text(lvl))).toList(),
                            onChanged: (newLevel) {
                              if (newLevel != null) {
                                setState(() => userSports[index]["level"] = newLevel);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.redAccent),
                      // 👇 DELETED DEPRECATED LINE 👇
                      onPressed: () => setState(() => userSports.removeAt(index)),
                    )
                  ],
                ),
              );
            },
          ),
        ),

        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text("Add Sport"),
            style: OutlinedButton.styleFrom(
              foregroundColor: darkBlue,
              side: BorderSide(color: darkBlue, width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                builder: (context) {
                  return Container(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Select Sport", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        Expanded(
                          child: ListView.builder(
                            itemCount: availableSports.length,
                            itemBuilder: (context, index) {
                              final sportName = availableSports[index];
                              final isAlreadyAdded = userSports.any((s) => s["sport"] == sportName);
                              return ListTile(
                                title: Text(sportName, style: TextStyle(color: isAlreadyAdded ? Colors.grey : Colors.black)),
                                trailing: isAlreadyAdded ? const Icon(Icons.check, color: Colors.green) : const Icon(Icons.add_circle_outline),
                                onTap: isAlreadyAdded ? null : () {
                                  setState(() {
                                    userSports.add({"sport": sportName, "level": "Beginner"}); // Default to Beginner
                                  });
                                  Navigator.pop(context);
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                }
              );
            },
          ),
        ),
      ],
    );
  }

  // ================= STEP 3: LOCATION =================
  Widget buildStep3() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        "Location", 
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)
      ),
      const SizedBox(height: 8),
      const Text(
        "Where do you usually play? This helps us find matches near you.", 
        style: TextStyle(color: Colors.grey)
      ),
      const SizedBox(height: 24),

      const Text(
        "Current Location / Area", 
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
      ),
      const SizedBox(height: 8),
      
      // 👇 TRIGGER FOR YOUR SEARCH SCREEN 👇
      TextField(
        controller: locationController,
        readOnly: true, // Prevents keyboard, makes it behave like a button
        onTap: () async {
          // Open your custom LocationSearchScreen
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const LocationSearchScreen()),
          );

          // If the user selected a place and backed out
          if (result != null && result is Map<String, dynamic>) {
            setState(() {
              locationController.text = result["name"] ?? "";
              userLat = result["lat"];
              userLng = result["lng"];
            });
          }
        },
        decoration: InputDecoration(
          hintText: "Tap to search places",
          prefixIcon: const Icon(Icons.location_on_outlined, color: Color(0xFF0D47A1)),
          suffixIcon: locationController.text.isNotEmpty 
              ? const Icon(Icons.check_circle, color: Colors.green) 
              : null,
          filled: true, 
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12), 
            borderSide: BorderSide.none
          ),
        ),
      ),
      
      const SizedBox(height: 30),
      
      // Radius Selection
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "Preferred Play Radius", 
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
          ),
          Text(
            "${radius.toInt()} km", 
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: darkBlue)
          ),
        ],
      ),
      const SizedBox(height: 10),
      Slider(
        value: radius,
        min: 1,
        max: 50,
        divisions: 49,
        activeColor: darkBlue,
        label: "${radius.toInt()} km",
        onChanged: (val) => setState(() => radius = val),
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
      
      const SizedBox(height: 20),
      if (userLat != null)
        Center(
          child: Text(
            "Coordinates Captured: ${userLat!.toStringAsFixed(3)}, ${userLng!.toStringAsFixed(3)}",
            style: const TextStyle(color: Colors.green, fontSize: 12),
          ),
        ),
    ],
  );
}

  // ================= STEP 4: AVAILABILITY =================
  Widget buildStep4() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Availability", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text("When are you usually free for a game?", style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),

          const Text("Days", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10, runSpacing: 10,
            children: daysOptions.map((day) {
              final isSelected = selectedDays.contains(day);
              return FilterChip(
                label: Text(day, style: TextStyle(color: isSelected ? Colors.white : Colors.black87)),
                selected: isSelected,
                selectedColor: darkBlue,
                backgroundColor: Colors.grey.shade100,
                onSelected: (selected) {
                  setState(() {
                    selected ? selectedDays.add(day) : selectedDays.remove(day);
                  });
                },
              );
            }).toList(),
          ),

          const SizedBox(height: 30),

          const Text("Time of Day", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10, runSpacing: 10,
            children: timeOptions.map((time) {
              final isSelected = selectedTimes.contains(time);
              return FilterChip(
                label: Text(time, style: TextStyle(color: isSelected ? Colors.white : Colors.black87)),
                selected: isSelected,
                selectedColor: darkBlue,
                backgroundColor: Colors.grey.shade100,
                onSelected: (selected) {
                  setState(() {
                    selected ? selectedTimes.add(time) : selectedTimes.remove(time);
                  });
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ================= BUILDER =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (step > 0)
            TextButton(
              onPressed: saveProfile,
              child: const Text("Skip to Finish", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            )
        ],
      ),
      // Use ModalProgressHUD or Stack to show a loading spinner over the whole screen during upload
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  
                  // Progress indicator
                  Row(
                    children: List.generate(4, (index) {
                      return Expanded(
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          height: 6,
                          decoration: BoxDecoration(
                            color: index <= step ? darkBlue : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 30),

                  // Dynamic Step Content
                  Expanded(
                    child: step == 0 
                        ? buildStep1() 
                        : step == 1 
                            ? buildStep2() 
                            : step == 2 
                                ? buildStep3() 
                                : buildStep4(),
                  ),

                  const SizedBox(height: 20),

                  // Bottom Navigation Buttons
                  Row(
                    children: [
                      if (step > 0)
                        Expanded(
                          flex: 1,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () => setState(() => step--),
                            child: const Text("Back"),
                          ),
                        ),
                      
                      if (step > 0) const SizedBox(width: 12),

                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: darkBlue,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          onPressed: isUploading ? null : () { // Disable button while uploading
                            // MANDATORY STEP VALIDATION
                            if (step == 0) {
                              if (nameController.text.trim().isEmpty || gender.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Please provide a Display Name and select a Gender to continue."))
                                );
                                return;
                              }
                            }

                            if (step < 3) {
                              setState(() => step++);
                            } else {
                              saveProfile();
                            }
                          },
                          child: isUploading 
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2,))
                              : Text(
                                  step == 3 ? "Complete Profile" : "Next", 
                                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)
                                ),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
            
            // 👇 NEW Full screen loading overlay for storage upload 👇
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
                        CircularProgressIndicator(color: darkBlue),
                        const SizedBox(height: 16),
                        const Text("Uploading Profile...", style: TextStyle(fontWeight: FontWeight.bold)),
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
}