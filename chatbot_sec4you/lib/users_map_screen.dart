import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'user_location_service.dart';

class UsersMapScreen extends StatelessWidget {
  const UsersMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('<Mapa de Usuários./>')),
      body: Stack(
        children: [
          // Mapa dos usuários
          Positioned.fill(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('user_locations').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final markers = <Marker>[];
                for (var doc in snapshot.data!.docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  markers.add(
                    Marker(
                      width: 40,
                      height: 40,
                      point: LatLng(data['latitude'], data['longitude']),
                      child: const Icon(Icons.person_pin_circle, color: Colors.purple, size: 36),
                    ),
                  );
                }
                return FlutterMap(
                  options: MapOptions(
                    center: markers.isNotEmpty ? markers.first.point : LatLng(0, 0),
                    zoom: 2,
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
          // Número de usuários ativos na parte de baixo
          Positioned(
            left: 0,
            right: 0,
            bottom: 16,
            child: Center(
              child: FutureBuilder<int>(
                future: UserLocationService.getActiveUsersCount(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  }
                  if (snapshot.hasError) {
                    return const Text(
                      'Erro ao carregar usuários ativos',
                      style: TextStyle(color: Colors.white),
                    );
                  }
                  final count = snapshot.data ?? 0;
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Text(
                      'Usuários ativos: $count',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
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