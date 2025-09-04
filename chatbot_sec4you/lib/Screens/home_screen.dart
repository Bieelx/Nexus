//Cores do app
import 'package:chatbot_sec4you/Screens/course_content.dart';
import 'package:chatbot_sec4you/Screens/course_screen.dart';

import '../../core/theme/app_colors.dart';

//widgets
import '../widgets/homeScreen/news_feed_widget.dart';
import '../widgets/homeScreen/notification_card.dart';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vector_math/vector_math_64.dart' show Matrix4;
import '../security_alerts_screen_real.dart';
import './profile_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? firstName;
  final bool _isMapSelected = true; // Adicionado para controlar o switch

  @override
  void initState() {
    super.initState();
    _loadFirstNameFromFirestore();
  }
  


  Future<void> _loadFirstNameFromFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .get();
      if (doc.exists && doc.data()?['nome'] != null) {
        setState(() {
          firstName = doc.data()!['nome'];
        });
      } else {
        setState(() {
          firstName = 'Usuário';
        });
      }
    } else {
      setState(() {
        firstName = 'Usuário';
      });
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: firstName == null
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Builder(
                        builder: (context) {
                          final media = MediaQuery.of(context);
                          const desiredTop = 67.0; // distância a partir do topo da tela
                          const outerLeftPad = 16.0; // já aplicado via Padding do Scaffold
                          final status = media.padding.top;
                          final topGap = (desiredTop - status - outerLeftPad).clamp(0.0, 200.0);

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: topGap),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Bem-vindo de volta',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 24,
                                            fontFamily: 'Poppins',
                                            fontWeight: FontWeight.w700,
                                            height: 1.2,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        // === fixed username without unwanted newline and with ellipsis ===
                                        Text(
                                          '<${(firstName ?? 'Usuário').trim()}/>',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          softWrap: false,
                                          style: const TextStyle(
                                            color: AppColors.primaryPurple,
                                            fontSize: 18,
                                            fontFamily: 'JetBrainsMono',
                                            fontWeight: FontWeight.w600,
                                            height: 1.2,
                                            letterSpacing: 0.2,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  InkWell(
                                    borderRadius: BorderRadius.circular(18),
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => const ProfileScreen(),
                                        ),
                                      );
                                    },
                                    child: const CircleAvatar(
                                      radius: 18,
                                      backgroundColor: AppColors.primaryPurple,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      // CARD DO CURSO
                      LayoutBuilder(
                        builder: (context, constraints) {
                          const baseW = 380.0;
                          const baseH = 162.0;
                          final w = constraints.maxWidth;
                          final scale = w / baseW;
                      
                          return InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              // Navega para a tela do curso
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => CourseScreen(
                                    content: CourseContent(
                                      courseTitle: 'Firewall',         
                                      moduleTitle: 'Capítulo 5',
                                      activityTitle: 'Atividade 5',
                                      description: 'Aprenda sobre firewalls e como configurá-los corretamente.',
                                      videoId: 'GOAEybxj4bQ',
                                    ),
                                  ),
                                ),
                              );
                            },
                            child: SizedBox(
                              width: w,
                              height: baseH * scale,
                              child: Stack(
                                children: [
                                  // Título "Continuar curso?"
                                  Positioned(
                                    left: 0,
                                    top: 0,
                                    child: Text(
                                      'Continuar curso?',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16 * scale,
                                        fontFamily: 'JetBrainsMono',
                                        fontWeight: FontWeight.w500,
                                        height: 1.38,
                                      ),
                                    ),
                                  ),
                                  // Cartão com gradiente (fundo)
                                  Positioned(
                                    left: 0,
                                    top: 30 * scale,
                                    child: Container(
                                      width: w,
                                      height: 132 * scale,
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          begin: Alignment(0.08, 0.68),
                                          end: Alignment(0.59, 0.69),
                                          colors: [Color(0xFF6638B6), Color(0xFF634A9E)],
                                        ),
                                        border: Border.all(width: 1, color: Color(0xFF6C52BB)),
                                        borderRadius: BorderRadius.circular(16 * scale),
                                      ),
                                    ),
                                  ),
                                  // Título do curso
                                  Positioned(
                                    left: 23 * scale,
                                    top: 60 * scale,
                                    child: Text(
                                      'Firewall',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 20 * scale,
                                        fontFamily: 'JetBrainsMono',
                                        fontWeight: FontWeight.w500,
                                        height: 1,
                                        letterSpacing: 0.2 * scale,
                                      ),
                                    ),
                                  ),
                                  // Subtítulo
                                  Positioned(
                                    left: 23 * scale,
                                    top: 77 * scale,
                                    child: Text(
                                      'Capítulo 5',
                                      style: TextStyle(
                                        color: Color(0xFFD5C4F3),
                                        fontSize: 12 * scale,
                                        fontFamily: 'JetBrainsMono',
                                        fontWeight: FontWeight.w500,
                                        height: 1.67,
                                        letterSpacing: 0.12 * scale,
                                      ),
                                    ),
                                  ),
                                  // Barra de progresso - trilho
                                  Positioned(
                                    left: 19 * scale,
                                    top: 109 * scale,
                                    child: Container(
                                      width: 343 * scale,
                                      height: 10 * scale,
                                      decoration: BoxDecoration(
                                        color: const Color(0xAF545252),
                                        borderRadius: BorderRadius.circular(100 * scale),
                                      ),
                                    ),
                                  ),
                                  // Barra de progresso - preenchimento (60%)
                                  Positioned(
                                    left: 19 * scale,
                                    top: 109 * scale,
                                    child: Container(
                                      width: (343 * 0.60) * scale,
                                      height: 10 * scale,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF441867),
                                        borderRadius: BorderRadius.circular(100 * scale),
                                      ),
                                    ),
                                  ),
                                  // Texto do progresso
                                  Positioned(
                                    left: 22 * scale,
                                    top: 125 * scale,
                                    child: Text(
                                      '60% concluído',
                                      style: TextStyle(
                                        color: const Color(0xFFAE85E5),
                                        fontSize: 12 * scale,
                                        fontFamily: 'JetBrainsMono',
                                        fontWeight: FontWeight.w600,
                                        height: 1.83,
                                      ),
                                    ),
                                  ),
                                  // Botão circular à direita (decorativo)
                                  Positioned(
                                    left: 314 * scale,
                                    top: 53 * scale,
                                    child: Container(
                                      width: 45 * scale,
                                      height: 45 * scale,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: LinearGradient(
                                          begin: Alignment(0.00, 0.58),
                                          end: Alignment(1.00, 0.58),
                                          colors: [Color(0xFF9240FE), Color(0xFF8523F7)],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: const NotificationSummaryCardBlue(),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SecurityAlertCardRed(
                              count: '1',
                              onTap: () {
                                try {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (BuildContext context) {
                                        return SecurityAlertsScreenReal();
                                      },
                                    ),
                                  ).then((value) {
                                  });
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Erro ao abrir alertas: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      _isMapSelected
                          ? NewsFeedWidget(query: 'cybersecurity')
                          : Container(
                              height: 180,
                              width: double.infinity,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.13),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                'Calendário (em breve)',
                                style: TextStyle(color: Colors.grey[400], fontSize: 16),
                              ),
                            ),

                      const SizedBox(height: 48), // espaço ao final para evitar colagem no bottom
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

// COMPONENTE REUTILIZÁVEL PARA OS CARDS DE INFO - VERSÃO FUNCIONAL PERMANENTE
class CardInfo extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;

  const CardInfo({
    super.key,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    print('🏗️ Construindo CardInfo - subtitle: $subtitle, onTap: ${onTap != null}');
    
    // Se tem onTap, retorna um botão clicável
    if (onTap != null) {
      print('✅ Criando card CLICÁVEL para: $subtitle');
      return SizedBox(
        height: 120,
        child: ElevatedButton(
          onPressed: () {
            print('🚀 CARD CLICÁVEL ACIONADO: $subtitle');
            onTap!();
          },
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: color.withOpacity(0.8), width: 3),
            ),
            padding: EdgeInsets.all(12),
            elevation: 8,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(title, style: const TextStyle(color: Colors.white)),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(subtitle, style: const TextStyle(color: Colors.white70)),
                  const SizedBox(width: 4),
                  Icon(Icons.touch_app, color: color, size: 18),
                ],
              ),
            ],
          ),
        ),
      );
    } else {
      // Card normal sem clique
      print('📦 Criando card NORMAL para: $subtitle');
      return Container(
        height: 120,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(title, style: const TextStyle(color: AppColors.white)),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(subtitle, style: const TextStyle(color: AppColors.white)),
          ],
        ),
      );
    }
  }
}

// --- NOVO CARD: Alerta de segurança (VERMELHO) ---
class SecurityAlertCardRed extends StatefulWidget {
  final String count;
  final VoidCallback? onTap;
  const SecurityAlertCardRed({
    super.key,
    required this.count,
    this.onTap,
  });

  @override
  State<SecurityAlertCardRed> createState() => _SecurityAlertCardRedState();
}

class _SecurityAlertCardRedState extends State<SecurityAlertCardRed> {
  bool _pressed = false;
  bool _hovered = false;

  void _setPressed(bool v) => setState(() => _pressed = v);
  void _setHovered(bool v) => setState(() => _hovered = v);

  @override
  Widget build(BuildContext context) {
    final double scale = _pressed ? 0.98 : (_hovered ? 1.02 : 1.0);
    final double translateY = _pressed ? -3.0 : (_hovered ? -2.0 : 0.0);

    final cardContent = LayoutBuilder(
      builder: (context, constraints) {
        // Base do Figma: 178 x 171
        const baseW = 178.0;
        const baseH = 171.0;
        final w = constraints.maxWidth;
        final scaleW = w / baseW;
        final h = baseH * scaleW;

        return SizedBox(
          width: w,
          height: h,
          child: Stack(
            children: [
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xB2834748),
                    borderRadius: BorderRadius.circular(16 * scaleW),
                    border: Border.all(
                      width: 1 * scaleW,
                      color: const Color(0xFFD07274),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 12 * scaleW,
                left: 0,
                right: 0,
                child: Icon(
                  Icons.shield_outlined,
                  size: 28 * scaleW,
                  color: const Color(0xFFD58F90),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                top: 64 * scaleW,
                child: Text(
                  'Você tem',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16 * scaleW,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    height: 1.38,
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                top: 92 * scaleW,
                child: Text(
                  widget.count,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: const Color(0xFFD64344),
                    fontSize: 22 * scaleW,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    height: 1,
                  ),
                ),
              ),
              Positioned(
                left: 8 * scaleW,
                right: 8 * scaleW,
                top: 120 * scaleW,
                child: Text(
                  'Alerta de segurança',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: const Color(0xFFD58F90),
                    fontSize: 16 * scaleW,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    height: 1.38,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    final animated = AnimatedScale(
      scale: scale,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, translateY, 0),
        child: cardContent,
      ),
    );

    final interactive = MouseRegion(
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        child: animated,
      ),
    );

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        splashColor: const Color(0xFFD07274).withOpacity(0.15),
        highlightColor: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(16),
        onTap: widget.onTap,
        child: interactive,
      ),
    );
  }
}