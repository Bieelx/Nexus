import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserLocationService {
  static Future<void> updateUserLocation(String userId) async {
    try {
      // Solicita permissão
      LocationPermission permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Não concedeu permissão
        return;
      }
      // Pega a localização
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

      // Salva no Firestore
      await FirebaseFirestore.instance.collection('user_locations').doc(userId).set({
        'userId': userId,
        'latitude': position.latitude,
        'longitude': position.longitude,
        'timestamp': FieldValue.serverTimestamp(),
        'isActive': true,
      });
    } catch (e) {
      print('Erro ao salvar localização: $e');
    }
  }

  static Future<int> getActiveUsersCount() async {
    final snap = await FirebaseFirestore.instance
        .collection('user_locations')
        .where('isActive', isEqualTo: true)
        .get();
    return snap.docs.length;
  }
}