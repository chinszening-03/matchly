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
  return "${date.day}/${date.month}/${date.year}";
}

String formatTime(Timestamp? timestamp) {
  if (timestamp == null) return "";
  final date = timestamp.toDate();
  final hour = date.hour > 12 ? date.hour - 12 : date.hour == 0 ? 12 : date.hour;
  final suffix = date.hour >= 12 ? "PM" : "AM";
  return "$hour:${date.minute.toString().padLeft(2, '0')} $suffix";
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
    if (_isSameDay(date, DateTime.now().add(const Duration(days: 1)))) return "Tmr";
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

    final currentUserId = AuthService().getCurrentUser()?.uid;
    final createdBy = data["createdBy"] ?? "";
    final participants = List<String>.from(data["participants"] ?? []);
    
    final isCreator = currentUserId == createdBy;
    final hasJoined = participants.contains(currentUserId);
    final isFull = participants.length >= max;

    return Container(
      width: double.infinity, 
      margin: const EdgeInsets.only(bottom: 16), 

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
          )
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// 🔵 SPORT TAG
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF0D47A1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              sport.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 10),

          /// 🏸 GAME NAME
          Text(
            name,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),

          /// 👥 PLAYERS + TYPE
          Row(
            children: [
              const Icon(Icons.people, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                "${participants.length}/$max players • $gameType", 
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          /// 💰 PRICE
          if (price > 0)
            Row(
              children: [
                const Icon(Icons.attach_money, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  "RM $price / pax",
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          const SizedBox(height: 10),
          const Divider(),
          const SizedBox(height: 8),

          /// 📅 DATE
          Row(
            children: [
              const Icon(Icons.calendar_month, size: 14),
              const SizedBox(width: 6),
              Text(
                formatDate(start),
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 6),

          /// ⏰ TIME
          Row(
            children: [
              const Icon(Icons.access_time, size: 14),
              const SizedBox(width: 6),
              Text(
                "${formatTime(start)} - ${formatTime(end)}",
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 6),

          /// 📍 LOCATION
          Row(
            children: [
              const Icon(Icons.location_on, size: 14),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  location,
                  style: const TextStyle(fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),

          /// 🔵 JOIN BUTTON UI
          if (!isCreator)
            SizedBox(
              width: double.infinity,
              height: 45,
              child: ElevatedButton(
                onPressed: (hasJoined || isFull) ? null : () => joinActivity(doc.id),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D47A1),
                  disabledBackgroundColor: Colors.grey.shade300,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
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
                  ),
                ),
              ),
            ),
            
          if (isCreator)
            Center(
              child: Text(
                "You are the host",
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }
}