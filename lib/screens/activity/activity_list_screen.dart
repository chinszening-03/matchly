import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ActivityListScreen extends StatefulWidget {
  final String sport;

  const ActivityListScreen({super.key, required this.sport});

  @override
  State<ActivityListScreen> createState() => _ActivityListScreenState();
}

class _ActivityListScreenState extends State<ActivityListScreen> {

  String selectedSport = "";
  String sortBy = "Time";
  bool showFull = false;

  RangeValues priceRange = const RangeValues(0, 100);
  RangeValues slotRange = const RangeValues(1, 10);

  DateTime? selectedDate;

  final List<String> sports = [
    "Badminton","Pickleball","Basketball","Tennis","Pilates",
    "Paintball","Golf","Hiking","Football","Futsal",
    "Bowling","Bouldering","Dodgeball","Running","Squash",
    "Table Tennis","Frisbee","Volleyball"
  ];

  final List<String> activityTypes = ["All", "Singles", "Doubles", "Social"];
  String selectedType = "All";

  @override
  void initState() {
    super.initState();
    selectedSport = widget.sport;
  }

  /// ================= DATE PICKER =================
  Future<void> pickDate() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      initialDate: DateTime.now(),
    );

    if (date != null) {
      setState(() => selectedDate = date);
    }
  }

  /// ================= BUILD =================
  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Text(selectedSport),
      ),

      body: Column(
        children: [

          /// ================= FILTER BAR =================
          SizedBox(
            height: 120,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(10),

              child: Row(
                children: [

                  filterButton("📍 Map", () {}),
                  filterButton("📌 Pin Game", () {}),

                  filterButton("Sort: $sortBy", () {
                    showSortDialog();
                  }),

                  filterButton("Date", pickDate),

                  filterButton("Sport", showSportPicker),

                  filterButton("Type", showTypePicker),

                  filterButton("Price", showPriceSlider),

                  filterButton("Slots", showSlotSlider),

                  filterButton(
                    showFull ? "Hide Full" : "Show Full",
                        () {
                      setState(() {
                        showFull = !showFull;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),

          const Divider(),

          /// ================= ACTIVITY LIST =================
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("activities")
                  .orderBy("createdAt", descending: true)
                  .snapshots(),

              builder: (context, snapshot) {

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs.where((doc) {

                  final data = doc.data() as Map<String, dynamic>;

                  /// SPORT FILTER
                  if (data["sport"] != selectedSport) return false;

                  /// TYPE FILTER
                  if (selectedType != "All" &&
                      data["gameType"] != selectedType) return false;

                  return true;

                }).toList();

                return ListView.builder(
                  itemCount: docs.length,
                  padding: const EdgeInsets.all(12),

                  itemBuilder: (context, index) {
                    return activityCard(docs[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// ================= FILTER BUTTON =================
  Widget filterButton(String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),

        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade300),
        ),

        child: Text(text),
      ),
    );
  }

  /// ================= ACTIVITY CARD =================
  Widget activityCard(QueryDocumentSnapshot doc) {

    final data = doc.data() as Map<String, dynamic>;

    final Timestamp? startTs = data["startTime"];
    final Timestamp? endTs = data["endTime"];

    final start = startTs?.toDate();
    final end = endTs?.toDate();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
          )
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          /// TOP
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [

              Text(
                data["name"] ?? "",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),

              Text(
                data["gameType"] ?? "",
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),

          const SizedBox(height: 6),

          Text("🏸 ${data["sport"]}"),
          Text("👥 ${data["minPeople"]} - ${data["maxPeople"]} players"),
          Text("📍 ${data["location"]}"),

          if (start != null && end != null)
            Text(
              "⏰ ${DateFormat("hh:mm a").format(start)} - ${DateFormat("hh:mm a").format(end)}",
            ),

          if (data["price"] != null)
            Text("💰 RM ${data["price"]}"),

          const SizedBox(height: 10),

          /// JOIN BUTTON
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {

                /// TODO: join logic later
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D47A1),
              ),
              child: const Text("Join"),
            ),
          ),
        ],
      ),
    );
  }

  /// ================= SORT =================
  void showSortDialog() {
    showModalBottomSheet(
      context: context,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(title: const Text("Time"), onTap: () {
            setState(() => sortBy = "Time");
            Navigator.pop(context);
          }),
          ListTile(title: const Text("Distance"), onTap: () {
            setState(() => sortBy = "Distance");
            Navigator.pop(context);
          }),
        ],
      ),
    );
  }

  /// ================= SPORT PICKER =================
  void showSportPicker() {
    showModalBottomSheet(
      context: context,
      builder: (_) => ListView(
        children: sports.map((sport) {
          return ListTile(
            title: Text(sport),
            onTap: () {
              setState(() => selectedSport = sport);
              Navigator.pop(context);
            },
          );
        }).toList(),
      ),
    );
  }

  /// ================= TYPE PICKER =================
  void showTypePicker() {
    showModalBottomSheet(
      context: context,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: activityTypes.map((type) {
          return ListTile(
            title: Text(type),
            onTap: () {
              setState(() => selectedType = type);
              Navigator.pop(context);
            },
          );
        }).toList(),
      ),
    );
  }

  /// ================= PRICE =================
  void showPriceSlider() {
    showModalBottomSheet(
      context: context,
      builder: (_) => RangeSlider(
        values: priceRange,
        min: 0,
        max: 200,
        divisions: 20,
        labels: RangeLabels(
          priceRange.start.toString(),
          priceRange.end.toString(),
        ),
        onChanged: (value) {
          setState(() => priceRange = value);
        },
      ),
    );
  }

  /// ================= SLOT =================
  void showSlotSlider() {
    showModalBottomSheet(
      context: context,
      builder: (_) => RangeSlider(
        values: slotRange,
        min: 1,
        max: 10,
        divisions: 9,
        labels: RangeLabels(
          slotRange.start.toString(),
          slotRange.end.toString(),
        ),
        onChanged: (value) {
          setState(() => slotRange = value);
        },
      ),
    );
  }
}