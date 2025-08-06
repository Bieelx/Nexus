import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MiniMapWidget extends StatelessWidget {
  const MiniMapWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(0xFF9F45FF), width: 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('user_locations').snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final markers = <Marker>[];
            for (var doc in snapshot.data!.docs) {
              final data = doc.data() as Map<String, dynamic>;
              markers.add(
                Marker(
                  width: 30,
                  height: 30,
                  point: LatLng(data['latitude'], data['longitude']),
                  child: const Icon(Icons.person_pin_circle, color: Colors.purple, size: 28),
                ),
              );
            }
            return FlutterMap(
              options: MapOptions(
                center: markers.isNotEmpty ? markers.first.point : LatLng(0, 0),
                zoom: 2,
                interactiveFlags: InteractiveFlag.none, // Não permite mover/zoom, só visualização
              ),
              children: [
                TileLayer(
                  urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                  userAgentPackageName: 'com.example.app',
                ),
                MarkerLayer(markers: markers),
              ],
            );
          },
        ),
      ),
    );
  }
}