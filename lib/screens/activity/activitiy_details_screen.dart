import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart'; // Add this import
import '../../services/auth_service.dart';

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

        final isCreator = currentUserId == createdBy;
        final hasJoined = participants.contains(currentUserId);
        final isFull = participants.length >= max;

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
                                Text("${participants.length}/$max Joined", style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
                              ],
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
                                if (!userSnapshot.hasData || userSnapshot.data!.isEmpty) {
                                  return const Text("No one has joined yet.");
                                }

                                return ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(), 
                                  itemCount: userSnapshot.data!.length,
                                  itemBuilder: (context, index) {
                                    var userDoc = userSnapshot.data![index].data() as Map<String, dynamic>?;
                                    String pName = userDoc?["name"] ?? "Player";
                                    String pPic = userDoc?["profilePicUrl"] ?? "";
                                    bool isHost = participants[index] == createdBy;

                                    return ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      leading: CircleAvatar(
                                        radius: 22,
                                        backgroundColor: primaryColor.withOpacity(0.1),
                                        backgroundImage: pPic.isNotEmpty ? NetworkImage(pPic) : null,
                                        child: pPic.isEmpty ? Icon(Icons.person, color: primaryColor) : null,
                                      ),
                                      title: Text(pName, style: const TextStyle(fontWeight: FontWeight.w600)),
                                      subtitle: isHost ? Text("Host", style: TextStyle(color: primaryColor, fontSize: 12)) : null,
                                    );
                                  },
                                );
                              }
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