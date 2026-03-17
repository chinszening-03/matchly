import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_google_places_sdk/flutter_google_places_sdk.dart';

class LocationSearchScreen extends StatefulWidget {
  const LocationSearchScreen({super.key});

  @override
  State<LocationSearchScreen> createState() => _LocationSearchScreenState();
}

class _LocationSearchScreenState extends State<LocationSearchScreen> {

  final places = FlutterGooglePlacesSdk("AIzaSyBaY9J1xCNSSCxxIq3dyvqSROLv7XkBp98");

  final TextEditingController controller = TextEditingController();

  List<AutocompletePrediction> results = [];

  bool loading = false;

  void searchPlaces(String input) async {

    if (input.isEmpty) {
      setState(() => results = []);
      return;
    }

    setState(() => loading = true);

    try {

      final response = await places.findAutocompletePredictions(input);

      setState(() {
        results = response.predictions;
      });

    } catch (e) {
      log("ERROR: $e");
    }

    setState(() => loading = false);
  }

  Future<void> selectPlace(AutocompletePrediction prediction) async {

    final detail = await places.fetchPlace(
      prediction.placeId!,
      fields: [PlaceField.Location],
    );

    final lat = detail.place?.latLng?.lat;
    final lng = detail.place?.latLng?.lng;

    if (mounted) {
      Navigator.pop(context, {
        "name": prediction.fullText,
        "lat": lat,
        "lng": lng,
      });
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text("Search Location"),
      ),

      body: Column(
        children: [

          Padding(
            padding: const EdgeInsets.all(16),

            child: TextField(
              controller: controller,
              onChanged: searchPlaces,

              decoration: const InputDecoration(
                hintText: "Search courts, parks...",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),

          if (loading)
            const CircularProgressIndicator(),

          Expanded(
            child: ListView.builder(

              itemCount: results.length,

              itemBuilder: (context, index) {

                final place = results[index];

                return ListTile(

                  leading: const Icon(Icons.location_on),

                  title: Text(place.primaryText),

                  subtitle: Text(place.secondaryText),

                  onTap: () => selectPlace(place),
                );
              },
            ),
          )

        ],
      ),
    );
  }
}