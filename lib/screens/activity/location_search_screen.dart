import 'package:flutter/material.dart';
import 'package:flutter_google_places_sdk/flutter_google_places_sdk.dart';
import 'package:geolocator/geolocator.dart'; // Add this to pubspec.yaml
import 'dart:async'; // For Timer (Debouncing)
import 'package:geocoding/geocoding.dart';

class LocationSearchScreen extends StatefulWidget {
  const LocationSearchScreen({super.key});

  @override
  State<LocationSearchScreen> createState() => _LocationSearchScreenState();
}

class _LocationSearchScreenState extends State<LocationSearchScreen> {
  // REPLACE with your actual API Key
  final places = FlutterGooglePlacesSdk("AIzaSyBaY9J1xCNSSCxxIq3dyvqSROLv7XkBp98");
  final TextEditingController controller = TextEditingController();
  
  List<AutocompletePrediction> results = [];
  bool loading = false;
  Timer? _debounce; // 👈 1. Added for saving API money

  // 👈 2. API SAVING LOGIC (Debouncing)
  void searchPlaces(String input) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    // Only search after the user stops typing for 600ms
    _debounce = Timer(const Duration(milliseconds: 600), () async {
      if (input.isEmpty) {
        setState(() { results = []; loading = false; });
        return;
      }

      setState(() => loading = true);
      try {
        final response = await places.findAutocompletePredictions(input);
        if (!mounted) return;
        setState(() => results = response.predictions);
      } catch (e) {
        debugPrint("ERROR: $e");
      } finally {
        if (mounted) setState(() => loading = false);
      }
    });
  }

  // 👈 3. USE CURRENT LOCATION LOGIC
  Future<void> _getCurrentLocation() async {
  setState(() => loading = true);
  try {
    // 1. Check/Request Permissions
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
      // 2. Get the raw coordinates
      Position position = await Geolocator.getCurrentPosition();
      
      // 3. 🛡️ THE MAGIC PART: Reverse Geocoding
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude, 
        position.longitude
      );

      String addressName = "Unknown Location";
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        // Construct a clean name (e.g., "Puchong, Selangor")
        addressName = "${place.locality}, ${place.administrativeArea}";
      }

      if (mounted) {
        Navigator.pop(context, {
          "name": addressName, // 👈 This now shows the real city name!
          "lat": position.latitude,
          "lng": position.longitude,
        });
      }
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Error: $e")),
    );
  } finally {
    if (mounted) setState(() => loading = false);
  }
}
  Future<void> selectPlace(AutocompletePrediction prediction) async {
    final detail = await places.fetchPlace(
      prediction.placeId,
      fields: [PlaceField.Location],
    );

    if (mounted) {
      Navigator.pop(context, {
        "name": prediction.fullText,
        "lat": detail.place?.latLng?.lat,
        "lng": detail.place?.latLng?.lng,
      });
    }
  }

  @override
  void dispose() {
    _debounce?.cancel(); // Clean up the timer
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Search Location")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: controller,
              onChanged: searchPlaces,
              decoration: InputDecoration(
                hintText: "Search courts, parks...",
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => controller.clear(),
                ),
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          
          // 👇 "USE CURRENT LOCATION" BUTTON
          ListTile(
            leading: const Icon(Icons.my_location, color: Color(0xFF0D47A1)),
            title: const Text("Use Current Location", 
              style: TextStyle(color: Color(0xFF0D47A1), fontWeight: FontWeight.bold)),
            onTap: _getCurrentLocation,
          ),
          const Divider(),

          if (loading) const LinearProgressIndicator(),

          Expanded(
            child: ListView.builder(
              itemCount: results.length,
              itemBuilder: (context, index) {
                final place = results[index];
                return ListTile(
                  leading: const Icon(Icons.location_on_outlined),
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