import 'package:flutter/material.dart';
import '../service/hibp_service.dart';
import '../core/theme/app_colors.dart';
import 'package:intl/intl.dart';

/// Card que exibe detalhes de um vazamento específico
class BreachDetailCard extends StatelessWidget {
  final BreachData breach;

  const BreachDetailCard({super.key, required this.breach});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2B3242),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: breach.isSensitive
              ? const Color(0xFFD07274)
              : const Color(0x334D5A7A),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header com nome e badges
          Row(
            children: [
              Expanded(
                child: Text(
                  breach.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
              if (breach.isVerified)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified, size: 14, color: Colors.green),
                      SizedBox(width: 4),
                      Text(
                        'Verificado',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              if (breach.isSensitive) const SizedBox(width: 8),
              if (breach.isSensitive)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.warning, size: 14, color: Colors.red),
                      SizedBox(width: 4),
                      Text(
                        'Sensível',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(height: 12),

          // Informações principais
          _InfoRow(
            icon: Icons.language,
            label: 'Site',
            value: breach.domain.isNotEmpty ? breach.domain : 'N/A',
          ),
          const SizedBox(height: 8),
          _InfoRow(
            icon: Icons.calendar_today,
            label: 'Data do vazamento',
            value: dateFormat.format(breach.breachDate),
          ),
          const SizedBox(height: 8),
          _InfoRow(
            icon: Icons.people,
            label: 'Contas afetadas',
            value: _formatNumber(breach.pwnCount),
          ),

          const SizedBox(height: 12),

          // Tipos de dados vazados
          const Text(
            'Dados comprometidos:',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: breach.dataClasses.map((dataClass) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryPurple.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.primaryPurple),
                ),
                child: Text(
                  dataClass,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),

          // Descrição (expansível)
          if (breach.description.isNotEmpty) ...[
            const SizedBox(height: 12),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: const Text(
                'Ver descrição completa',
                style: TextStyle(
                  color: AppColors.primaryPurple,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              iconColor: AppColors.primaryPurple,
              collapsedIconColor: AppColors.primaryPurple,
              children: [
                Text(
                  _stripHtml(breach.description),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  String _stripHtml(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&quot;', '"')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>');
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primaryPurple),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

/// Card de resumo estatístico dos vazamentos
class BreachSummaryCard extends StatelessWidget {
  final List<BreachData> breaches;
  final List<PasteData>? pastes;

  const BreachSummaryCard({
    super.key,
    required this.breaches,
    this.pastes,
  });

  @override
  Widget build(BuildContext context) {
    final stats = HIBPService.getBreachStatistics(breaches);
    final totalBreaches = stats['total'] as int;
    final mostRecent = stats['mostRecent'] as BreachData?;
    final pasteCount = pastes?.length ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF834748).withOpacity(0.7),
            const Color(0xFF6B3B3C).withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD07274)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.warning_amber_rounded,
                  color: Color(0xFFD64344), size: 28),
              SizedBox(width: 12),
              Text(
                'Alerta de Segurança',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Estatísticas
          _StatRow(
            label: 'Total de vazamentos',
            value: totalBreaches.toString(),
            icon: Icons.broken_image,
          ),
          if (pasteCount > 0) ...[
            const SizedBox(height: 8),
            _StatRow(
              label: 'Aparições em pastes',
              value: pasteCount.toString(),
              icon: Icons.description,
            ),
          ],
          if (mostRecent != null) ...[
            const SizedBox(height: 8),
            _StatRow(
              label: 'Vazamento mais recente',
              value: '${mostRecent.title} (${mostRecent.year})',
              icon: Icons.history,
            ),
          ],

          const SizedBox(height: 16),

          // Tipos de dados comprometidos
          const Text(
            'Tipos de dados comprometidos:',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            (stats['dataTypes'] as List<String>).join(', '),
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.white70),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
