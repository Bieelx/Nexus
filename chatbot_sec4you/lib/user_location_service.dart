import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'local_user_id.dart';

class UserLocationService {
  static Future<Position?> getUserLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }
    if (permission == LocationPermission.deniedForever) return null;

    return await Geolocator.getCurrentPosition();
  }

  static Future<void> saveUserLocation() async {
    final position = await getUserLocation();
    final userId = await LocalUserId.getId();
    if (position != null) {
      await FirebaseFirestore.instance.collection('user_locations').doc(userId).set({
        'latitude': position.latitude,
        'longitude': position.longitude,
        'timestamp': FieldValue.serverTimestamp(),
      });
    }
  }

  static Future<int> getActiveUsersCount() async {
    final snapshot = await FirebaseFirestore.instance.collection('user_locations').get();
    return snapshot.docs.length;
  }
}