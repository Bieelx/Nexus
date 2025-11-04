// =================================================================
// TELA DE RESULTADOS DO QUIZ (Atualizada para salvar o ranking)
// =================================================================
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nexus_app/core/theme/app_colors.dart';
import 'package:intl/intl.dart'; // Para formatar o tempo

// Este widget estava no seu quiz_screen.dart, 
// estou colocando-o aqui com as novas lógicas
class QuizResultsScreen extends StatefulWidget {
  final int totalPointsGained;
  final int correctAnswers; // Novo
  final int totalQuestions;
  final int timeTakenInSeconds; // Novo

  const QuizResultsScreen({
    super.key,
    required this.totalPointsGained,
    required this.correctAnswers,
    required this.totalQuestions,
    required this.timeTakenInSeconds,
  });

  @override
  State<QuizResultsScreen> createState() => _QuizResultsScreenState();
}

class _QuizResultsScreenState extends State<QuizResultsScreen> {
  @override
  void initState() {
    super.initState();
    _saveResultToRanking();
  }

  // FORMATA O TEMPO de segundos (ex: 182) para "03:02"
  String _formatTime(int seconds) {
    final duration = Duration(seconds: seconds);
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final secs = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$secs';
  }

  // FUNÇÃO PRINCIPAL DE SALVAMENTO
  Future<void> _saveResultToRanking() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return; // Não salvar se não estiver logado

    // O 'displayName' pode ser nulo, pegue de onde você salva (ex: coleção 'users')
    // Vou usar o 'email' como fallback
    final String userName = user.displayName ?? user.email ?? 'Usuário Anônimo';
    // Pega as iniciais, ex: "Gabriel Araujo" -> "GA"
    final String initials = userName.isNotEmpty
        ? userName.trim().split(' ').map((e) => e[0]).take(2).join().toUpperCase()
        : '??';

    final rankingRef = FirebaseFirestore.instance.collection('quizRanking').doc(user.uid);
    final now = Timestamp.now();

    final newResult = {
      'userId': user.uid,
      'userName': userName,
      'userInitials': initials,
      'totalPoints': widget.totalPointsGained,
      'correctAnswers': widget.correctAnswers,
      'timeTakenSeconds': widget.timeTakenInSeconds,
      'timeFormatted': _formatTime(widget.timeTakenInSeconds),
      'lastUpdated': now,
    };

    try {
      final doc = await rankingRef.get();

      if (!doc.exists) {
        // 1. Se o usuário não tem resultado, salva o primeiro
        await rankingRef.set(newResult);
      } else {
        // 2. Se já existe, compara para salvar apenas o MELHOR resultado
        final int currentBestPoints = doc.data()?['totalPoints'] ?? 0;
        final int currentTime = doc.data()?['timeTakenSeconds'] ?? 99999;

        // Regra 1: Pontuação maior é melhor
        if (widget.totalPointsGained > currentBestPoints) {
          await rankingRef.set(newResult);
        } 
        // Regra 2: Se a pontuação for IGUAL, tempo menor é melhor
        else if (widget.totalPointsGained == currentBestPoints &&
                   widget.timeTakenInSeconds < currentTime) {
          await rankingRef.set(newResult);
        }
        // Se não, não faz nada (mantém o recorde antigo)
      }
    } catch (e) {
      debugPrint("Erro ao salvar no ranking: $e");
      // Opcional: mostrar um SnackBar de erro
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Resultados'),
        backgroundColor: const Color(0xFF1B202E),
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Quiz Concluído!',
                style: TextStyle(color: AppColors.primaryPurple, fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              Text(
                'Você fez',
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),
              Text(
                '${widget.totalPointsGained} Pontos',
                style: const TextStyle(color: Color(0xFFAE85E5), fontSize: 48, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Acertando ${widget.correctAnswers} de ${widget.totalQuestions} perguntas.',
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
              Text(
                'Tempo: ${_formatTime(widget.timeTakenInSeconds)}',
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 48),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryPurple,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Fechar', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}