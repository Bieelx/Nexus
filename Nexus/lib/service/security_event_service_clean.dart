// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:device_info_plus/device_info_plus.dart';

// class SecurityEventService {
//   // Registra tentativa de login (sucesso ou falha)
//   static Future<void> logLoginAttempt({
//     required String email,
//     required bool success,
//     String? errorMessage,
//   }) async {
//     print('🔐 Registrando evento: ${success ? "SUCESSO" : "FALHA"} para $email');
    
//     try {
//       // Coleta informações do contexto
//       final deviceInfo = await _getDeviceInfo();
//       final location = await _getLocationInfo();
//       final ipAddress = await _getIPAddress();

//       // Cria evento estruturado
//       final eventData = {
//         'userEmail': email,
//         'success': success,
//         'errorMessage': errorMessage,
//         'timestamp': DateTime.now().toIso8601String(),
//         'deviceInfo': deviceInfo,
//         'location': location,
//         'ipAddress': ipAddress,
//         'eventType': success ? 'LOGIN_SUCCESS' : 'LOGIN_FAILURE',
//         'severity': success ? 'Info' : 'High',
//         'source': 'SecurApp Mobile',
//         'category': 'Authentication',
//       };

//       // Salva no Firebase
//       await _saveToFirebase(eventData);
//       print('✅ Evento registrado com sucesso!');

//     } catch (e) {
//       print('❌ Erro ao registrar evento: $e');
//     }
//   }

//   // Salva no Firebase
//   static Future<void> _saveToFirebase(Map<String, dynamic> eventData) async {
//     try {
//       print('💾 Salvando no Firebase...');
      
//       final docRef = await FirebaseFirestore.instance
//           .collection('security_events')
//           .add({
//         ...eventData,
//         'timestamp': FieldValue.serverTimestamp(),
//         'created_at': DateTime.now().toIso8601String(),
//       });
      
//       print('✅ Evento salvo no Firebase com ID: ${docRef.id}');
      
//     } catch (e) {
//       print('❌ Erro ao salvar no Firebase: $e');
//       rethrow;
//     }
//   }

//   // Coleta informações do dispositivo
//   static Future<Map<String, dynamic>> _getDeviceInfo() async {
//     try {
//       DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      
//       if (Theme.of(WidgetsBinding.instance.rootElement!).platform == TargetPlatform.android) {
//         AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
//         return {
//           'platform': 'Android',
//           'model': androidInfo.model,
//           'manufacturer': androidInfo.manufacturer,
//           'version': androidInfo.version.release,
//           'device_id': androidInfo.id,
//         };
//       } else if (Theme.of(WidgetsBinding.instance.rootElement!).platform == TargetPlatform.iOS) {
//         IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
//         return {
//           'platform': 'iOS',
//           'model': iosInfo.model,
//           'name': iosInfo.name,
//           'version': iosInfo.systemVersion,
//           'device_id': iosInfo.identifierForVendor,
//         };
//       }
//     } catch (e) {
//       print('❌ Erro ao obter info do dispositivo: $e');
//     }
    
//     return {
//       'platform': 'Unknown',
//       'model': 'Unknown',
//       'error': 'Failed to get device info'
//     };
//   }

//   // Obtém localização aproximada
//   static Future<Map<String, dynamic>> _getLocationInfo() async {
//     try {
//       LocationPermission permission = await Geolocator.checkPermission();
//       if (permission == LocationPermission.denied) {
//         permission = await Geolocator.requestPermission();
//       }

//       if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
//         Position position = await Geolocator.getCurrentPosition(
//           desiredAccuracy: LocationAccuracy.low,
//           timeLimit: const Duration(seconds: 5),
//         );
        
//         return {
//           'latitude': position.latitude,
//           'longitude': position.longitude,
//           'accuracy': position.accuracy,
//           'timestamp': position.timestamp.toIso8601String(),
//         };
//       }
//     } catch (e) {
//       print('❌ Erro ao obter localização: $e');
//     }
    
//     return {
//       'latitude': null,
//       'longitude': null,
//       'error': 'Location not available'
//     };
//   }

//   // Simula obtenção de IP
//   static Future<String?> _getIPAddress() async {
//     return 'Mobile-Network';
//   }

//   // MÉTODOS PARA DASHBOARD DE SEGURANÇA
  
//   static Future<List<Map<String, dynamic>>> getRecentSecurityEvents({int limit = 10}) async {
//     try {
//       final query = await FirebaseFirestore.instance
//           .collection('security_events')
//           .limit(limit)
//           .get();

//       final events = query.docs.map((doc) {
//         final data = doc.data();
//         return {
//           'id': doc.id,
//           ...data,
//           'timestamp': (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
//         };
//       }).toList();

//       // Ordena por timestamp
//       events.sort((a, b) => (b['timestamp'] as DateTime).compareTo(a['timestamp'] as DateTime));

//       return events;
//     } catch (e) {
//       print('❌ Erro ao buscar eventos: $e');
//       return [];
//     }
//   }

//   static Future<Map<String, dynamic>> getUserSecurityStatus(String email) async {
//     try {
//       print('🔍 Buscando eventos para: $email');
      
//       final recentEvents = await FirebaseFirestore.instance
//           .collection('security_events')
//           .where('userEmail', isEqualTo: email)
//           .limit(15)
//           .get();

//       print('📊 Encontrados ${recentEvents.docs.length} eventos para $email');

//       final events = recentEvents.docs.map((doc) {
//         final data = doc.data();
//         return {
//           'id': doc.id,
//           ...data,
//           'timestamp': (data['timestamp'] as Timestamp?)?.toDate() ?? 
//                       (data['created_at'] != null ? DateTime.parse(data['created_at']) : DateTime.now()),
//         };
//       }).toList();

//       // Ordena por timestamp
//       events.sort((a, b) => (b['timestamp'] as DateTime).compareTo(a['timestamp'] as DateTime));

//       final failedAttempts = events.where((e) => e['success'] == false).length;
//       final successfulLogins = events.where((e) => e['success'] == true).length;

//       print('✅ $email: ${events.length} eventos ($successfulLogins sucessos, $failedAttempts falhas)');

//       return {
//         'email': email,
//         'total_events': events.length,
//         'failed_attempts': failedAttempts,
//         'successful_logins': successfulLogins,
//         'last_login': events.isNotEmpty ? events.first['timestamp'] : null,
//         'risk_level': failedAttempts >= 3 ? 'High' : failedAttempts >= 1 ? 'Medium' : 'Low',
//         'recent_events': events,
//       };
//     } catch (e) {
//       print('❌ Erro ao obter status de segurança: $e');
//       return {
//         'email': email,
//         'error': 'Failed to load security status',
//         'risk_level': 'Unknown',
//         'total_events': 0,
//         'failed_attempts': 0,
//         'successful_logins': 0,
//         'recent_events': [],
//       };
//     }
//   }
// }
