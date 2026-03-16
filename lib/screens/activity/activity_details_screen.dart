import 'package:flutter/material.dart';

class ActivityDetailsScreen extends StatefulWidget {

  final String sport;

  const ActivityDetailsScreen({
    super.key,
    required this.sport,
  });

  @override
  State<ActivityDetailsScreen> createState() => _ActivityDetailsScreenState();
}

class _ActivityDetailsScreenState extends State<ActivityDetailsScreen> {

  DateTime? selectedDate;

  TimeOfDay? startTime;
  TimeOfDay? endTime;

  bool courtBooked = false;

  /// Game Type
  String gameType = "Singles";

  final List<String> gameTypes = [
    "Singles",
    "Doubles",
    "Social"
  ];

  final TextEditingController locationController = TextEditingController();
  final TextEditingController courtController = TextEditingController();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  final TextEditingController minPeopleController = TextEditingController();
  final TextEditingController maxPeopleController = TextEditingController();

  @override
  void initState() {
    super.initState();

    /// default min players
    minPeopleController.text = "2";
  }

  void updateMinPlayers(String type) {

    if (type == "Singles") {
      minPeopleController.text = "2";
    }

    if (type == "Doubles") {
      minPeopleController.text = "4";
    }

    if (type == "Social") {
      minPeopleController.text = "5";
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: Text(widget.sport),
      ),

      body: SingleChildScrollView(

        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// DATE
            ListTile(

              leading: const Icon(Icons.calendar_month),

              title: const Text("Date"),

              subtitle: Text(
                selectedDate == null
                    ? "Add date"
                    : selectedDate.toString().split(" ")[0],
              ),

              onTap: () async {

                final date = await showDatePicker(
                  context: context,
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2100),
                  initialDate: DateTime.now(),
                );

                if (date != null) {
                  setState(() {
                    selectedDate = date;
                  });
                }
              },
            ),

            const Divider(),

            /// TIME
            ListTile(

              leading: const Icon(Icons.access_time),

              title: const Text("Time"),

              subtitle: Text(
                startTime == null
                    ? "Add time"
                    : "${startTime!.format(context)} - ${endTime?.format(context) ?? ""}",
              ),

              onTap: () async {

                final start = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now(),
                );

                if (start != null) {

                  final end = await showTimePicker(
                    context: context,
                    initialTime: start,
                  );

                  setState(() {
                    startTime = start;
                    endTime = end;
                  });
                }
              },
            ),

            const Divider(),

            /// LOCATION
            ListTile(
              leading: const Icon(Icons.location_on),
              title: const Text("Location"),
              subtitle: TextField(
                controller: locationController,
                decoration: const InputDecoration(
                  hintText: "Search a city, town, venue...",
                  border: InputBorder.none,
                ),
              ),
            ),

            const Divider(),

            /// COURT BOOKED
            SwitchListTile(

              title: const Text("Court booked"),

              value: courtBooked,

              onChanged: (v) {
                setState(() {
                  courtBooked = v;
                });
              },
            ),

            if (courtBooked)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),

                child: TextField(
                  controller: courtController,
                  decoration: const InputDecoration(
                    hintText: "Court number",
                    border: OutlineInputBorder(),
                  ),
                ),
              ),

            const SizedBox(height: 10),

            /// GAME DETAILS
            const Text(
              "GAME DETAILS",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 12),

            /// NAME
            TextField(

              controller: nameController,

              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.text_fields),
                labelText: "Name",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

            /// DESCRIPTION
            TextField(

              controller: descriptionController,
              maxLines: 3,

              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.notes),
                labelText: "Description (optional)",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            /// GAME TYPE
            DropdownButtonFormField(

              value: gameType,

              items: gameTypes.map((type) {

                return DropdownMenuItem(
                  value: type,
                  child: Text(type),
                );

              }).toList(),

              onChanged: (value) {

                setState(() {

                  gameType = value!;
                  updateMinPlayers(gameType);

                });

              },

              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.people),
                labelText: "Game type",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            /// MIN PEOPLE
            TextField(

              controller: minPeopleController,
              keyboardType: TextInputType.number,

              decoration: const InputDecoration(
                labelText: "Min people",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

            /// MAX PEOPLE
            TextField(

              controller: maxPeopleController,
              keyboardType: TextInputType.number,

              decoration: const InputDecoration(
                labelText: "Max people",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 30),

            /// CREATE BUTTON
            SizedBox(
              width: double.infinity,
              height: 50,

              child: ElevatedButton(

                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D47A1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),

                onPressed: () {

                  /// later save to firestore

                },

                child: const Text(
                  "Create Activity",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

          ],
        ),
      ),
    );
  }
}