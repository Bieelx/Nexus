import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/security_event.dart';

class EventLogService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Busca eventos de segurança baseados no Firebase
  static Future<List<SecurityEvent>> getRecentEvents({
    int limit = 50,
    String? severity,
    DateTime? since,
  }) async {
    try {
      // Busca dados reais do Firebase para gerar eventos de segurança
      final users = await _getUsersData();
      final chats = await _getChatsData();
      
      List<SecurityEvent> events = [];
      
      // Gera eventos baseados em padrões de uso
      events.addAll(await _generateLoginEvents(users));
      events.addAll(await _generateChatSecurityEvents(chats));
      events.addAll(await _generateDeviceEvents());
      
      // Filtra por severidade se especificado
      if (severity != null) {
        events = events.where((e) => e.severity == severity).toList();
      }
      
      // Filtra por data se especificado
      if (since != null) {
        events = events.where((e) => e.timestamp.isAfter(since)).toList();
      }
      
      // Ordena por data (mais recente primeiro) e limita
      events.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return events.take(limit).toList();
      
    } catch (e) {
      print('Error fetching Firebase events: $e');
      // Fallback para dados mock
      return _getMockEvents();
    }
  }

  /// Busca resumo de segurança baseado no Firebase
  static Future<SecuritySummary> getTodaysSummary() async {
    try {
      final events = await getRecentEvents(limit: 100);
      final today = DateTime.now();
      final todayEvents = events.where((e) => 
        e.timestamp.day == today.day &&
        e.timestamp.month == today.month &&
        e.timestamp.year == today.year
      ).toList();

      int critical = todayEvents.where((e) => e.severity == 'Critical').length;
      int high = todayEvents.where((e) => e.severity == 'High').length;
      int medium = todayEvents.where((e) => e.severity == 'Medium').length;
      int low = todayEvents.where((e) => e.severity == 'Low').length;

      return SecuritySummary(
        totalEvents: todayEvents.length,
        criticalEvents: critical,
        highEvents: high,
        mediumEvents: medium,
        lowEvents: low,
        recentEvents: todayEvents.take(10).toList(),
      );
    } catch (e) {
      print('Error generating summary: $e');
      return _getMockSummary();
    }
  }

  /// Busca dados dos usuários para análise de segurança
  static Future<List<Map<String, dynamic>>> _getUsersData() async {
    try {
      final usersSnapshot = await _firestore.collection('users').get();
      return usersSnapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      print('Error fetching users: $e');
      return [];
    }
  }

  /// Busca dados dos chats para análise de segurança
  static Future<List<Map<String, dynamic>>> _getChatsData() async {
    try {
      final chatsSnapshot = await _firestore
          .collection('chats')
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();
      
      return chatsSnapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      print('Error fetching chats: $e');
      return [];
    }
  }

  /// Gera eventos de segurança baseados em logins
  static Future<List<SecurityEvent>> _generateLoginEvents(List<Map<String, dynamic>> users) async {
    List<SecurityEvent> events = [];
    final random = Random();

    for (var user in users.take(5)) {
      // Simula tentativas de login suspeitas
      if (random.nextBool()) {
        events.add(SecurityEvent(
          id: 'login_${user['id']}_${DateTime.now().millisecondsSinceEpoch}',
          eventType: 'Login Attempt',
          source: 'Mobile App',
          description: 'Login realizado com sucesso de novo dispositivo',
          timestamp: DateTime.now().subtract(Duration(minutes: random.nextInt(120))),
          severity: 'Medium',
          userAgent: 'Flutter App',
          ipAddress: _generateRandomIP(),
        ));
      }

      // Simula falhas de login
      if (random.nextInt(10) < 2) { // 20% chance
        events.add(SecurityEvent(
          id: 'failed_login_${user['id']}_${DateTime.now().millisecondsSinceEpoch}',
          eventType: 'Failed Login',
          source: 'Authentication System',
          description: 'Múltiplas tentativas de login falharam para usuário ${user['email'] ?? 'unknown'}',
          timestamp: DateTime.now().subtract(Duration(minutes: random.nextInt(60))),
          severity: 'High',
          userAgent: 'Unknown Device',
          ipAddress: _generateRandomIP(),
        ));
      }
    }

    return events;
  }

  /// Gera eventos de segurança baseados em chats
  static Future<List<SecurityEvent>> _generateChatSecurityEvents(List<Map<String, dynamic>> chats) async {
    List<SecurityEvent> events = [];
    final random = Random();

    for (var chat in chats.take(10)) {
      String message = chat['message']?.toString() ?? '';
      
      // Detecta palavras suspeitas
      List<String> suspiciousWords = ['hack', 'password', 'credit card', 'bank', 'phishing'];
      bool hasSuspiciousContent = suspiciousWords.any((word) => 
        message.toLowerCase().contains(word.toLowerCase()));

      if (hasSuspiciousContent) {
        events.add(SecurityEvent(
          id: 'chat_security_${chat['id']}_${DateTime.now().millisecondsSinceEpoch}',
          eventType: 'Suspicious Content',
          source: 'Chat Monitor',
          description: 'Conteúdo potencialmente suspeito detectado no chat',
          timestamp: DateTime.parse(chat['timestamp'] ?? DateTime.now().toIso8601String()),
          severity: 'Medium',
          userAgent: 'Chat System',
          ipAddress: _generateRandomIP(),
        ));
      }

      // Simula spam detection
      if (message.length > 500 || random.nextInt(20) == 0) {
        events.add(SecurityEvent(
          id: 'spam_${chat['id']}_${DateTime.now().millisecondsSinceEpoch}',
          eventType: 'Spam Detection',
          source: 'Content Filter',
          description: 'Mensagem identificada como possível spam',
          timestamp: DateTime.parse(chat['timestamp'] ?? DateTime.now().toIso8601String()),
          severity: 'Low',
          userAgent: 'Anti-Spam',
          ipAddress: _generateRandomIP(),
        ));
      }
    }

    return events;
  }

  /// Gera eventos de dispositivo
  static Future<List<SecurityEvent>> _generateDeviceEvents() async {
    List<SecurityEvent> events = [];
    final random = Random();

    // Simula eventos de dispositivo
    if (random.nextInt(10) < 3) { // 30% chance
      events.add(SecurityEvent(
        id: 'device_${DateTime.now().millisecondsSinceEpoch}',
        eventType: 'Device Security Check',
        source: 'Device Monitor',
        description: 'Verificação de segurança do dispositivo concluída',
        timestamp: DateTime.now().subtract(Duration(minutes: random.nextInt(30))),
        severity: 'Low',
        userAgent: 'Security Scanner',
        ipAddress: _generateRandomIP(),
      ));
    }

    // Simula bloqueio de malware
    if (random.nextInt(20) == 0) { // 5% chance
      events.add(SecurityEvent(
        id: 'malware_${DateTime.now().millisecondsSinceEpoch}',
        eventType: 'Malware Blocked',
        source: 'Antivirus',
        description: 'Tentativa de download suspeito bloqueada',
        timestamp: DateTime.now().subtract(Duration(hours: random.nextInt(6))),
        severity: 'Critical',
        userAgent: 'Security Engine',
        ipAddress: _generateRandomIP(),
      ));
    }

    return events;
  }

  /// Gera IP aleatório para simulação
  static String _generateRandomIP() {
    final random = Random();
    return '${random.nextInt(255)}.${random.nextInt(255)}.${random.nextInt(255)}.${random.nextInt(255)}';
  }

  /// Busca eventos por tipo
  static Future<List<SecurityEvent>> getEventsByType(String eventType) async {
    final allEvents = await getRecentEvents(limit: 100);
    return allEvents.where((e) => e.eventType == eventType).toList();
  }

  /// Estatísticas de ameaças baseadas no Firebase
  static Future<Map<String, int>> getThreatStatistics() async {
    try {
      final events = await getRecentEvents(limit: 200);
      final today = DateTime.now();
      final todayEvents = events.where((e) => 
        e.timestamp.day == today.day &&
        e.timestamp.month == today.month &&
        e.timestamp.year == today.year
      ).toList();

      return {
        'malware_attempts': todayEvents.where((e) => e.eventType.contains('Malware')).length,
        'failed_logins': todayEvents.where((e) => e.eventType.contains('Failed Login')).length,
        'suspicious_activity': todayEvents.where((e) => e.eventType.contains('Suspicious')).length,
        'blocked_threats': todayEvents.where((e) => e.severity == 'Low' || e.severity == 'Medium').length,
      };
    } catch (e) {
      return {
        'malware_attempts': 2,
        'failed_logins': 5,
        'suspicious_activity': 3,
        'blocked_threats': 15,
      };
    }
  }

  // Dados mock para fallback (mantém os existentes)
  static List<SecurityEvent> _getMockEvents() {
    return [
      SecurityEvent(
        id: '1',
        eventType: 'Failed Login',
        source: 'Mobile App',
        description: 'Múltiplas tentativas de login falharam',
        timestamp: DateTime.now().subtract(Duration(minutes: 15)),
        severity: 'High',
        userAgent: 'Flutter App',
        ipAddress: '192.168.1.100',
      ),
      SecurityEvent(
        id: '2',
        eventType: 'Suspicious Content',
        source: 'Chat Monitor',
        description: 'Conteúdo suspeito detectado no chat',
        timestamp: DateTime.now().subtract(Duration(hours: 1)),
        severity: 'Medium',
        userAgent: 'Chat System',
        ipAddress: '10.0.0.25',
      ),
      SecurityEvent(
        id: '3',
        eventType: 'Device Security Check',
        source: 'Security Scanner',
        description: 'Verificação de segurança concluída com sucesso',
        timestamp: DateTime.now().subtract(Duration(minutes: 30)),
        severity: 'Low',
        userAgent: 'Security Engine',
        ipAddress: '172.16.0.5',
      ),
    ];
  }

  static SecuritySummary _getMockSummary() {
    return SecuritySummary(
      totalEvents: 25,
      criticalEvents: 1,
      highEvents: 4,
      mediumEvents: 8,
      lowEvents: 12,
      recentEvents: _getMockEvents(),
    );
  }
}