import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart'; 

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
  
  // Strip out the hours/minutes to accurately compare just the calendar days
  final today = DateTime(now.year, now.month, now.day);
  final tomorrow = today.add(const Duration(days: 1));
  final targetDate = DateTime(date.year, date.month, date.day);
  
  String dayName;
  
  if (targetDate == today) {
    dayName = "Today";
  } else if (targetDate == tomorrow) {
    dayName = "Tomorrow";
  } else {
    // If it's not today or tomorrow, get the full day name
    List<String> days = [
      "Monday", "Tuesday", "Wednesday", "Thursday", 
      "Friday", "Saturday", "Sunday"
    ];
    dayName = days[date.weekday - 1];
  }

  // Returns formats like: "Today, 19/3/2026" or "Monday, 23/3/2026"
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
  
  if (hours > 0 && minutes > 0) {
    return "${hours}h ${minutes}m";
  } else if (hours > 0) {
    return "$hours hr${hours > 1 ? 's' : ''}";
  } else {
    return "$minutes mins";
  }
}

class _ActivityListScreenState extends State<ActivityListScreen> {
  DateTime _selectedDate = DateTime.now();
  
  // Filter States
  late String _selectedSport;
  String _sortBy = 'time'; // 'time' or 'distance'
  RangeValues _timeRange = const RangeValues(0, 24); // 0 = 12 AM, 24 = 11:59 PM

  // List of all available sports and their asset paths
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
    {"name": "Dodgeball", "image": "assets/basketball.png"}, 
    {"name": "Running", "image": "assets/running.png"},
    {"name": "Squash", "image": "assets/squash.png"},
    {"name": "Table Tennis", "image": "assets/tabletennis.png"},
    {"name": "Frisbee", "image": "assets/frisbee.png"},
    {"name": "Volleyball", "image": "assets/volleyball.png"},
  ];

  @override
  void initState() {
    super.initState();
    _selectedSport = widget.sport; // Initialize with the sport passed from Home
  }

  Future<void> joinActivity(String docId) async {
    final currentUserId = AuthService().getCurrentUser()?.uid;
    if (currentUserId == null) return;

    try {
      await FirebaseFirestore.instance
          .collection("activities")
          .doc(docId)
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
        SnackBar(content: Text("Error joining game: $e")),
      );
    }
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
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

  // --- MODAL SHEETS ---

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
                trailing: _sortBy == 'time' ? const Icon(Icons.check, color: Color(0xFF0D47A1)) : null,
                onTap: () {
                  setState(() => _sortBy = 'time');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text("Distance"),
                trailing: _sortBy == 'distance' ? const Icon(Icons.check, color: Color(0xFF0D47A1)) : null,
                onTap: () {
                  setState(() => _sortBy = 'distance');
                  // Note: True distance sorting requires User's Location + GeoFlutterFire. 
                  // For now, it will just change the state.
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
    // Need a temporary state variable for the slider while modal is open
    RangeValues tempRange = _timeRange; 

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder( // StatefulBuilder allows the modal to update its own UI
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
                    values: tempRange,
                    min: 0,
                    max: 24,
                    divisions: 24,
                    activeColor: const Color(0xFF0D47A1),
                    onChanged: (values) {
                      setModalState(() {
                        tempRange = values;
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D47A1),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        setState(() {
                          _timeRange = tempRange; // Apply to main screen
                        });
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
      isScrollControlled: true, // Allows the modal to be taller
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.6, // Take 60% of screen height
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Select Sport", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: allSports.length,
                  itemBuilder: (context, index) {
                    final sport = allSports[index];
                    final isSelected = _selectedSport.toLowerCase() == sport["name"]!.toLowerCase();
                    
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedSport = sport["name"]!;
                        });
                        Navigator.pop(context);
                      },
                      child: Column(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: isSelected ? Border.all(color: const Color(0xFF0D47A1), width: 3) : null,
                            ),
                            child: CircleAvatar(
                              radius: 30,
                              backgroundColor: Colors.grey.shade200,
                              backgroundImage: AssetImage(sport["image"]!),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            sport["name"]!.toUpperCase(),
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? const Color(0xFF0D47A1) : Colors.black,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
    // Dynamically calculate Start and End time based on the slider state
    DateTime startOfDay = DateTime(
      _selectedDate.year, 
      _selectedDate.month, 
      _selectedDate.day, 
      _timeRange.start.toInt()
    );
    
    DateTime endOfDay = DateTime(
      _selectedDate.year, 
      _selectedDate.month, 
      _selectedDate.day, 
      _timeRange.end.toInt() == 24 ? 23 : _timeRange.end.toInt(), 
      _timeRange.end.toInt() == 24 ? 59 : 0
    );

    DateTime today = DateTime.now();
    int daysInMonth = DateTime(today.year, today.month + 1, today.day).difference(today).inDays;
    
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: Text(_selectedSport, style: const TextStyle(color: Colors.black)), // Updates when sport changes
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          
          // --- 1. FILTER BAR ---
          Container(
            height: 60,
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                
                // Map Button
                Container(
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(20)
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.map_outlined, size: 20),
                    onPressed: () {
                      // TODO: Implement Map View
                    },
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
                        Text(
                          _timeRange.start == 0 && _timeRange.end == 24 
                          ? "Start Time" 
                          : "${_formatHour(_timeRange.start)} - ${_formatHour(_timeRange.end)}"
                        ),
                      ],
                    ),
                    onPressed: _showTimeModal,
                  ),
                ),

                // Sports Chip
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    backgroundColor: const Color(0xFF0D47A1).withValues(alpha: 0.1), // Slightly highlight active sport
                    label: Row(
                      children: [
                        const Icon(Icons.sports_tennis, size: 16, color: Color(0xFF0D47A1)),
                        const SizedBox(width: 4),
                        Text(_selectedSport, style: const TextStyle(color: Color(0xFF0D47A1), fontWeight: FontWeight.bold)),
                        const Icon(Icons.keyboard_arrow_down, size: 16, color: Color(0xFF0D47A1)),
                      ],
                    ),
                    onPressed: _showSportsModal,
                  ),
                ),
              ],
            ),
          ),
          
          const Divider(height: 1),

          // --- 2. THE DATE FILTER ROW ---
          Container(
            height: 70,
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: daysInMonth, 
              itemBuilder: (context, index) {
                DateTime date = DateTime.now().add(Duration(days: index));
                bool isSelected = _isSameDay(date, _selectedDate);

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDate = date;
                    });
                  },
                  child: Container(
                    width: 70,
                    margin: const EdgeInsets.only(left: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF0D47A1) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF0D47A1) : Colors.grey.shade300,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _formatDayName(date),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${date.day} ${_formatMonth(date.month)}",
                          style: TextStyle(
                            fontSize: 12,
                            color: isSelected ? Colors.white : Colors.black,
                          ),
                        ),
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
              stream: FirebaseFirestore.instance
                  .collection("activities")
                  .where("sport", isEqualTo: _selectedSport) // Using the dynamic state now
                  .where("startTime", isGreaterThanOrEqualTo: startOfDay)
                  .where("startTime", isLessThanOrEqualTo: endOfDay)
                  .orderBy("startTime") 
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text("No $_selectedSport games found for this time.", style: const TextStyle(color: Colors.grey)),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var doc = snapshot.data!.docs[index];
                    return activityCard(doc);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

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

    // --- AUTH & PARTICIPANT LOGIC ---
    final currentUserId = AuthService().getCurrentUser()?.uid;
    final createdBy = data["createdBy"] ?? "";
    final participants = List<String>.from(data["participants"] ?? []);
    
    final isCreator = currentUserId == createdBy;
    final hasJoined = participants.contains(currentUserId);
    final isFull = participants.length >= max;

    // Dynamically build the details string (Players + Type + Price)
    String detailsText = "${participants.length}/$max players • $gameType";
    if (price > 0) {
      detailsText += " • RM $price";
    }

    // --- AVATAR LOGIC SETUP ---
    int maxDisplay = 7; // Maximum number of circles to draw before showing "+X"
    int currentCount = participants.length;
    
    int filledCircles = currentCount > maxDisplay ? maxDisplay : currentCount;
    int emptyCircles = max > maxDisplay ? maxDisplay - filledCircles : max - filledCircles;
    
    // Prevent negative empty circles if data is ever weird
    if (emptyCircles < 0) emptyCircles = 0; 

    return Container(
      width: double.infinity, // Set to fill screen width for vertical list
      margin: const EdgeInsets.only(bottom: 16), // Bottom margin for vertical scrolling
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// 🔵 SPORT TAG
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF0C3169).withOpacity(0.1), // Soft background
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              sport.toUpperCase(),
              style: const TextStyle(
                color: Color(0xFF0C3169), // Primary colored text
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 12),

          /// 🏸 GAME NAME
          Text(
            name,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),

          /// 👥 AVATARS ROW (FETCHES FROM FIRESTORE)
          FutureBuilder<List<DocumentSnapshot>>(
            future: Future.wait(
              participants.take(maxDisplay).map(
                (uid) => FirebaseFirestore.instance.collection("users").doc(uid).get()
              )
            ),
            builder: (context, snapshot) {
              List<Widget> avatarWidgets = [];

              // 1. Generate Filled Avatars (Loading State)
              if (snapshot.connectionState == ConnectionState.waiting) {
                for (int i = 0; i < filledCircles; i++) {
                  avatarWidgets.add(
                    Align(
                      widthFactor: 0.75,
                      child: Container(
                        width: 40, height: 40,
                        margin: const EdgeInsets.only(right: 6),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle, 
                          color: Colors.grey.shade200,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      )
                    )
                  );
                }
              } 
              // 1. Generate Filled Avatars (Loaded State)
              else if (snapshot.hasData) {
                for (int i = 0; i < filledCircles; i++) {
                  var userDoc = snapshot.data![i].data() as Map<String, dynamic>?;
                  String profilePicUrl = userDoc?["profilePicUrl"] ?? "";

                  avatarWidgets.add(
                    Container(
                      margin: const EdgeInsets.only(right: 6), // Creates the gap
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                      ),
                      child: CircleAvatar(
                        radius: 18, 
                        backgroundColor: const Color(0xFF0C3169).withOpacity(0.1),
                        backgroundImage: profilePicUrl.isNotEmpty ? NetworkImage(profilePicUrl) : null,
                        child: profilePicUrl.isEmpty 
                            ? const Icon(Icons.person, size: 20, color: Color(0xFF0C3169))
                            : null, 
                      ),
                    ),
                  );
                }
              }

              // 2. Generate Empty Avatars
              for (int i = 0; i < emptyCircles; i++) {
                avatarWidgets.add(
                  Container(
                    width: 40, 
                    height: 40,
                    margin: const EdgeInsets.only(right: 6), 
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey.shade50,
                      border: Border.all(color: Colors.grey.shade300, width: 1.5, strokeAlign: BorderSide.strokeAlignInside),
                    ),
                  ),
                );
              }
              return Row(children: avatarWidgets);
            },
          ),
          
          const SizedBox(height: 20),

          /// 📌 TYPE + PRICE
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(Icons.people_outline, size: 16, color: Color(0xFF0C3169)),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  detailsText,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis, 
                ),
              ),
            ],
          ),
            
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F0)),
          ),

          /// 📅 DATE
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8)
                ),
                child: const Icon(Icons.calendar_today, size: 14, color: Color(0xFF0C3169)),
              ),
              const SizedBox(width: 8),
              Text(
                formatDate(start),
                style: const TextStyle(fontSize: 12,  color: Colors.black87),
              ),
            ],
          ),
          const SizedBox(height: 5),

          /// ⏰ TIME & DURATION
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8)
                ),
                child: const Icon(Icons.access_time, size: 14, color: Color(0xFF0C3169)),
              ),
              const SizedBox(width: 8),
              Text(
                "${formatTime(start)} - ${formatTime(end)}  •  ${formatDuration(start, end)}", 
                style: const TextStyle(fontSize: 12, color: Colors.black87),
              ),
            ],
          ),
          const SizedBox(height: 5),

          /// 📍 LOCATION
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8)
                ),
                child: const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF0C3169)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    location,
                    style: const TextStyle(fontSize: 12, color: Colors.black87, height: 1.2),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          /// 🔵 JOIN BUTTON UI
          if (!isCreator)
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: (hasJoined || isFull) ? null : () => joinActivity(doc.id),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0C3169),
                  disabledBackgroundColor: Colors.grey.shade300,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  hasJoined
                      ? "Joined"
                      : isFull
                          ? "Game Full"
                          : "Join Game",
                  style: TextStyle(
                    color: (hasJoined || isFull) ? Colors.grey.shade600 : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            
          if (isCreator)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  "You are the host",
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}