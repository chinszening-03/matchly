import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

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
    minPeopleController.text = "2";
  }

  /// ROUND TIME TO 15 MINUTES
  DateTime roundToFifteen(DateTime time) {

    int minute = time.minute;
    int remainder = minute % 15;

    if (remainder != 0) {
      minute = minute + (15 - remainder);
    }

    return DateTime(
      time.year,
      time.month,
      time.day,
      time.hour,
      minute,
    );
  }

  /// CALCULATE DURATION
  String calculateDuration(DateTime start, DateTime end) {

  /// If end is before start → next day
  if (end.isBefore(start)) {
    end = end.add(const Duration(days: 1));
  }

  final diff = end.difference(start);

  final hours = diff.inHours;
  final minutes = diff.inMinutes % 60;

  if (minutes == 0) {
    return "${hours}h";
  }

  return "${hours}h ${minutes}m";
}

  void updateMinPlayers(String type) {

    if (type == "Singles") minPeopleController.text = "2";
    if (type == "Doubles") minPeopleController.text = "4";
    if (type == "Social") minPeopleController.text = "5";
  }

  Future<void> pickDate() async {

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
  }

  /// TIME PICKER
  Future<void> pickTimeRange() async {

    DateTime start = roundToFifteen(DateTime.now());
    DateTime end = roundToFifteen(
      DateTime.now().add(const Duration(hours: 2)),
    );

    await showModalBottomSheet(

      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),

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

                        const Text(
                          "Add time",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

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

                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),

                    child: Text(
                      "${TimeOfDay.fromDateTime(start).format(context)} - "
                      "${TimeOfDay.fromDateTime(end).format(context)}   $duration",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

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

                            onDateTimeChanged: (value) {

                              setModalState(() {
                                start = value;
                              });
                            },
                          ),
                        ),

                        const Text(
                          "-",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        Expanded(
                          child: CupertinoDatePicker(

                            mode: CupertinoDatePickerMode.time,
                            minuteInterval: 15,
                            use24hFormat: false,

                            initialDateTime: end,

                            onDateTimeChanged: (value) {

                              setModalState(() {
                                end = value;
                              });
                            },
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

    return Scaffold(

      appBar: AppBar(
        title: Text("Organise ${widget.sport} game"),
      ),

      body: SingleChildScrollView(

        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const Text(
              "Time & Location",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            ListTile(

              leading: const Icon(Icons.calendar_month),

              title: const Text("Date"),

              subtitle: Text(
                selectedDate == null
                    ? "Add date"
                    : selectedDate.toString().split(" ")[0],
              ),

              onTap: pickDate,
            ),

            const Divider(),

            ListTile(

              leading: const Icon(Icons.access_time),

              title: const Text("Time"),

              subtitle: Text(
                startTime == null
                    ? "Add time"
                    : "${startTime!.format(context)} - ${endTime!.format(context)}",
              ),

              onTap: pickTimeRange,
            ),

            const Divider(),

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
                    labelText: "Court number",
                    border: OutlineInputBorder(),
                  ),
                ),
              ),

            const SizedBox(height: 10),

            const Text(
              "Game details",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            TextField(

              controller: nameController,

              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.text_fields),
                labelText: "Name",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

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

            const SizedBox(height: 12),

            TextField(

              controller: minPeopleController,
              keyboardType: TextInputType.number,

              decoration: const InputDecoration(
                labelText: "Min people",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

            TextField(

              controller: maxPeopleController,
              keyboardType: TextInputType.number,

              decoration: const InputDecoration(
                labelText: "Max people",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 30),

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

                onPressed: () {},

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