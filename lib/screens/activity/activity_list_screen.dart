import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ActivityListScreen extends StatefulWidget {
  // 1. Add the sport parameter here
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
    final hour = date.hour > 12 ? date.hour - 12 : date.hour;
    final suffix = date.hour >= 12 ? "PM" : "AM";
    return "$hour:${date.minute.toString().padLeft(2, '0')} $suffix";
  }

class _ActivityListScreenState extends State<ActivityListScreen> {
  DateTime _selectedDate = DateTime.now();

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

  @override
  Widget build(BuildContext context) {
    DateTime startOfDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    DateTime endOfDay = startOfDay.add(const Duration(days: 1)).subtract(const Duration(seconds: 1));

    DateTime today = DateTime.now();
    int daysInMonth = DateTime(today.year, today.month + 1, today.day).difference(today).inDays;
    
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        // 2. Display the selected sport in the App Bar
        title: Text(widget.sport, style: const TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          // Filter Bar Placeholder
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: const Row(
              children: [
                Icon(Icons.filter_list),
                SizedBox(width: 8),
                Text("Your Filter Bar Here", style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),

          // The Date Filter Row
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

          // StreamBuilder with Sport AND Date Filter
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("activities")
                  // 3. Filter by the selected sport
                  .where("sport", isEqualTo: widget.sport) 
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
                    child: Text("No ${widget.sport} games found for this date.", style: const TextStyle(color: Colors.grey)),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var doc = snapshot.data!.docs[index];
                    
                    // Call the custom UI card here!
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

    final min = data["minPeople"] ?? 0;
    final max = data["maxPeople"] ?? 0;
    final price = data["price"] ?? 0;

    final start = data["startTime"] as Timestamp?;
    final end = data["endTime"] as Timestamp?;

    return Container(
      width: double.infinity, // Changed to fill the screen width
      margin: const EdgeInsets.only(bottom: 16), // Changed to bottom margin for vertical scrolling

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
                "$min-$max players • $gameType",
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
        ],
      ),
    );
  }
}