import 'package:cloud_firestore/cloud_firestore.dart';

class SecurityEventService {
  // Registra tentativa de login (sucesso ou falha)
  static Future<void> logLoginAttempt({
    required String email,
    required bool success,
    String? errorMessage,
  }) async {
    print('🔐 ${success ? "Login realizado" : "Falha no login"}: $email');
    
    try {
      // Cria evento básico
      final eventData = {
        'userEmail': email,
        'success': success,
        'errorMessage': errorMessage,
        'timestamp': DateTime.now().toIso8601String(),
        'eventType': success ? 'LOGIN_SUCCESS' : 'LOGIN_FAILURE',
        'source': 'SecurApp Mobile',
      };

      // Salva no Firebase
      await _saveToFirebase(eventData);
      print('✅ Evento registrado!');

    } catch (e) {
      print('❌ Erro ao registrar evento: $e');
    }
  }

  // Salva no Firebase
  static Future<void> _saveToFirebase(Map<String, dynamic> eventData) async {
    try {
      await FirebaseFirestore.instance
          .collection('security_events')
          .add({
        ...eventData,
        'timestamp': FieldValue.serverTimestamp(),
      });
      
    } catch (e) {
      print('❌ Erro ao salvar: $e');
      throw e;
    }
  }

  // MÉTODOS PARA DASHBOARD DE SEGURANÇA
  
  static Future<List<Map<String, dynamic>>> getRecentSecurityEvents({int limit = 10}) async {
    try {
      final query = await FirebaseFirestore.instance
          .collection('security_events')
          .limit(limit)
          .get();

      final events = query.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
          'timestamp': (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
        };
      }).toList();

      // Ordena por timestamp
      events.sort((a, b) => (b['timestamp'] as DateTime).compareTo(a['timestamp'] as DateTime));

      return events;
    } catch (e) {
      print('❌ Erro ao buscar eventos: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>> getUserSecurityStatus(String email) async {
    try {
      final recentEvents = await FirebaseFirestore.instance
          .collection('security_events')
          .where('userEmail', isEqualTo: email)
          .limit(10)
          .get();

      final events = recentEvents.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
          'timestamp': (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
        };
      }).toList();

      // Ordena por timestamp
      events.sort((a, b) => (b['timestamp'] as DateTime).compareTo(a['timestamp'] as DateTime));

      final failedAttempts = events.where((e) => e['success'] == false).length;
      final successfulLogins = events.where((e) => e['success'] == true).length;

      return {
        'email': email,
        'total_events': events.length,
        'failed_attempts': failedAttempts,
        'successful_logins': successfulLogins,
        'recent_events': events,
      };
    } catch (e) {
      return {
        'email': email,
        'total_events': 0,
        'failed_attempts': 0,
        'successful_logins': 0,
        'recent_events': [],
      };
    }
  }
}
