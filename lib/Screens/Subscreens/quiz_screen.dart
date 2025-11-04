import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nexus_app/core/theme/app_colors.dart';
// Importa a nova tela de resultados que criamos (onde os dados são salvos)
import 'package:nexus_app/Screens/Subscreens/quiz_results_screen.dart';

// Modelo de dados local para a pergunta (com 'points')
class QuizQuestion {
  final String id;
  final String questionText;
  final List<String> options;
  final int correctOptionIndex;
  final int points;

  QuizQuestion({
    required this.id,
    required this.questionText,
    required this.options,
    required this.correctOptionIndex,
    required this.points,
  });

  factory QuizQuestion.fromDoc(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return QuizQuestion(
      id: doc.id,
      questionText: data['questionText'] ?? 'Texto da pergunta não encontrado',
      options: List<String>.from(data['options'] ?? []),
      correctOptionIndex: (data['correctOptionIndex'] as num?)?.toInt() ?? 0,
      points: (data['points'] as num?)?.toInt() ?? 10, // Padrão 10
    );
  }
}

// A tela principal do Quiz (global)
class QuizScreen extends StatefulWidget {
  const QuizScreen({
    super.key,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  late Future<List<QuizQuestion>> _questionsFuture;
  List<QuizQuestion> _questions = [];
  int _currentQuestionIndex = 0;
  int _totalPoints = 0;
  int? _selectedOptionIndex;
  bool _answerChecked = false;

  // NOVAS VARIÁVEIS PARA O RANKING
  final Stopwatch _stopwatch = Stopwatch(); // 1. Para medir o tempo
  int _correctAnswersCount = 0; // 2. Para contar acertos (ex: 8/10)

  @override
  void initState() {
    super.initState();
    _questionsFuture = _fetchQuiz();
  }

  // FUNÇÃO ATUALIZADA (BUSCA 8 + 2)
  Future<List<QuizQuestion>> _fetchQuiz() async {
    // 1. Criar as listas finais
    List<QuizQuestion> finalQuizList = [];
    
    // 2. Buscar, embaralhar e adicionar 8 perguntas de 10 PONTOS
    try {
      final tenPointSnapshot = await FirebaseFirestore.instance
          .collection('quizQuestions')
          .where('points', isEqualTo: 10) // Busca só as de 10 pontos
          .get();
          
      if (tenPointSnapshot.docs.length < 8) {
        // Erro se não houver perguntas suficientes no banco
        throw Exception('Não há perguntas suficientes de 10 pontos no banco de dados. (Encontrado: ${tenPointSnapshot.docs.length}, Necessário: 8)');
      }

      List<QuizQuestion> tenPointQuestions = tenPointSnapshot.docs.map((doc) => QuizQuestion.fromDoc(doc)).toList();
      tenPointQuestions.shuffle();
      finalQuizList.addAll(tenPointQuestions.take(8)); // Adiciona 8

    } catch (e) {
      debugPrint('Erro ao buscar perguntas de 10 pontos: $e');
      rethrow; // Re-lança o erro para o FutureBuilder
    }

    // 3. Buscar, embaralhar e adicionar 2 perguntas de 20 PONTOS
    try {
      final twentyPointSnapshot = await FirebaseFirestore.instance
          .collection('quizQuestions')
          .where('points', isEqualTo: 20) // Busca só as de 20 pontos
          .get();

      if (twentyPointSnapshot.docs.length < 2) {
        // Erro se não houver perguntas suficientes no banco
        throw Exception('Não há perguntas suficientes de 20 pontos no banco de dados. (Encontrado: ${twentyPointSnapshot.docs.length}, Necessário: 2)');
      }
      
      List<QuizQuestion> twentyPointQuestions = twentyPointSnapshot.docs.map((doc) => QuizQuestion.fromDoc(doc)).toList();
      twentyPointQuestions.shuffle();
      finalQuizList.addAll(twentyPointQuestions.take(2)); // Adiciona 2

    } catch (e) {
      debugPrint('Erro ao buscar perguntas de 20 pontos: $e');
      rethrow; // Re-lança o erro para o FutureBuilder
    }

    // 4. Embaralhar a lista final de 10 perguntas
    // (Para que as de 20 pontos não fiquem sempre no fim)
    finalQuizList.shuffle();

    _questions = finalQuizList;

    if (_questions.length != 10) {
      // Apenas uma verificação de segurança
      throw Exception('Falha ao montar o quiz com 10 perguntas.');
    }

    // 5. Inicia o cronômetro quando as perguntas são carregadas
    _stopwatch.start();
    return _questions;
  }


  // FUNÇÃO ATUALIZADA (SOMA PONTOS E ACERTOS)
  void _checkAnswer() {
    if (_answerChecked || _selectedOptionIndex == null) return;

    final currentQuestion = _questions[_currentQuestionIndex];

    setState(() {
      _answerChecked = true;
      if (_selectedOptionIndex == currentQuestion.correctOptionIndex) {
        _totalPoints += currentQuestion.points; // Soma os pontos
        _correctAnswersCount++; // Incrementa o contador de acertos
      }
    });

    Future.delayed(const Duration(milliseconds: 1500), () {
      _nextQuestion();
    });
  }

  // FUNÇÃO ATUALIZADA (NAVEGA COM TODOS OS DADOS)
  void _nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _selectedOptionIndex = null;
        _answerChecked = false;
      });
    } else {
      // Fim do quiz
      _stopwatch.stop(); // Para o cronômetro

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => QuizResultsScreen(
            totalPointsGained: _totalPoints,
            correctAnswers: _correctAnswersCount,  // Passa os acertos
            totalQuestions: _questions.length,
            timeTakenInSeconds: _stopwatch.elapsed.inSeconds, // Passa o tempo
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Usa o gradiente do app
      appBar: AppBar(
        title: const Text('Quiz Rápido'),
        backgroundColor: const Color(0xFF1B202E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ),
      body: FutureBuilder<List<QuizQuestion>>(
        future: _questionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
             return Center(child: Padding(
               padding: const EdgeInsets.all(16.0),
               child: Text('Erro ao carregar perguntas: ${snapshot.error}', style: const TextStyle(color: Colors.red, fontSize: 16)),
             ));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Nenhuma pergunta encontrada.', style: TextStyle(color: Colors.white)));
          }

          final question = _questions[_currentQuestionIndex];
          final progress = (_currentQuestionIndex + 1) / _questions.length;
          final isCorrect = _selectedOptionIndex == question.correctOptionIndex;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 32), // Espaço do topo
                Text(
                  'Pergunta ${_currentQuestionIndex + 1} de ${_questions.length}',
                  textAlign: TextAlign.start,
                  style: const TextStyle(
                    color: Color(0xFFC6C5C3),
                    fontSize: 16,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                // Barra de Progresso
                ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 10,
                    backgroundColor: const Color(0xAF545252),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFAE85E5)),
                  ),
                ),
                const SizedBox(height: 28),
                // Pergunta
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: ShapeDecoration(
                    color: const Color(0x7F515767),
                    shape: RoundedRectangleBorder(
                      side: const BorderSide(width: 1, color: Color(0xB27884C4)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        question.questionText,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFFC6C5C3),
                          fontSize: 22,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                       const SizedBox(height: 8),
                      // Mostra os pontos da pergunta
                      Text(
                        'Vale: ${question.points} pontos',
                        style: const TextStyle(
                          color: AppColors.primaryPurple, // Use sua cor de tema
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                // Opções
                ...List.generate(question.options.length, (index) {
                  final letter = String.fromCharCode('A'.codeUnitAt(0) + index);
                  return _OptionTile(
                    text: question.options[index],
                    letter: letter,
                    isSelected: _selectedOptionIndex == index,
                    isCorrect: index == question.correctOptionIndex,
                    showResult: _answerChecked,
                    onTap: () {
                      if (!_answerChecked) {
                        setState(() => _selectedOptionIndex = index);
                      }
                    },
                  );
                }),
                const Spacer(),
                // Botão de Confirmação / Feedback
                _ConfirmButton(
                  status: !_answerChecked 
                    ? (_selectedOptionIndex != null ? _ButtonStatus.selected : _ButtonStatus.normal)
                    : (isCorrect ? _ButtonStatus.correct : _ButtonStatus.incorrect),
                  onTap: _checkAnswer,
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }
}

// =================================================================
// WIDGETS DE ESTILO DO QUIZ (Internos)
// =================================================================

enum _ButtonStatus { normal, selected, correct, incorrect }

class _ConfirmButton extends StatelessWidget {
  final _ButtonStatus status;
  final VoidCallback onTap;

  const _ConfirmButton({required this.status, required this.onTap});

  @override
  Widget build(BuildContext context) {
    String text;
    List<Color> gradient;
    
    switch (status) {
      case _ButtonStatus.correct:
        text = 'Resposta correta';
        gradient = [const Color(0xFF9BF0BE), const Color(0xFF43D660)];
        break;
      case _ButtonStatus.incorrect:
        text = 'Resposta incorreta';
        gradient = [const Color(0xFFD17374), const Color(0xFFFF6B35)];
        break;
      case _ButtonStatus.selected:
      case _ButtonStatus.normal:
      default:
        text = 'Confirmar resposta';
        gradient = [const Color(0xFF9644FF), const Color(0xFF6638B6)];
        break;
    }

    return GestureDetector(
      onTap: (status == _ButtonStatus.selected) ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        height: 50,
        decoration: ShapeDecoration(
          gradient: LinearGradient(colors: gradient),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          shadows: const [BoxShadow(color: Color(0x5EAE85E5), blurRadius: 50, offset: Offset(0, 0), spreadRadius: -5)],
        ),
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
    );
  }
}


class _OptionTile extends StatelessWidget {
  final String text;
  final String letter;
  final bool isSelected;
  final bool isCorrect;
  final bool showResult;
  final VoidCallback onTap;

  const _OptionTile({
    required this.text,
    required this.letter,
    required this.isSelected,
    required this.isCorrect,
    required this.showResult,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor, borderColor, letterBgColor, letterColor, textColor;

    if (showResult && isCorrect) {
      // Estado: CORRETO
      bgColor = const Color(0xB75DA146);
      borderColor = const Color(0xBF96E585);
      letterBgColor = const Color(0xFF85E59D);
      letterColor = const Color(0xFF368848);
      textColor = const Color(0xFF9EE7B1);
    } else if (showResult && isSelected && !isCorrect) {
      // Estado: SELECIONADO E INCORRETO
      bgColor = const Color(0xB7A14646);
      borderColor = const Color(0xBFE58585);
      letterBgColor = const Color(0xFFE58585);
      letterColor = const Color(0xFF883636);
      textColor = const Color(0xFFE79E9E);
    } else if (isSelected) {
      // Estado: SELECIONADO (ANTES DE CONFIRMAR)
      bgColor = const Color(0xFF703FAF);
      borderColor = const Color(0xBFAE85E5);
      letterBgColor = const Color(0xFFAE85E5);
      letterColor = const Color(0xFFA259FF);
      textColor = const Color(0xFFBD9EE7);
    } else {
      // Estado: NORMAL
      bgColor = const Color(0x7F515767);
      borderColor = const Color(0xB27884C4);
      letterBgColor = const Color(0xFF555A65);
      letterColor = Colors.white;
      textColor = const Color(0xFFC6C5C3);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: InkWell(
        onTap: showResult ? null : onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: double.infinity,
          height: 65,
          decoration: ShapeDecoration(
            color: bgColor,
            shape: RoundedRectangleBorder(
              side: BorderSide(width: 1, color: borderColor),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 60, // Largura fixa para o "A"
                alignment: Alignment.center,
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: ShapeDecoration(
                    color: letterBgColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    letter,
                    style: TextStyle(
                      color: letterColor,
                      fontSize: 22,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8.0), // Adiciona padding
                  child: Text(
                    text,
                    // ###################### CORREÇÃO AQUI ######################
                    //      'const' foi removido de TextStyle abaixo
                    // ###########################################################
                    style: TextStyle(
                      color: textColor,
                      fontSize: 20, // Ajustado para 20
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis, // Evita quebra de layout
                    maxLines: 2, // Permite até 2 linhas
                  ),
                ),
              ),
              // Ícone de check/erro (oculto por padrão)
              if (showResult && (isCorrect || isSelected))
                Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: Icon(
                    isCorrect ? Icons.check_circle : Icons.cancel,
                    color: isCorrect ? Colors.green : Colors.red,
                  ),
                )
            ],
          ),
        ),
      ),
    );
  }
}

// O QuizResultsScreen foi removido daqui e está agora em seu próprio arquivo
// 'quiz_results_screen.dart', que é importado no topo deste arquivo.