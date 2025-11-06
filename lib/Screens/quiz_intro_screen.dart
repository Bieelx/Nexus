import 'package:flutter/material.dart';
import 'package:nexus_app/Screens/Subscreens/quiz_screen.dart';
import 'package:nexus_app/Screens/Subscreens/ranking_screen.dart';
import 'package:nexus_app/core/theme/app_colors.dart';

class QuizIntroScreen extends StatelessWidget {
  // REMOVIDO: Não precisamos mais de courseId, moduleId, ou moduleXP
  // final String courseId;
  // final String moduleId;
  // final int moduleXP;

  const QuizIntroScreen({
    super.key,
    // REMOVIDO: Parâmetros antigos
    // required this.courseId,
    // required this.moduleId,
    // this.moduleXP = 50,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Deixa o gradiente da main aparecer
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Cabeçalho com botão de voltar
              Align(
                alignment: Alignment.topLeft,
                child: Material(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(12),
                    child: const SizedBox(
                      width: 44,
                      height: 44,
                      child: Icon(Icons.arrow_back, color: Colors.white, size: 22),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // 2. Ícone de Troféu
              Center(child: _TrophyIcon()),

              const SizedBox(height: 32),

              // 3. Textos (Atualizados)
              const Text(
                'Desafio Rápido', // <-- MUDADO
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFFD0B7F2),
                  fontSize: 24,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w500,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Teste seus conhecimentos',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFFC6C5C3),
                  fontSize: 16,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),

              // 4. Card de Informações (Atualizado)
              _InfoCard(),

              const SizedBox(height: 40),

              // 5. Botões
              _QuizButton(
                text: 'Iniciar quiz',
                isPrimary: true,
                onTap: () {
                  // CORRIGIDO: Navega para a nova QuizScreen sem parâmetros
                  Navigator.push( // Usamos 'push' para poder voltar
                    context,
                    MaterialPageRoute(
                      builder: (_) => const QuizScreen(), // <-- MUDADO
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              _QuizButton(
                              text: 'Ranking',
                              isPrimary: false,
                              onTap: () {
                                // ALTERADO: Navega para a nova tela
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const RankingScreen(),
                                  ),
                                );
                              },
                            ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Widgets de Estilo Internos ---

class _TrophyIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      height: 150,
      decoration: ShapeDecoration(
        color: const Color(0xFF634A9E),
        shape: RoundedRectangleBorder(
          side: const BorderSide(width: 1, color: Color(0xFF8447D6)),
          borderRadius: BorderRadius.circular(16),
        ),
        shadows: const [
          BoxShadow(
            color: Color(0x51AE85E5),
            blurRadius: 100,
            offset: Offset(0, 0),
            spreadRadius: 9,
          )
        ],
      ),
      child: const Icon(Icons.emoji_events_outlined, color: Color(0xFFD0B7F2), size: 80),
    );
  }
}

class _InfoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: ShapeDecoration(
        color: const Color(0x7F515767),
        shape: RoundedRectangleBorder(
          side: const BorderSide(width: 1, color: Color(0xB27884C4)),
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 63,
                height: 63,
                decoration: ShapeDecoration(
                  color: const Color(0xFF634A9E),
                  shape: RoundedRectangleBorder(
                    side: const BorderSide(width: 1, color: Color(0xFF8447D6)),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Icon(Icons.bolt, color: Color(0xFFAE85E5), size: 32),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    '10 perguntas', // Isto ainda é verdade
                    style: TextStyle(
                      color: Color(0xFFAE85E5),
                      fontSize: 22,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Ganhe pontos por cada acerto', // <-- MUDADO
                    style: TextStyle(
                      color: Color(0xFFC6C5C3),
                      fontSize: 14,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          const _BulletPoint(text: 'Teste seu conhecimento'),
          const SizedBox(height: 12),
          const _BulletPoint(text: 'Ganhe XP e suba de nível'),
          const SizedBox(height: 12),
          const _BulletPoint(text: 'Compare pontos no Ranking'), // <-- MUDADO
        ],
      ),
    );
  }
}

class _BulletPoint extends StatelessWidget {
  final String text;
  const _BulletPoint({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text(
          '√', // Usando o caractere de check
          style: TextStyle(
            color: Color(0xFF43D660),
            fontSize: 16,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          text,
          style: const TextStyle(
            color: Color(0xFF9CA3AF),
            fontSize: 16,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _QuizButton extends StatelessWidget {
  final String text;
  final bool isPrimary;
  final VoidCallback onTap;

  const _QuizButton({required this.text, this.isPrimary = true, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isPrimary ? null : Colors.transparent,
      shape: RoundedRectangleBorder(
        side: isPrimary ? BorderSide.none : const BorderSide(width: 1, color: Color(0xFF9745FF)),
        borderRadius: BorderRadius.circular(16),
      ),
      shadowColor: const Color(0x7FAE85E5),
      elevation: isPrimary ? 8 : 0,
      child: Ink(
        decoration: BoxDecoration(
          gradient: isPrimary
              ? const LinearGradient(
                  colors: [Color(0xFF9644FF), Color(0xFF6638B6)],
                )
              : null,
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: double.infinity,
            height: 50,
            alignment: Alignment.center,
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFFFEF7FF),
                fontSize: 20,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}