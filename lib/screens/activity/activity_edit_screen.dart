import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'location_search_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ActivityEditScreen extends StatefulWidget {
  final String activityId; // 👈 Required for editing
  final String sport;

  const ActivityEditScreen({
    super.key,
    required this.activityId,
    required this.sport,
  });

  @override
  State<ActivityEditScreen> createState() => _ActivityEditScreenState();
}

class _ActivityEditScreenState extends State<ActivityEditScreen> {
  // State Variables
  DateTime? selectedDate;
  TimeOfDay? startTime;
  TimeOfDay? endTime;
  bool courtBooked = false;
  String gameType = "Singles";
  double? selectedLat;
  double? selectedLng;
  bool isLoading = true; // 👈 Added loading state

  final List<String> gameTypes = ["Singles", "Doubles", "Social"];

  // Controllers
  final TextEditingController locationController = TextEditingController();
  final TextEditingController courtController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController minPeopleController = TextEditingController();
  final TextEditingController maxPeopleController = TextEditingController();
  final TextEditingController priceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadActivityData(); // 👈 Load existing data on start
  }

  /// ================= FETCH DATA FROM FIRESTORE =================
  Future<void> _loadActivityData() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection("activities")
          .doc(widget.activityId)
          .get();

      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        setState(() {
          nameController.text = data["name"] ?? "";
          descriptionController.text = data["description"] ?? "";
          locationController.text = data["location"] ?? "";
          
          GeoPoint coords = data["coordinates"];
          selectedLat = coords.latitude;
          selectedLng = coords.longitude;

          courtBooked = data["isCourtBooked"] ?? false;
          courtController.text = data["courtDetails"] ?? "";
          gameType = data["gameType"] ?? "Singles";
          
          minPeopleController.text = (data["minPeople"] ?? 2).toString();
          maxPeopleController.text = (data["maxPeople"] ?? 4).toString();
          priceController.text = data["price"]?.toString() ?? "";

          // Handle Dates & Times
          Timestamp? startTs = data["startTime"];
          Timestamp? endTs = data["endTime"];
          if (startTs != null) {
            selectedDate = startTs.toDate();
            startTime = TimeOfDay.fromDateTime(startTs.toDate());
          }
          if (endTs != null) {
            endTime = TimeOfDay.fromDateTime(endTs.toDate());
          }
          
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading activity: $e");
    }
  }

  /// ================= LOGIC HELPERS =================
  DateTime roundToFifteen(DateTime time) {
    int minute = time.minute;
    int remainder = minute % 15;
    if (remainder != 0) minute = minute + (15 - remainder);
    return DateTime(time.year, time.month, time.day, time.hour, minute);
  }

  String calculateDuration(DateTime start, DateTime end) {
    if (end.isBefore(start)) end = end.add(const Duration(days: 1));
    final diff = end.difference(start);
    final hours = diff.inHours;
    final minutes = diff.inMinutes % 60;
    if (minutes == 0) return "${hours}h";
    return "${hours}h ${minutes}m";
  }

  String formatDate(DateTime date) => DateFormat("EEEE, d MMM yyyy").format(date);

  /// ================= UI HELPERS =================
  Widget sectionTitle(String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
  );

  Widget requiredLabel(String text) => RichText(
    text: TextSpan(
      text: text,
      style: const TextStyle(color: Colors.black, fontSize: 16),
      children: const [TextSpan(text: " *", style: TextStyle(color: Colors.red))],
    ),
  );

  Widget cardWrapper({required Widget child}) => Container(
    padding: const EdgeInsets.all(14),
    margin: const EdgeInsets.only(bottom: 14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6)],
    ),
    child: child,
  );

  /// ================= PICKERS =================
  Future<void> pickDate() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)), // Allow past dates for edits
      lastDate: DateTime(2100),
      initialDate: selectedDate ?? DateTime.now(),
    );
    if (date != null) setState(() => selectedDate = date);
  }

  Future<void> pickTimeRange() async {
    DateTime start = selectedDate != null && startTime != null 
        ? DateTime(selectedDate!.year, selectedDate!.month, selectedDate!.day, startTime!.hour, startTime!.minute)
        : roundToFifteen(DateTime.now());
    
    DateTime end = selectedDate != null && endTime != null 
        ? DateTime(selectedDate!.year, selectedDate!.month, selectedDate!.day, endTime!.hour, endTime!.minute)
        : start.add(const Duration(hours: 2));

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            String duration = calculateDuration(start, end);
            return SizedBox(
              height: 320,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Edit time", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              startTime = TimeOfDay.fromDateTime(start);
                              endTime = TimeOfDay.fromDateTime(end);
                            });
                            Navigator.pop(context);
                          },
                          child: const Text("Done"),
                        )
                      ],
                    ),
                  ),
                  Text("${TimeOfDay.fromDateTime(start).format(context)} - ${TimeOfDay.fromDateTime(end).format(context)}   $duration",
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                  const Divider(),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: CupertinoDatePicker(
                            mode: CupertinoDatePickerMode.time,
                            minuteInterval: 15,
                            use24hFormat: false,
                            initialDateTime: start,
                            onDateTimeChanged: (value) => setModalState(() => start = value),
                          ),
                        ),
                        const Text("-", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                        Expanded(
                          child: CupertinoDatePicker(
                            mode: CupertinoDatePickerMode.time,
                            minuteInterval: 15,
                            use24hFormat: false,
                            initialDateTime: end,
                            onDateTimeChanged: (value) => setModalState(() => end = value),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text("Edit ${widget.sport}"),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            sectionTitle("Time & Location"),
            cardWrapper(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.calendar_month),
                    title: requiredLabel("Date"),
                    subtitle: Text(selectedDate == null ? "Add date" : formatDate(selectedDate!)),
                    onTap: pickDate,
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.access_time),
                    title: requiredLabel("Time"),
                    subtitle: Text(startTime == null ? "Add time" : "${startTime!.format(context)} - ${endTime!.format(context)}"),
                    onTap: pickTimeRange,
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.location_on),
                    title: requiredLabel("Location"),
                    subtitle: Text(locationController.text.isEmpty ? "Search venue" : locationController.text),
                    onTap: () async {
                      final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const LocationSearchScreen()));
                      if (result != null) {
                        setState(() {
                          locationController.text = result["name"];
                          selectedLat = result["lat"];
                          selectedLng = result["lng"];
                        });
                      }
                    },
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Court booked", style: TextStyle(fontSize: 16)),
                      GestureDetector(
                        onTap: () => setState(() => courtBooked = !courtBooked),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          width: 50, height: 28, padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: courtBooked ? const Color(0xFF00BFA5) : Colors.grey.shade300,
                          ),
                          child: Align(
                            alignment: courtBooked ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(width: 20, height: 20, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: courtBooked
                        ? Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: TextField(
                              controller: courtController,
                              decoration: InputDecoration(
                                labelText: "Court details",
                                hintText: "e.g. Court 3",
                                prefixIcon: const Icon(Icons.sports_tennis),
                                filled: true, fillColor: Colors.grey[100],
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                              ),
                            ),
                          )
                        : const SizedBox(),
                  ),
                ],
              ),
            ),
            sectionTitle("Game Details"),
            cardWrapper(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(label: requiredLabel("Name"), prefixIcon: const Icon(Icons.text_fields)),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descriptionController,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: "Description (optional)", prefixIcon: Icon(Icons.notes)),
                  ),
                  const SizedBox(height: 16),
                  const Text("Game Type", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      gameTypeCard("Singles", "2+"),
                      gameTypeCard("Doubles", "4+"),
                      gameTypeCard("Social", "5+"),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: buildStepper("Min", minPeopleController)),
                      const SizedBox(width: 10),
                      Expanded(child: buildStepper("Max", maxPeopleController)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: priceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: "Price per pax (optional)", prefixIcon: Icon(Icons.attach_money)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity, height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D47A1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () async {
                  // Validation
                  int min = int.tryParse(minPeopleController.text) ?? 0;
                  int max = int.tryParse(maxPeopleController.text) ?? 0;
                  if (locationController.text.isEmpty || selectedDate == null || startTime == null || max < min) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill all required fields correctly.")));
                    return;
                  }

                  final startDateTime = DateTime(selectedDate!.year, selectedDate!.month, selectedDate!.day, startTime!.hour, startTime!.minute);
                  final endDateTime = DateTime(selectedDate!.year, selectedDate!.month, selectedDate!.day, endTime!.hour, endTime!.minute);
                  final finalEnd = endDateTime.isBefore(startDateTime) ? endDateTime.add(const Duration(days: 1)) : endDateTime;

                  // 👈 UPDATE LOGIC
                  await FirebaseFirestore.instance.collection("activities").doc(widget.activityId).update({
                    "name": nameController.text,
                    "description": descriptionController.text,
                    "location": locationController.text,
                    "coordinates": GeoPoint(selectedLat!, selectedLng!),
                    "isCourtBooked": courtBooked,
                    "courtDetails": courtBooked ? courtController.text : "",
                    "gameType": gameType,
                    "minPeople": min,
                    "maxPeople": max,
                    "price": priceController.text.isEmpty ? null : double.tryParse(priceController.text),
                    "startTime": startDateTime,
                    "endTime": finalEnd,
                    "date": selectedDate,
                    "lastUpdated": Timestamp.now(),
                  });

                  Navigator.pop(context); // Go back to details
                },
                child: const Text("Update Activity", style: TextStyle(color: Colors.white)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget gameTypeCard(String type, String subtitle) {
    final selected = gameType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => gameType = type),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4), padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF00BFA5) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected ? const Color(0xFF00BFA5) : Colors.grey.shade300),
          ),
          child: Column(
            children: [
              Text(type, style: TextStyle(color: selected ? Colors.white : Colors.black)),
              Text(subtitle, style: TextStyle(fontSize: 11, color: selected ? Colors.white70 : Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildStepper(String title, TextEditingController controller) {
    int value = int.tryParse(controller.text) ?? 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(10)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(icon: const Icon(Icons.remove), onPressed: () { if (value > 1) setState(() { value--; controller.text = value.toString(); _validateMinMax(); }); }),
              Text(value.toString()),
              IconButton(icon: const Icon(Icons.add), onPressed: () { setState(() { value++; controller.text = value.toString(); }); }),
            ],
          ),
        ),
      ],
    );
  }

  void _validateMinMax() {
    int min = int.tryParse(minPeopleController.text) ?? 0;
    int max = int.tryParse(maxPeopleController.text) ?? 0;
    if (max < min) maxPeopleController.text = min.toString();
  }
}