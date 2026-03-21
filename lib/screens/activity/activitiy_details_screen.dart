import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart'; // Add this import
import '../../services/auth_service.dart';
import 'activity_edit_screen.dart';

class ActivityDetailsScreen extends StatefulWidget {
  final String activityId;

  const ActivityDetailsScreen({super.key, required this.activityId});

  @override
  State<ActivityDetailsScreen> createState() => _ActivityDetailsScreenState();
}

class _ActivityDetailsScreenState extends State<ActivityDetailsScreen> {
  final Color primaryColor = const Color(0xFF0C3169);
  
  // Controller for the Google Map
  // ignore: unused_field
  GoogleMapController? _mapController;

  // --- UI HELPER FOR AVATAR ITEMS ---
  Widget _buildAvatarColumn({
    required String name, 
    required String imageUrl, 
    required Color primaryColor,
    bool isHost = false, 
    bool isReserved = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 60, // Fixed width prevents messy wrapping
        child: Column(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: isReserved ? Color(0xFF0C3169).withOpacity(0.1) : primaryColor.withOpacity(0.1),
              backgroundImage: imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
              child: imageUrl.isEmpty 
                  ? Icon(isReserved ? Icons.person: Icons.person, 
                         color: isReserved ? Color(0xFF0C3169) : primaryColor, size: 28) 
                  : null,
            ),
            const SizedBox(height: 6),
            Text(
              name, 
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
              maxLines: 1, 
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            if (isHost)
              Text("Host", style: TextStyle(fontSize: 10, color: primaryColor, fontWeight: FontWeight.bold)),
            if (isReserved && onTap != null) // Show 'remove' hint for host
              const Text("Remove", style: TextStyle(fontSize: 10, color: Colors.red)),
          ],
        ),
      ),
    );
  }

  // --- HOST ACTIONS ---
  void _showAddPlayerOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text("Manage Empty Spot", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              ListTile(
                leading: const Icon(Icons.person_add_alt_1),
                title: const Text("Reserve spot for a friend (Enter name)"),
                onTap: () {
                  Navigator.pop(context);
                  _showReserveSpotDialog(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.share),
                title: const Text("Invite players via app"),
                subtitle: const Text("(Coming soon)"),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Invite feature coming soon!")));
                },
              ),
            ],
          ),
        );
      }
    );
  }

  void _showReserveSpotDialog(BuildContext context) {
    final TextEditingController nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Reserve Spot"),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(hintText: "Friend's name (e.g. John)"),
            textCapitalization: TextCapitalization.words,
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
              onPressed: () async {
                if (nameController.text.trim().isEmpty) return;
                
                // Safely save the name to a dedicated array in Firestore
                await FirebaseFirestore.instance.collection("activities").doc(widget.activityId).update({
                  "reservedSpots": FieldValue.arrayUnion([nameController.text.trim()])
                });
                
                if (context.mounted) Navigator.pop(context);
              }, 
              child: const Text("Reserve", style: TextStyle(color: Colors.white))
            ),
          ],
        );
      }
    );
  }

  void _removeReservedSpot(String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Remove Reservation"),
        content: Text("Remove '$name' from the game?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              // Safely remove the name from Firestore
              await FirebaseFirestore.instance.collection("activities").doc(widget.activityId).update({
                "reservedSpots": FieldValue.arrayRemove([name])
              });
              if (context.mounted) Navigator.pop(context);
            }, 
            child: const Text("Remove", style: TextStyle(color: Colors.red))
          ),
        ],
      )
    );
  }
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
      List<String> days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
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
    if (hours > 0 && minutes > 0) return "${hours}h ${minutes}m";
    if (hours > 0) return "$hours hr${hours > 1 ? 's' : ''}";
    return "$minutes mins";
  }

  // --- GOOGLE MAPS LAUNCHER LOGIC (Native App) ---
  Future<void> _openMapDialog(BuildContext context, String location) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Open Google Maps?", style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text("Do you want to get directions to '$location'? This will open your maps app."),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              final String encodedLocation = Uri.encodeComponent(location);
              final Uri googleMapsUrl = Uri.parse("https://www.google.com/maps/search/?api=1&query=$encodedLocation");
              if (await canLaunchUrl(googleMapsUrl)) {
                await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Could not open Google Maps.")),
                  );
                }
              }
            },
            child: const Text("Open Maps", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // --- JOIN LOGIC ---
  Future<void> joinActivity() async {
    final currentUserId = AuthService().getCurrentUser()?.uid;
    if (currentUserId == null) return;

    try {
      await FirebaseFirestore.instance
          .collection("activities")
          .doc(widget.activityId)
          .update({
        "participants": FieldValue.arrayUnion([currentUserId])
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Successfully joined the game!")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error joining: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = AuthService().getCurrentUser()?.uid;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection("activities").doc(widget.activityId).snapshots(),
      builder: (context, snapshot) {
        
        // Loading State
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(backgroundColor: Colors.white, elevation: 0),
            body: Center(child: CircularProgressIndicator(color: primaryColor)),
          );
        }

        // Error / Deleted State
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(backgroundColor: Colors.white, elevation: 0),
            body: const Center(child: Text("Activity not found or deleted.")),
          );
        }

        // Data Loaded Successfully
        final data = snapshot.data!.data() as Map<String, dynamic>;

        final sport = data["sport"] ?? "Sport";
        final name = data["name"] ?? "Game Name";
        final location = data["location"] ?? "No Location Provided";
        
        // 👇 Grab the coordinates field 👇
        final GeoPoint? coords = data["coordinates"] as GeoPoint?;

        final description = data["description"] ?? "No description provided for this game.";
        final gameType = data["gameType"] ?? "Casual";
        final max = data["maxPeople"] ?? 0;
        final price = data["price"] ?? 0;
        final start = data["startTime"] as Timestamp?;
        final end = data["endTime"] as Timestamp?;
        
        final isCourtBooked = data["isCourtBooked"] ?? data["courtBooked"] ?? false;
        final courtDetails = data["courtDetails"] ?? data["courtNumber"] ?? data["court"] ?? "";

        final createdBy = data["createdBy"] ?? "";
        final participants = List<String>.from(data["participants"] ?? []);
        final reservedSpots = List<String>.from(data["reservedSpots"] ?? []);

        final totalJoined = participants.length + reservedSpots.length; 
        final isFull = totalJoined >= max; 

        final isCreator = currentUserId == createdBy;
        final hasJoined = participants.contains(currentUserId);

        // Converter GeoPoint to LatLng for Google Maps
        LatLng activityLatLng = const LatLng(3.1390, 101.6869); // Default: KL
        if (coords != null) {
          activityLatLng = LatLng(coords.latitude, coords.longitude);
        }

        return DefaultTabController(
          length: 2,
          child: Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.black),
              
              title: Text(
                name,
                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
              ),

              actions: [
                if (isCreator)
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ActivityEditScreen(
          activityId: widget.activityId, // The ID passed to the details screen
          sport: sport,                  // The sport name fetched from Firestore data
        ),
                          ),
                        );
                      } else if (value == 'delete') {
                        return; // Uses your existing delete logic
                      }
                    },
                    icon: const Icon(Icons.more_vert, color: Colors.black),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    itemBuilder: (BuildContext context) => [
                      const PopupMenuItem<String>(
                        value: 'edit',
                        child: ListTile(
                          leading: Icon(Icons.edit_outlined, color: Colors.black),
                          title: Text('Edit Game'),
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                        ),
                      ),
                      const PopupMenuItem<String>(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(Icons.delete_outline, color: Colors.red),
                          title: Text('Delete Game', style: TextStyle(color: Colors.red)),
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                        ),
                      ),
                    ],
                  ),
              ],
                          
              bottom: TabBar(
                labelColor: primaryColor,
                unselectedLabelColor: Colors.grey.shade500,
                indicatorColor: primaryColor,
                indicatorWeight: 3,
                tabs: const [
                  Tab(text: "Details"),
                  Tab(text: "Chat"),
                ],
              ),
            ),
            
            body: TabBarView(
              children: [
                
                // TAB 1: DETAILS
                Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            
                            /// --- GAME TYPE & SPORT ROW ---
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.sports_esports, size: 16, color: primaryColor),
                                    const SizedBox(width: 6),
                                    Text(
                                      gameType.toUpperCase(),
                                      style: TextStyle(color: primaryColor, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    sport.toUpperCase(),
                                    style: TextStyle(color: primaryColor, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            /// --- GAME NAME ---
                            Text(
                              name,
                              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black87, height: 1.2),
                            ),
                            const SizedBox(height: 24),

                            /// --- INFO BOXES ---
                            _buildInfoRow(Icons.calendar_today, "Date", formatDate(start)),
                            const SizedBox(height: 16),
                            _buildInfoRow(Icons.access_time, "Time", "${formatTime(start)} - ${formatTime(end)} (${formatDuration(start, end)})"),
                            const SizedBox(height: 16),
                            _buildInfoRow(Icons.location_on_outlined, "Location", location),
                            const SizedBox(height: 16),
                            
                            // --- 👇 NEW DYNAMIC MAP UI SNIPPET 👇 ---
                            if (coords != null) ...[
                              _buildDynamicMap(activityLatLng, location),
                              const SizedBox(height: 16),
                            ],

                            // --- COURT BOOKED DISPLAY ---
                            if (isCourtBooked && courtDetails.toString().trim().isNotEmpty) ...[
                              _buildInfoRow(Icons.check_circle_outline, "Court Booked", courtDetails.toString()),
                              const SizedBox(height: 16),
                            ],

                            // --- PRICE DISPLAY ---
                            if (price > 0) _buildInfoRow(Icons.attach_money, "Price", "RM $price / pax"),
                            
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F0)),
                            ),

                            /// --- DESCRIPTION ---
                            const Text("About this game", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 10),
                            Text(
                              description.isEmpty ? "No description provided." : description,
                              style: TextStyle(fontSize: 14, color: Colors.grey.shade700, height: 1.5),
                            ),
                            
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F0)),
                            ),

                            /// --- PARTICIPANTS ---
                            Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Participants", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              Text("$totalJoined/$max Joined", style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),                            ],
                          ),
                          const SizedBox(height: 16),
                                                      
                            FutureBuilder<List<DocumentSnapshot>>(
                            future: Future.wait(
                              participants.map((uid) => FirebaseFirestore.instance.collection("users").doc(uid).get())
                            ),
                            builder: (context, userSnapshot) {
                              if (userSnapshot.connectionState == ConnectionState.waiting) {
                                return const Center(child: CircularProgressIndicator());
                              }

                              // Prepare lists for rendering
                              List<Widget> avatarWidgets = [];

                              // 1. ADD ACTUAL USERS (from Firestore)
                              if (userSnapshot.hasData && userSnapshot.data!.isNotEmpty) {
                                for (int i = 0; i < userSnapshot.data!.length; i++) {
                                  var userDoc = userSnapshot.data![i].data() as Map<String, dynamic>?;
                                  String pName = userDoc?["name"] ?? "Player";
                                  String pPic = userDoc?["profilePicUrl"] ?? "";
                                  bool isHost = participants[i] == createdBy;

                                  avatarWidgets.add(_buildAvatarColumn(
                                    name: pName,
                                    imageUrl: pPic,
                                    isHost: isHost,
                                    primaryColor: primaryColor,
                                  ));
                                }
                              }

                              // 2. ADD RESERVED SPOTS (Manually added by host)
                              List<String> reservedSpots = List<String>.from(data["reservedSpots"] ?? []);
                              for (String reservedName in reservedSpots) {
                                avatarWidgets.add(_buildAvatarColumn(
                                  name: reservedName,
                                  imageUrl: "", 
                                  isReserved: true,
                                  primaryColor: primaryColor,
                                  onTap: isCreator ? () => _removeReservedSpot(reservedName) : null,
                                ));
                              }

                              // 3. CALCULATE EMPTY SPOTS
                              int totalJoined = participants.length + reservedSpots.length;
                              int emptySpots = max - totalJoined;

                              // 4. ADD EMPTY/ADD SPOTS
                              for (int i = 0; i < emptySpots; i++) {
                                avatarWidgets.add(
                                  GestureDetector(
                                    onTap: isCreator ? () => _showAddPlayerOptions(context) : null,
                                    child: Column(
                                      children: [
                                        CircleAvatar(
                                          radius: 28,
                                          backgroundColor: Colors.grey.shade100,
                                          child: Icon(
                                            isCreator ? Icons.add : Icons.person_outline, 
                                            color: isCreator ? primaryColor : Colors.grey.shade400,
                                            size: 28,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          isCreator ? "Add" : "Empty", 
                                          style: TextStyle(
                                            fontSize: 12, 
                                            color: isCreator ? primaryColor : Colors.grey,
                                            fontWeight: isCreator ? FontWeight.bold : FontWeight.normal
                                          )
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }

                              // Render as a grid/wrap
                              return Wrap(
                                spacing: 16, // Horizontal gap
                                runSpacing: 16, // Vertical gap between rows
                                alignment: WrapAlignment.start,
                                children: avatarWidgets,
                              );
                            },
                          ),
                          const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),

                    /// --- BOTTOM ACTION BAR (ONLY ON DETAILS TAB) ---
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4))],
                      ),
                      child: SafeArea(
                        child: isCreator
                            ? Center(
                                child: Text(
                                  "You are the host of this game",
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14, fontStyle: FontStyle.italic),
                                ),
                              )
                            : SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: (hasJoined || isFull) ? null : joinActivity,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryColor,
                                    disabledBackgroundColor: Colors.grey.shade300,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    elevation: 0,
                                  ),
                                  child: Text(
                                    hasJoined ? "Joined" : isFull ? "Game Full" : "Join Game",
                                    style: TextStyle(
                                      color: (hasJoined || isFull) ? Colors.grey.shade600 : Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                      ),
                    ),
                  ],
                ),

                // TAB 2: CHAT (PLACEHOLDER)
                Container(
                  color: Colors.grey.shade50,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          "Chat feature coming soon!",
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ),
                
              ],
            ),
          ),
        );
      }
    );
  }

  // --- UI HELPER: INFO ROW ---
  Widget _buildInfoRow(IconData icon, String title, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 20, color: primaryColor),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87, height: 1.3)),
            ],
          ),
        ),
      ],
    );
  }

  // --- 👇 NEW UI HELPER: DYNAMIC GOOGLE MAP 👇 ---
  Widget _buildDynamicMap(LatLng position, String location) {
    // Defines the camera view (center and zoom level)
    final CameraPosition activityCamera = CameraPosition(
      target: position,
      zoom: 15.0, // Standard street-level zoom
    );

    // Defines the red marker pin on the map
    Set<Marker> markers = {
      Marker(
        markerId: const MarkerId("activity_loc"),
        position: position,
        infoWindow: InfoWindow(title: location),
        icon: BitmapDescriptor.defaultMarker, // Standard red pin
      ),
    };

    return Container(
      height: 180, // Increased height for better visibility
      width: double.infinity,
      margin: const EdgeInsets.only(left: 48), // Align perfectly with InfoRow text
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      // ClipRRect ensures the map corners are rounded to match the container
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // THE ACTUAL INTERACTIVE MAP WIDGET
            GoogleMap(
              mapType: MapType.normal,
              initialCameraPosition: activityCamera,
              markers: markers,
              myLocationButtonEnabled: false, // Keep UI clean
              zoomControlsEnabled: false, // Keep UI clean
              onMapCreated: (GoogleMapController controller) {
                _mapController = controller;
              },
            ),
            
            // "Get Directions" Overlay Button (Clicking this still opens native maps)
            Positioned(
              bottom: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => _openMapDialog(context, location),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.directions, size: 16, color: primaryColor),
                      const SizedBox(width: 6),
                      Text(
                        "Directions", 
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryColor)
                      ),
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