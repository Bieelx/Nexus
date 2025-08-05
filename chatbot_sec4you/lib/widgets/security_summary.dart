import 'package:flutter/material.dart';
import '../models/security_event.dart' as SecurityModels;
import '../service/eventlog_service.dart';

class SecuritySummary extends StatefulWidget {
  @override
  _SecuritySummaryState createState() => _SecuritySummaryState();
}

class _SecuritySummaryState extends State<SecuritySummary> {
  SecurityModels.SecuritySummary? summaryData;
  bool isLoading = true;
  DateTime lastUpdate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadSecurityData();
  }

  Future<void> _loadSecurityData() async {
    try {
      final data = await EventLogService.getTodaysSummary();
      
      setState(() {
        summaryData = data;
        isLoading = false;
        lastUpdate = DateTime.now();
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Verificando segurança...'),
          ],
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSecurityStatus(),
          SizedBox(height: 24),
          _buildThreatsSummary(),
          SizedBox(height: 24),
          _buildQuickActions(),
          SizedBox(height: 16),
          _buildLastUpdate(),
        ],
      ),
    );
  }

  Widget _buildSecurityStatus() {
    bool isSecure = summaryData == null || summaryData!.criticalEvents == 0;
    
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isSecure ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSecure ? Colors.green : Colors.red,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isSecure ? Icons.shield : Icons.warning,
            size: 48,
            color: isSecure ? Colors.green : Colors.red,
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isSecure ? 'Dispositivo Protegido' : 'Atenção Necessária',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isSecure ? Colors.green : Colors.red,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  isSecure 
                    ? 'Seu dispositivo está seguro e protegido'
                    : 'Detectamos algumas ameaças que precisam de atenção',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThreatsSummary() {
    if (summaryData == null) return Container();

    int totalThreats = summaryData!.criticalEvents + summaryData!.highEvents;
    int blockedThreats = summaryData!.mediumEvents + summaryData!.lowEvents;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Resumo de Hoje',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'Ameaças Bloqueadas',
                blockedThreats.toString(),
                Icons.block,
                Colors.green,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _buildSummaryCard(
                'Alertas Importantes',
                totalThreats.toString(),
                Icons.warning,
                totalThreats > 0 ? Colors.orange : Colors.green,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ações Rápidas',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                'Verificar Agora',
                Icons.refresh,
                Colors.blue,
                _loadSecurityData,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                'Dicas de Segurança',
                Icons.lightbulb,
                Colors.orange,
                _showSecurityTips,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(String text, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            SizedBox(height: 8),
            Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLastUpdate() {
    String timeAgo = _getTimeAgo(lastUpdate);
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.access_time, size: 16, color: Colors.grey),
        SizedBox(width: 4),
        Text(
          'Última verificação: $timeAgo',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'agora';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}min atrás';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h atrás';
    } else {
      return '${difference.inDays}d atrás';
    }
  }

  void _showSecurityTips() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.lightbulb, color: Colors.orange),
            SizedBox(width: 8),
            Text('Dicas de Segurança'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTip('🔒', 'Use senhas fortes e únicas'),
            _buildTip('🔄', 'Mantenha seu sistema atualizado'),
            _buildTip('📧', 'Cuidado com emails suspeitos'),
            _buildTip('🛡️', 'Ative a autenticação em duas etapas'),
            _buildTip('💾', 'Faça backups regulares'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Entendi'),
          ),
        ],
      ),
    );
  }

  Widget _buildTip(String emoji, String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(emoji, style: TextStyle(fontSize: 16)),
          SizedBox(width: 8),
          Expanded(child: Text(text, style: TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}