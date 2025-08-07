import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MiniMapWidget extends StatelessWidget {
  const MiniMapWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 380,
      height: 274,
      decoration: BoxDecoration(
        color: const Color(0xFF393939),
        borderRadius: BorderRadius.circular(29),
      ),
      
      child: Stack(
        children: [
          Positioned(
            left: 107,
            top: 15,
            right: 15,
            bottom: 15,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('markers').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: Text('Nenhum dado.'));
                  }
                  final List<Marker> markers = snapshot.data!.docs.map<Marker>((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return Marker(
                      width: 40,
                      height: 40,
                      point: LatLng(
                        data['latitude'] ?? 0.0,
                        data['longitude'] ?? 0.0,
                      ),
                      child: const Icon(Icons.location_on, color: Colors.red, size: 32),
                    );
                  }).toList();
                  return FlutterMap(
                    options: MapOptions(
                      center: LatLng(-23.5505, -46.6333),
                      zoom: 12,
                      interactiveFlags: InteractiveFlag.none,
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
          ),
        ],
      ),
    );
  }
}