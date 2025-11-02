class SecurityEvent {
  final String id;
  final String eventType;
  final String source;
  final String description;
  final DateTime timestamp;
  final String severity;
  final String userAgent;
  final String ipAddress;

  SecurityEvent({
    required this.id,
    required this.eventType,
    required this.source,
    required this.description,
    required this.timestamp,
    required this.severity,
    required this.userAgent,
    required this.ipAddress,
  });

  factory SecurityEvent.fromJson(Map<String, dynamic> json) {
    return SecurityEvent(
      id: json['id'] ?? '',
      eventType: json['event_type'] ?? '',
      source: json['source'] ?? '',
      description: json['description'] ?? '',
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      severity: json['severity'] ?? 'Low',
      userAgent: json['user_agent'] ?? '',
      ipAddress: json['ip_address'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'event_type': eventType,
      'source': source,
      'description': description,
      'timestamp': timestamp.toIso8601String(),
      'severity': severity,
      'user_agent': userAgent,
      'ip_address': ipAddress,
    };
  }
}

class SecuritySummary {
  final int totalEvents;
  final int criticalEvents;
  final int highEvents;
  final int mediumEvents;
  final int lowEvents;
  final List<SecurityEvent> recentEvents;

  SecuritySummary({
    required this.totalEvents,
    required this.criticalEvents,
    required this.highEvents,
    required this.mediumEvents,
    required this.lowEvents,
    required this.recentEvents,
  });

  factory SecuritySummary.fromJson(Map<String, dynamic> json) {
    return SecuritySummary(
      totalEvents: json['total_events'] ?? 0,
      criticalEvents: json['critical_events'] ?? 0,
      highEvents: json['high_events'] ?? 0,
      mediumEvents: json['medium_events'] ?? 0,
      lowEvents: json['low_events'] ?? 0,
      recentEvents: (json['recent_events'] as List?)
          ?.map((e) => SecurityEvent.fromJson(e))
          .toList() ?? [],
    );
  }
}