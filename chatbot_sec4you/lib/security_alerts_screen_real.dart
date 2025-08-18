import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'service/security_event_service.dart';

class SecurityAlertsScreenReal extends StatefulWidget {
  const SecurityAlertsScreenReal({super.key});

  @override
  State<SecurityAlertsScreenReal> createState() => _SecurityAlertsScreenRealState();
}

class _SecurityAlertsScreenRealState extends State<SecurityAlertsScreenReal> {
  List<Map<String, dynamic>> securityEvents = [];
  bool isLoading = true;
  String? error;
  String? currentUserEmail;

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
  }

  // Obtém o usuário atual logado
  void _getCurrentUser() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      currentUserEmail = user.email;
      print('👤 Usuário logado: $currentUserEmail');
      _loadSecurityEvents();
    } else {
      setState(() {
        error = 'Usuário não logado';
        isLoading = false;
      });
    }
  }

  Future<void> _loadSecurityEvents() async {
    if (currentUserEmail == null) return;
    
    try {
      print('📊 Carregando eventos de segurança para: $currentUserEmail');
      
      // Busca apenas eventos do usuário logado
      final userStatus = await SecurityEventService.getUserSecurityStatus(currentUserEmail!);
      final events = userStatus['recent_events'] as List<dynamic>? ?? [];
      
      setState(() {
        securityEvents = events.cast<Map<String, dynamic>>();
        isLoading = false;
      });
      print('✅ ${events.length} eventos carregados para $currentUserEmail');
      
      // Debug: mostra eventos do usuário
      for (var event in events.take(3)) {
        print('🔍 Evento do usuário: ${event['eventType']} - ${event['userEmail']} - ${event['success']}');
      }
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
      print('❌ Erro ao carregar eventos para $currentUserEmail: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF7F2AB1);
    const bg = Color(0xFF0D0D0D);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text(
          currentUserEmail != null 
            ? 'Seus Alertas de Segurança'
            : 'Alertas de Segurança',
          style: TextStyle(
            color: Color(0xFFFAF9F6),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Color(0xFF1A1A1A),
        iconTheme: IconThemeData(color: Color(0xFFFAF9F6)),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadSecurityEvents,
            tooltip: 'Atualizar eventos',
          ),
          if (currentUserEmail != null)
            IconButton(
              icon: Icon(Icons.person),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Visualizando eventos de: $currentUserEmail'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              tooltip: 'Usuário: $currentUserEmail',
            ),
        ],
      ),
      body: isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: purple),
                  SizedBox(height: 16),
                  Text(
                    'Carregando eventos de segurança...',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ],
              ),
            )
          : error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, color: Colors.red, size: 64),
                      SizedBox(height: 16),
                      Text(
                        'Erro ao carregar eventos',
                        style: TextStyle(color: Colors.red, fontSize: 18),
                      ),
                      SizedBox(height: 8),
                      Text(
                        error!,
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadSecurityEvents,
                        child: Text('Tentar Novamente'),
                      ),
                    ],
                  ),
                )
              : securityEvents.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.security, color: purple, size: 64),
                          SizedBox(height: 16),
                          Text(
                            'Nenhum evento de segurança encontrado',
                            style: TextStyle(color: Colors.white, fontSize: 18),
                          ),
                          SizedBox(height: 8),
                          Text(
                            currentUserEmail != null 
                              ? 'Não há eventos registrados para: $currentUserEmail'
                              : 'Nenhum evento foi registrado ainda',
                            style: TextStyle(color: Colors.white70, fontSize: 14),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 16),
                          Text(
                            '✨ Isso é uma boa notícia!\nSignifica que não houve tentativas de login suspeitas.',
                            style: TextStyle(color: Colors.green, fontSize: 14),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: _loadSecurityEvents,
                            icon: Icon(Icons.refresh),
                            label: Text('Verificar Novamente'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: purple,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSummaryCard(),
                          SizedBox(height: 24),
                          _buildEventsList(),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildSummaryCard() {
    int totalEvents = securityEvents.length;
    int failedLogins = securityEvents.where((e) => e['success'] == false).length;
    int successfulLogins = securityEvents.where((e) => e['success'] == true).length;
    
    Color statusColor = failedLogins > 3 ? Colors.red : Colors.green;
    String statusText = failedLogins > 3 ? 'Atenção Necessária' : 'Sistema Seguro';

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                failedLogins > 3 ? Icons.warning : Icons.shield,
                color: statusColor,
                size: 32,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Monitoramento em tempo real',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatCard('Total', totalEvents.toString(), Color(0xFF7F2AB1)),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildStatCard('Falhadas', failedLogins.toString(), Colors.red),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildStatCard('Sucessos', successfulLogins.toString(), Colors.green),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color(0xFF0D0D0D),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildEventsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Eventos Recentes (${securityEvents.length})',
          style: TextStyle(
            color: Color(0xFFFAF9F6),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 12),
        ...securityEvents.map((event) => _buildEventCard(event)),
      ],
    );
  }

  Widget _buildEventCard(Map<String, dynamic> event) {
    bool success = event['success'] ?? false;
    Color severityColor = success ? Colors.green : Colors.red;
    String severity = success ? 'Success' : (event['severity'] ?? 'High');
    
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: severityColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: severityColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  severity,
                  style: TextStyle(
                    color: severityColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              Spacer(),
              Text(
                _formatTimestamp(event['timestamp']),
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            event['eventType'] ?? 'Login Event',
            style: TextStyle(
              color: Color(0xFFFAF9F6),
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Usuário: ${event['userEmail'] ?? 'Unknown'}',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          if (event['errorMessage'] != null) ...[
            SizedBox(height: 4),
            Text(
              'Erro: ${event['errorMessage']}',
              style: TextStyle(color: Colors.red.shade300, fontSize: 12),
            ),
          ],
          SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.computer, size: 16, color: Colors.grey),
              SizedBox(width: 4),
              Text(
                event['source'] ?? 'Flutter App',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              Spacer(),
              Icon(Icons.location_on, size: 16, color: Colors.grey),
              SizedBox(width: 4),
              Text(
                event['ipAddress'] ?? 'Mobile',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    DateTime dateTime;
    
    if (timestamp == null) {
      dateTime = DateTime.now();
    } else if (timestamp is String) {
      dateTime = DateTime.tryParse(timestamp) ?? DateTime.now();
    } else {
      dateTime = DateTime.now();
    }
    
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Agora';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}min atrás';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h atrás';
    } else {
      return '${difference.inDays}d atrás';
    }
  }
}
