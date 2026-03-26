import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart'; 
import '../../services/auth_service.dart'; 
import 'activitiy_details_screen.dart';
import './location_search_screen.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';

class ActivityListScreen extends StatefulWidget {
  final String sport;

  const ActivityListScreen({super.key, required this.sport});

  @override
  State<ActivityListScreen> createState() => _ActivityListScreenState();
}
  
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
    List<String> days = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"];
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

class _ActivityListScreenState extends State<ActivityListScreen> {
  DateTime _selectedDate = DateTime.now();
  
  // Filter States
  late String _selectedSport;
  String _sortBy = 'time'; 
  RangeValues _timeRange = const RangeValues(0, 24); 
  
  // Location & Map States
  String locationName = "Fetching location...";
  double radiusKm = 10.0;
  double? userLat;
  double? userLng;
  bool _isMapView = false;
  final Color primaryColor = const Color(0xFF0C3169);

  // List of all available sports
  final List<Map<String, String>> allSports = [
    {"name": "Badminton", "image": "assets/badminton.png"},
    {"name": "Pickleball", "image": "assets/pickleball.png"},
    {"name": "Basketball", "image": "assets/basketball.png"},
    {"name": "Tennis", "image": "assets/tennis.png"},
    {"name": "Pilates", "image": "assets/pilates.png"},
    {"name": "Paintball", "image": "assets/paintball.png"},
    {"name": "Golf", "image": "assets/golf.png"},
    {"name": "Hiking", "image": "assets/hiking.png"},
    {"name": "Football", "image": "assets/football.png"},
    {"name": "Futsal", "image": "assets/futsal.png"},
    {"name": "Bowling", "image": "assets/bowling.png"},
    {"name": "Bouldering", "image": "assets/bouldering.png"},
    {"name": "Dodgeball", "image": "assets/dodgeball.png"}, 
    {"name": "Running", "image": "assets/running.png"},
    {"name": "Squash", "image": "assets/squash.png"},
    {"name": "Table Tennis", "image": "assets/tabletennis.png"},
    {"name": "Frisbee", "image": "assets/frisbee.png"},
    {"name": "Volleyball", "image": "assets/volleyball.png"},
  ];

  @override
  void initState() {
    super.initState();
    _selectedSport = widget.sport; 
    loadUserData();
  }

  Future<BitmapDescriptor> _getCustomMarker(int count) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    
    // Dimensions for the pin
    const double width = 120;
    const double height = 160;
    const double radius = width / 2;

    // 1. Draw Outer White Pin (Teardrop shape)
    Path outerPath = Path();
    outerPath.moveTo(radius, height); // Bottom point
    outerPath.quadraticBezierTo(0, height * 0.65, 0, radius); // Left curve
    outerPath.arcToPoint(const Offset(width, radius), radius: const Radius.circular(radius), clockwise: true); // Top semicircle
    outerPath.quadraticBezierTo(width, height * 0.65, radius, height); // Right curve
    outerPath.close();

    final Paint borderPaint = Paint()..color = Colors.white..style = PaintingStyle.fill;
    canvas.drawShadow(outerPath, Colors.black, 6.0, false); // Adds a nice drop shadow
    canvas.drawPath(outerPath, borderPaint);

    // 2. Draw Inner Blue Pin
    const double padding = 8.0;
    const double innerWidth = width - (padding * 2);
    const double innerRadius = innerWidth / 2;
    
    Path innerPath = Path();
    innerPath.moveTo(radius, height - padding - 4); // Inner bottom point
    innerPath.quadraticBezierTo(padding, height * 0.65, padding, radius);
    innerPath.arcToPoint(const Offset(width - padding, radius), radius: const Radius.circular(innerRadius), clockwise: true);
    innerPath.quadraticBezierTo(width - padding, height * 0.65, radius, height - padding - 4);
    innerPath.close();

    final Paint bgPaint = Paint()..color = primaryColor..style = PaintingStyle.fill;
    canvas.drawPath(innerPath, bgPaint);

    // 3. Draw the Number Text inside the circular top half
    TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: count.toString(),
        style: const TextStyle(fontSize: 48, color: Colors.white, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    
    // Center the text mathematically in the top circle part of the pin
    textPainter.paint(
      canvas,
      Offset((width - textPainter.width) / 2, radius - (textPainter.height / 2) ), 
    );

    // Convert Canvas to Image
    final ui.Image img = await pictureRecorder.endRecording().toImage(width.toInt(), height.toInt());
    final ByteData? data = await img.toByteData(format: ui.ImageByteFormat.png);
    
    return BitmapDescriptor.fromBytes(data!.buffer.asUint8List());
  }

  Future<Set<Marker>> _buildMapMarkers(List<QueryDocumentSnapshot> docs) async {
    Map<String, List<QueryDocumentSnapshot>> groupedActivities = {};
    
    // 1. Group by location
    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      if (data['coordinates'] == null) continue; 
      GeoPoint geoPoint = data['coordinates'] as GeoPoint;
      String locKey = "${geoPoint.latitude}_${geoPoint.longitude}";
      
      if (!groupedActivities.containsKey(locKey)) groupedActivities[locKey] = [];
      groupedActivities[locKey]!.add(doc);
    }

    Set<Marker> markers = {};
    
    // 2. Create Custom Markers
    for (var entry in groupedActivities.entries) {
      List<QueryDocumentSnapshot> games = entry.value;
      final firstGame = games.first.data() as Map<String, dynamic>;
      GeoPoint geoPoint = firstGame['coordinates'] as GeoPoint;
      int gameCount = games.length;

      // 🎨 Get our custom drawn marker with the number!
      BitmapDescriptor customIcon = await _getCustomMarker(gameCount);

      markers.add(Marker(
        markerId: MarkerId(entry.key),
        position: LatLng(geoPoint.latitude, geoPoint.longitude),
        icon: customIcon,
        anchor: const Offset(0.5, 1.0),
        infoWindow: InfoWindow(
          title: gameCount > 1 ? "$gameCount Games Here" : firstGame['name'] ?? 'Game',
          snippet: gameCount > 1 
              ? "Tap here to view all games" 
              : "${firstGame['sport']} • ${formatTime(firstGame['startTime'] as Timestamp?)}",
          onTap: () {
            if (gameCount == 1) {
              Navigator.push(context, MaterialPageRoute(builder: (_) => ActivityDetailsScreen(activityId: games.first.id)));
            } else {
              _showGamesAtLocationSheet(context, games);
            }
          }
        ),
      ));
    }
    return markers;
  }

  Future<void> loadUserData() async {
    final currentUserId = AuthService().getCurrentUser()?.uid;
    if (currentUserId == null) return;

    final userDoc = await FirebaseFirestore.instance.collection("users").doc(currentUserId).get();

    if (mounted) {
      setState(() {
        locationName = userDoc.data()?["location"] ?? "Set your location";
        radiusKm = (userDoc.data()?["radiusKm"] ?? 10.0).toDouble();
        userLat = userDoc.data()?["lat"];
        userLng = userDoc.data()?["lng"];
      });
    }
  }

  // --- MAP MULTI-GAME BOTTOM SHEET ---
  void _showGamesAtLocationSheet(BuildContext context, List<QueryDocumentSnapshot> games) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, 
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.6, 
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 16),
                  width: 40, height: 5,
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  "${games.length} Games at this location", 
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: games.length,
                  itemBuilder: (context, index) {
                    return activityCard(games[index]);
                  }
                ),
              ),
            ],
          ),
        );
      }
    );
  }

  // --- LOCATION FILTER BOTTOM SHEET ---
  void _showLocationBottomSheet(BuildContext context) {
    String tempLocName = locationName;
    double tempRadius = radiusKm;
    double? tempLat = userLat;
    double? tempLng = userLng;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, 
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                top: 24, left: 20, right: 20
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Location & Radius", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  const Text("Area / City", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 8),
                  TextField(
                    readOnly: true, 
                    controller: TextEditingController(text: tempLocName),
                    onTap: () async {
                       final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => const LocationSearchScreen()));
                       if (result != null && result is Map<String, dynamic>) {
                         setModalState(() {
                           tempLocName = result["name"] ?? "";
                           tempLat = result["lat"];
                           tempLng = result["lng"];
                         });
                       }
                    },
                    decoration: InputDecoration(
                      hintText: "Tap to search places",
                      prefixIcon: Icon(Icons.search, color: primaryColor),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Distance Radius", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text("${tempRadius.toInt()} km", style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Slider(
                    value: tempRadius, min: 1, max: 50, divisions: 49, activeColor: primaryColor,
                    onChanged: (val) => setModalState(() => tempRadius = val)
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity, height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      onPressed: () async {
                        final currentUserId = AuthService().getCurrentUser()?.uid;
                        if (currentUserId != null) {
                          await FirebaseFirestore.instance.collection("users").doc(currentUserId).update({
                            "location": tempLocName, "radiusKm": tempRadius, "lat": tempLat, "lng": tempLng,
                          });
                        }
                        setState(() {
                          locationName = tempLocName; radiusKm = tempRadius; userLat = tempLat; userLng = tempLng;
                        });
                        if (context.mounted) Navigator.pop(context);
                      },
                      child: const Text("Apply", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    )
                  )
                ]
              )
            );
          }
        );
      }
    );
  }

  Future<void> joinActivity(String docId) async {
    final currentUserId = AuthService().getCurrentUser()?.uid;
    if (currentUserId == null) return;

    try {
      await FirebaseFirestore.instance.collection("activities").doc(docId).update({
        "participants": FieldValue.arrayUnion([currentUserId])
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Successfully joined the game!")));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error joining game: $e")));
    }
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year && date1.month == date2.month && date1.day == date2.day;
  }

  String _formatDayName(DateTime date) {
    if (_isSameDay(date, DateTime.now())) return "Today";
    if (_isSameDay(date, DateTime.now().add(const Duration(days: 1)))) return "Tomorrow";
    List<String> days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
    return days[date.weekday - 1];
  }

  String _formatMonth(int month) {
    List<String> months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
    return months[month - 1];
  }

  String _formatHour(double value) {
    int hour = value.toInt();
    if (hour == 24) return "11:59 PM";
    if (hour == 0) return "12 AM";
    if (hour == 12) return "12 PM";
    return hour > 12 ? "${hour - 12} PM" : "$hour AM";
  }

  // --- OTHER MODAL SHEETS ---

  void _showSortByModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Sort By", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              ListTile(
                title: const Text("Time (Default)"),
                trailing: _sortBy == 'time' ? Icon(Icons.check, color: primaryColor) : null,
                onTap: () {
                  setState(() => _sortBy = 'time');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text("Distance"),
                trailing: _sortBy == 'distance' ? Icon(Icons.check, color: primaryColor) : null,
                onTap: () {
                  setState(() => _sortBy = 'distance');
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      }
    );
  }

  void _showTimeModal() {
    RangeValues tempRange = _timeRange; 

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Filter by Start Time", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_formatHour(tempRange.start), style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(_formatHour(tempRange.end), style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  RangeSlider(
                    values: tempRange, min: 0, max: 24, divisions: 24, activeColor: primaryColor,
                    onChanged: (values) => setModalState(() => tempRange = values),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                      onPressed: () {
                        setState(() => _timeRange = tempRange);
                        Navigator.pop(context);
                      },
                      child: const Text("Apply", style: TextStyle(color: Colors.white)),
                    ),
                  )
                ],
              ),
            );
          }
        );
      }
    );
  }

  void _showSportsModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, 
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.6, 
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Select Sport", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4, crossAxisSpacing: 10, mainAxisSpacing: 16, childAspectRatio: 0.75,
                  ),
                  itemCount: allSports.length + 1, 
                  itemBuilder: (context, index) {
                    final isAll = index == 0;
                    final sportName = isAll ? "All" : allSports[index - 1]["name"]!;
                    final sportImage = isAll ? "" : allSports[index - 1]["image"]!;
                    final isSelected = _selectedSport.toLowerCase() == sportName.toLowerCase();
                    
                    return GestureDetector(
                      onTap: () {
                        setState(() => _selectedSport = sportName);
                        Navigator.pop(context);
                      },
                      child: Column(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: isSelected ? Border.all(color: primaryColor, width: 3) : null,
                            ),
                            child: CircleAvatar(
                              radius: 30, backgroundColor: Colors.grey.shade100,
                              backgroundImage: isAll ? null : AssetImage(sportImage),
                              child: isAll ? Icon(Icons.apps, size: 28, color: primaryColor) : null,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            sportName.toUpperCase(),
                            style: TextStyle(
                              fontSize: 9, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? primaryColor : Colors.black,
                            ),
                            textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    DateTime startOfDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, _timeRange.start.toInt());
    DateTime endOfDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, _timeRange.end.toInt() == 24 ? 23 : _timeRange.end.toInt(), _timeRange.end.toInt() == 24 ? 59 : 0);

    DateTime today = DateTime.now();
    int daysInMonth = DateTime(today.year, today.month + 1, today.day).difference(today).inDays;
    
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: GestureDetector(
          onTap: () => _showLocationBottomSheet(context),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.location_on, color: primaryColor, size: 20),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  locationName, 
                  style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(Icons.keyboard_arrow_down, color: Colors.black, size: 18),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          // --- 1. FILTER BAR ---
          Container(
            height: 60, color: Colors.white, padding: const EdgeInsets.symmetric(vertical: 10),
            child: ListView(
              scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                // Map Button
                Container(
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    color: _isMapView ? primaryColor.withOpacity(0.1) : Colors.grey.shade200,
                    border: Border.all(color: _isMapView ? primaryColor : Colors.transparent),
                    borderRadius: BorderRadius.circular(20)
                  ),
                  child: IconButton(
                    icon: Icon(_isMapView ? Icons.format_list_bulleted : Icons.map_outlined, size: 20, color: _isMapView ? primaryColor : Colors.black87),
                    onPressed: () => setState(() => _isMapView = !_isMapView),
                  ),
                ),
                // Sort By Chip
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    backgroundColor: Colors.grey.shade100,
                    label: Row(
                      children: [
                        const Icon(Icons.sort, size: 16),
                        const SizedBox(width: 4),
                        Text(_sortBy == 'time' ? "Sort by" : "Distance"),
                      ],
                    ),
                    onPressed: _showSortByModal,
                  ),
                ),
                // Time Chip
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    backgroundColor: Colors.grey.shade100,
                    label: Row(
                      children: [
                        const Icon(Icons.access_time, size: 16),
                        const SizedBox(width: 4),
                        Text(_timeRange.start == 0 && _timeRange.end == 24 ? "Start Time" : "${_formatHour(_timeRange.start)} - ${_formatHour(_timeRange.end)}"),
                      ],
                    ),
                    onPressed: _showTimeModal,
                  ),
                ),
                // Sports Chip
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    backgroundColor: primaryColor.withOpacity(0.1), 
                    label: Row(
                      children: [
                        Icon(Icons.sports_tennis, size: 16, color: primaryColor),
                        const SizedBox(width: 4),
                        Text(_selectedSport, style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
                        Icon(Icons.keyboard_arrow_down, size: 16, color: primaryColor),
                      ],
                    ),
                    onPressed: _showSportsModal,
                  ),
                ),
              ],
            ),
          ),
          
          const Divider(height: 1),

          // --- 2. DATE FILTER ROW ---
          Container(
            height: 70, color: Colors.white, padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal, itemCount: daysInMonth, 
              itemBuilder: (context, index) {
                DateTime date = DateTime.now().add(Duration(days: index));
                bool isSelected = _isSameDay(date, _selectedDate);

                return GestureDetector(
                  onTap: () => setState(() => _selectedDate = date),
                  child: Container(
                    width: 70, margin: const EdgeInsets.only(left: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? primaryColor : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isSelected ? primaryColor : Colors.grey.shade300),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_formatDayName(date), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Colors.grey.shade600)),
                        const SizedBox(height: 4),
                        Text("${date.day} ${_formatMonth(date.month)}", style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : Colors.black)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 10),

          // --- 3. STREAM BUILDER ---
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: () {
                Query query = FirebaseFirestore.instance.collection("activities");
                if (_selectedSport != "All") query = query.where("sport", isEqualTo: _selectedSport);
                return query
                    .where("startTime", isGreaterThanOrEqualTo: startOfDay)
                    .where("startTime", isLessThanOrEqualTo: endOfDay)
                    .orderBy("startTime")
                    .snapshots();
              }(), 
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text("No games found for this time.", style: TextStyle(color: Colors.grey.shade600)));
                }

                // --- MAP OR LIST ---
                if (_isMapView) {
                  // --- GOOGLE MAPS VIEW WITH CUSTOM PINS ---
                  return FutureBuilder<Set<Marker>>(
                    // 👇 We pass the documents to the async function you added earlier
                    future: _buildMapMarkers(snapshot.data!.docs),
                    builder: (context, markerSnapshot) {
                      
                      // Wait for the custom pins to finish drawing
                      if (markerSnapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(color: Color(0xFF0C3169)));
                      }

                      // Draw the map with the newly created custom pins!
                      return GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: LatLng(userLat ?? 3.1390, userLng ?? 101.6869), 
                          zoom: 12.0,
                        ),
                        myLocationEnabled: true,
                        myLocationButtonEnabled: true,
                        markers: markerSnapshot.data ?? {}, // 👈 Here are your custom markers!
                      );
                    }
                  );
                } else {
                  // --- TRADITIONAL LIST VIEW ---
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      return activityCard(snapshot.data!.docs[index]);
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- REUSABLE ACTIVITY CARD ---
  Widget activityCard(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    final sport = data["sport"] ?? "";
    final name = data["name"] ?? "Game";
    final location = data["location"] ?? "";
    final gameType = data["gameType"] ?? "";

    final max = data["maxPeople"] ?? 0;
    final price = data["price"] ?? 0;

    final start = data["startTime"] as Timestamp?;
    final end = data["endTime"] as Timestamp?;

    final currentUserId = AuthService().getCurrentUser()?.uid;
    final createdBy = data["createdBy"] ?? "";
    final participants = List<String>.from(data["participants"] ?? []);
    
    final isCreator = currentUserId == createdBy;
    final hasJoined = participants.contains(currentUserId);
    final isFull = participants.length >= max;
    final reservedSpots = List<String>.from(data["reservedSpots"] ?? []);
    final totalJoined = participants.length + reservedSpots.length; 

    String detailsText = "$totalJoined/$max players • $gameType";
    if (price > 0) {
      detailsText += " • RM $price";
    }

    int maxDisplay = 7; 
    int filledCircles = totalJoined > maxDisplay ? maxDisplay : totalJoined;
    int emptyCircles = max > maxDisplay ? maxDisplay - filledCircles : max - filledCircles;
    if (emptyCircles < 0) emptyCircles = 0; 

    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => ActivityDetailsScreen(activityId: doc.id)));
      },
      child: Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
            child: Text(sport.toUpperCase(), style: TextStyle(color: primaryColor, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
          ),
          const SizedBox(height: 12),

          Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 10),

          FutureBuilder<List<DocumentSnapshot>>(
            future: Future.wait(participants.take(maxDisplay).map((uid) => FirebaseFirestore.instance.collection("users").doc(uid).get())),
            builder: (context, snapshot) {
              List<Widget> avatarWidgets = [];

              if (snapshot.connectionState == ConnectionState.waiting) {
                for (int i = 0; i < (participants.length > maxDisplay ? maxDisplay : participants.length); i++) {
                  avatarWidgets.add(Container(width: 40, height: 40, margin: const EdgeInsets.only(right: 6), decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.grey.shade200, border: Border.all(color: Colors.white, width: 2))));
                }
              } else if (snapshot.hasData) {
                for (int i = 0; i < snapshot.data!.length; i++) {
                  var userDoc = snapshot.data![i].data() as Map<String, dynamic>?;
                  String profilePicUrl = userDoc?["profilePicUrl"] ?? "";
                  avatarWidgets.add(
                    Container(
                      margin: const EdgeInsets.only(right: 6), 
                      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)]),
                      child: CircleAvatar(
                        radius: 18, backgroundColor: primaryColor.withOpacity(0.1),
                        backgroundImage: profilePicUrl.isNotEmpty ? NetworkImage(profilePicUrl) : null,
                        child: profilePicUrl.isEmpty ? Icon(Icons.person, size: 20, color: primaryColor) : null, 
                      ),
                    ),
                  );
                }
              }

              int spotsLeftToDisplay = maxDisplay - avatarWidgets.length;
              for (int i = 0; i < reservedSpots.length && i < spotsLeftToDisplay; i++) {
                avatarWidgets.add(
                  Container(
                    margin: const EdgeInsets.only(right: 6), 
                    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)]),
                    child: CircleAvatar(radius: 18, backgroundColor: primaryColor.withOpacity(0.1), child: Icon(Icons.person, size: 20, color: primaryColor)),
                  ),
                );
              }

              for (int i = 0; i < emptyCircles; i++) {
                avatarWidgets.add(
                  Container(
                    width: 40, height: 40, margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.grey.shade50, border: Border.all(color: Colors.grey.shade300, width: 1.5, strokeAlign: BorderSide.strokeAlignInside)),
                  ),
                );
              }
              return Row(children: avatarWidgets);
            },
          ),
          
          const SizedBox(height: 20),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(padding: const EdgeInsets.only(top: 2), child: Icon(Icons.people_outline, size: 16, color: primaryColor)),
              const SizedBox(width: 6),
              Expanded(child: Text(detailsText, style: TextStyle(fontSize: 13, color: Colors.grey.shade700, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis)),
            ],
          ),
            
          const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F0))),

          Row(
            children: [
              Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)), child: Icon(Icons.calendar_today, size: 14, color: primaryColor)),
              const SizedBox(width: 8),
              Text(formatDate(start), style: const TextStyle(fontSize: 12,  color: Colors.black87)),
            ],
          ),
          const SizedBox(height: 5),

          Row(
            children: [
              Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)), child: Icon(Icons.access_time, size: 14, color: primaryColor)),
              const SizedBox(width: 8),
              Text("${formatTime(start)} - ${formatTime(end)}  •  ${formatDuration(start, end)}", style: const TextStyle(fontSize: 12, color: Colors.black87)),
            ],
          ),
          const SizedBox(height: 5),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)), child: Icon(Icons.location_on_outlined, size: 14, color: primaryColor)),
              const SizedBox(width: 8),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(location, style: const TextStyle(fontSize: 12, color: Colors.black87, height: 1.2), maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          if (!isCreator)
            SizedBox(
              width: double.infinity, height: 48,
              child: ElevatedButton(
                onPressed: (hasJoined || isFull) ? null : () => joinActivity(doc.id),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  disabledBackgroundColor: Colors.grey.shade300,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                child: Text(
                  hasJoined ? "Joined" : isFull ? "Game Full" : "Join Game",
                  style: TextStyle(color: (hasJoined || isFull) ? Colors.grey.shade600 : Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
            
          if (isCreator)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text("You are the host", style: TextStyle(color: Colors.grey.shade500, fontSize: 14, fontStyle: FontStyle.italic)),
              ),
            ),
        ],
      ),
    ));
  }
}