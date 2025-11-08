import 'dart:convert';
import 'dart:async';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../core/theme/app_colors.dart';
import '../service/hibp_service.dart';

/// Versão melhorada da tela de vazamentos com integração completa HIBP
class LeakCheckerScreenEnhanced extends StatefulWidget {
  final Function(int, String) changeTab;
  const LeakCheckerScreenEnhanced({super.key, required this.changeTab});

  @override
  State<LeakCheckerScreenEnhanced> createState() =>
      _LeakCheckerScreenEnhancedState();
}

class _LeakCheckerScreenEnhancedState
    extends State<LeakCheckerScreenEnhanced> {
  final TextEditingController _dataController = TextEditingController();
  String _selectedType = 'Email';
  String _resultMessage = '';
  bool _isLoading = false;

  // Dados detalhados dos vazamentos
  List<BreachData> _breaches = [];
  List<PasteData> _pastes = [];
  bool _showDetails = false;

  @override
  void dispose() {
    _dataController.dispose();
    super.dispose();
  }

  Future<void> _verifyData() async {
    final data = _dataController.text.trim();
    if (data.isEmpty) {
      _showError('Digite algo para verificar.');
      return;
    }

    setState(() {
      _isLoading = true;
      _resultMessage = '';
      _showDetails = false;
      _breaches = [];
      _pastes = [];
    });

    try {
      switch (_selectedType) {
        case 'Email':
          await _checkEmailLeakDetailed(data);
          break;
        case 'Senha':
          await _checkPasswordLeak(data);
          break;
        // Adicione outras verificações aqui se necessário
      }
    } catch (e) {
      _showError('Erro: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (mounted) {
      setState(() {
        _resultMessage = '❌ $message';
        _showDetails = false;
      });
    }
  }

  /// Verifica senha usando k-Anonymity (Pwned Passwords API)
  Future<void> _checkPasswordLeak(String password) async {
    final sha1Hash =
        sha1.convert(utf8.encode(password)).toString().toUpperCase();
    final prefix = sha1Hash.substring(0, 5);
    final suffix = sha1Hash.substring(5);
    final url = Uri.parse('https://api.pwnedpasswords.com/range/$prefix');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final hashes = response.body.split('\n');
      final found = hashes.any((line) => line.split(':')[0] == suffix);
      if (found) {
        final count = hashes
            .firstWhere((line) => line.split(':')[0] == suffix)
            .split(':')[1];
        _resultMessage =
            '⚠️ Sua senha foi encontrada em vazamentos ($count vezes).';
        _showHelpToast();
      } else {
        _resultMessage = '✅ Sua senha NÃO foi encontrada em vazamentos!';
      }
    } else {
      _resultMessage = '❌ Erro ao consultar a senha.';
    }
    setState(() {});
  }

  /// Verifica email usando Have I Been Pwned API com detalhes completos
  Future<void> _checkEmailLeakDetailed(String email) async {
    try {
      // Busca breaches
      final breaches = await HIBPService.checkEmailBreaches(email);

      // Busca pastes (requer API key paga)
      List<PasteData> pastes = [];
      try {
        pastes = await HIBPService.checkEmailPastes(email);
      } catch (e) {
        // Se der erro no paste, continua sem ele
        // Silenciosamente ignora erro de pastes (pode não estar disponível)
      }

      setState(() {
        _breaches = breaches;
        _pastes = pastes;
      });

      if (breaches.isEmpty && pastes.isEmpty) {
        _resultMessage = '✅ Email seguro';
        _showDetails = false;
      } else {
        _resultMessage = '⚠️ Email comprometido';
        _showDetails = true;
        _showHelpToast();
      }

      setState(() {});
    } catch (e) {
      _showError(e.toString());
    }
  }

  void _showHelpToast() {
    CustomToast.show(
      context: context,
      message: 'Vazamento Detectado! Deseja conversar com o assistente?',
      onConfirm: () {
        String autoMsg = "Minha senha vazou, o que posso fazer?";
        if (_selectedType == 'Email') {
          autoMsg = "Meu email vazou em ${_breaches.length} sites, o que devo fazer?";
        }
        widget.changeTab(4, autoMsg);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final topSpacing = MediaQuery.of(context).size.height * (68 / 892);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: topSpacing),
              const Text(
                '<Vazamentos./>',
                style: TextStyle(
                    color: AppColors.primaryPurple,
                    fontSize: 22,
                    fontFamily: 'JetBrains Mono',
                    fontWeight: FontWeight.w400),
              ),
              const SizedBox(height: 48),

              // Card de verificação
              _VerificationCard(
                controller: _dataController,
                selectedType: _selectedType,
                onDropdownChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedType = val;
                      _resultMessage = '';
                      _showDetails = false;
                    });
                  }
                },
                isLoading: _isLoading,
                onVerify: _verifyData,
              ),

              const SizedBox(height: 24),

              // Resultados simplificados
              if (_showDetails && _breaches.isNotEmpty) ...[
                const SizedBox(height: 24),

                // Card com número de vazamentos EM DESTAQUE
                _SimpleBreachCountCard(
                  breachCount: _breaches.length,
                  pasteCount: _pastes.length,
                ),

                const SizedBox(height: 24),

                // Lista SIMPLES dos sites onde vazou
                _SimpleBreachListCard(breaches: _breaches),
              ] else if (_resultMessage.isNotEmpty) ...[
                // Mensagem quando NÃO há vazamentos
                const SizedBox(height: 24),
                _SafeEmailCard(),
              ],

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// ================================================================
// WIDGETS AUXILIARES
// ================================================================

class _VerificationCard extends StatelessWidget {
  final TextEditingController controller;
  final String selectedType;
  final ValueChanged<String?> onDropdownChanged;
  final bool isLoading;
  final VoidCallback onVerify;

  const _VerificationCard({
    required this.controller,
    required this.selectedType,
    required this.onDropdownChanged,
    required this.isLoading,
    required this.onVerify,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2B3242),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x334D5A7A)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Digite o $selectedType para verificar...',
                    hintStyle: const TextStyle(color: Colors.white54),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _CustomDropdown(
                value: selectedType,
                onChanged: onDropdownChanged,
                items: const ['Email', 'Senha'],
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: isLoading ? null : onVerify,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryPurple,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Verificar',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomDropdown extends StatelessWidget {
  final String value;
  final ValueChanged<String?> onChanged;
  final List<String> items;

  const _CustomDropdown(
      {required this.value, required this.onChanged, required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.primaryPurple.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryPurple),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          onChanged: onChanged,
          dropdownColor: const Color(0xFF2A2F3E),
          icon: const Icon(Icons.keyboard_arrow_down,
              color: AppColors.primaryPurple),
          style: const TextStyle(color: Colors.white, fontFamily: 'Poppins'),
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final String resultMessage;
  final String selectedType;
  const _StatusBanner(
      {required this.resultMessage, required this.selectedType});

  @override
  Widget build(BuildContext context) {
    final bool isLeaked = resultMessage.contains('⚠️');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isLeaked ? const Color(0xB2834748) : const Color(0xAD3251A3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color:
                isLeaked ? const Color(0xFFD07274) : const Color(0xFF678EE6)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
              isLeaked
                  ? Icons.warning_amber_rounded
                  : Icons.check_circle_outline,
              color:
                  isLeaked ? const Color(0xFFD64344) : const Color(0xFFB8CBF4),
              size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              resultMessage,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontWeight: FontWeight.w600,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Seção que mostra informações sobre pastes
class _PastesSection extends StatelessWidget {
  final List<PasteData> pastes;

  const _PastesSection({required this.pastes});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.description, color: AppColors.primaryPurple),
            SizedBox(width: 8),
            Text(
              'Aparições em Pastes Públicos',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF2B3242),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFD07274)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Seu email foi encontrado em ${pastes.length} paste${pastes.length > 1 ? 's' : ''} público${pastes.length > 1 ? 's' : ''}.',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              ...pastes.take(5).map((paste) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Icon(Icons.circle,
                            size: 8, color: AppColors.primaryPurple),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${paste.source}: ${paste.title ?? paste.id} ${paste.date != null ? '(${paste.date!.year})' : ''}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
              if (pastes.length > 5)
                Text(
                  'E mais ${pastes.length - 5} pastes...',
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ================================================================
// NOVOS WIDGETS SIMPLIFICADOS
// ================================================================

/// Card com número de vazamentos EM DESTAQUE
class _SimpleBreachCountCard extends StatelessWidget {
  final int breachCount;
  final int pasteCount;

  const _SimpleBreachCountCard({
    required this.breachCount,
    required this.pasteCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFD64344),
            const Color(0xFF834748),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD07274), width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD64344).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Ícone de alerta
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: Colors.white,
              size: 48,
            ),
          ),

          const SizedBox(height: 24),

          // Número de vazamentos - BEM GRANDE
          Text(
            breachCount.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 72,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
              height: 1,
            ),
          ),

          const SizedBox(height: 8),

          // Texto explicativo
          Text(
            breachCount == 1 ? 'Vazamento Encontrado' : 'Vazamentos Encontrados',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
            ),
          ),

          // Pastes (se houver)
          if (pasteCount > 0) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '+ $pasteCount paste${pasteCount > 1 ? 's' : ''} público${pasteCount > 1 ? 's' : ''}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Lista SIMPLES dos sites onde vazou
class _SimpleBreachListCard extends StatelessWidget {
  final List<BreachData> breaches;

  const _SimpleBreachListCard({required this.breaches});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2B3242),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x334D5A7A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título
          const Row(
            children: [
              Icon(Icons.business, color: AppColors.primaryPurple, size: 20),
              SizedBox(width: 8),
              Text(
                'Onde seu email foi vazado:',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Lista simples de sites
          ...breaches.map((breach) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    // Bullet point
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD64344),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Nome do site
                    Expanded(
                      child: Text(
                        breach.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),

                    // Ano
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        breach.year.toString(),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                    // Badge verificado (se for)
                    if (breach.isVerified) ...[
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.verified,
                        color: Colors.green,
                        size: 16,
                      ),
                    ],
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

/// Card quando email está SEGURO
class _SafeEmailCard extends StatelessWidget {
  const _SafeEmailCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF3251A3),
            const Color(0xFF2A4080),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF678EE6), width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3251A3).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Ícone de sucesso
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_outline,
              color: Colors.white,
              size: 48,
            ),
          ),

          const SizedBox(height: 24),

          // Mensagem
          const Text(
            'Email Seguro!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
            ),
          ),

          const SizedBox(height: 12),

          Text(
            'Seu email não foi encontrado em nenhum vazamento conhecido.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 16,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }
}

class CustomToast {
  static void show({
    required BuildContext context,
    required String message,
    required VoidCallback onConfirm,
  }) {
    final scaffold = ScaffoldMessenger.of(context);
    scaffold.hideCurrentSnackBar();

    final snackBar = SnackBar(
      content: Row(
        children: [
          Expanded(
              child:
                  Text(message, style: const TextStyle(color: Colors.white))),
          TextButton(
            onPressed: () {
              scaffold.hideCurrentSnackBar();
              onConfirm();
            },
            child: const Text('Sim',
                style: TextStyle(
                    color: AppColors.primaryPurple,
                    fontWeight: FontWeight.bold)),
          ),
          TextButton(
            onPressed: () => scaffold.hideCurrentSnackBar(),
            child: const Text('Não', style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
      backgroundColor: const Color(0xFF2B3242),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 90, left: 16, right: 16),
      duration: const Duration(seconds: 8),
    );

    scaffold.showSnackBar(snackBar);
  }
}
