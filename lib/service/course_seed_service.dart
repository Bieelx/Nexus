import 'package:cloud_firestore/cloud_firestore.dart';

class CourseSeedService {
  static Future<void> ensureModulesSeeded(String courseId) async {
    final db = FirebaseFirestore.instance;
    final modRef = db.collection('courses').doc(courseId).collection('modules');
    final exists = await modRef.limit(1).get();
    if (exists.size > 0) return;

    final batch = db.batch();

    Map<String, dynamic> lesson({
      required int order,
      required String id,
      required String title,
      required String duration,
      required String content,
    }) => {
      'order': order,
      'type': 'lesson',
      'title': title,
      'duration': duration,
      'content': content,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    Map<String, dynamic> quiz({
      required int order,
      required String id,
      required String title,
      required List<Map<String, dynamic>> questions,
    }) => {
      'order': order,
      'type': 'quiz',
      'title': title,
      'duration': '—',
      'questions': questions,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    // Exemplo genérico — personalize por curso depois se quiser.
    final docs = <MapEntry<String, Map<String, dynamic>>>[
      MapEntry('m01', lesson(
        order: 1, id: 'm01', title: 'Introdução', duration: '12min',
        content: 'Conceitos iniciais, objetivos do curso e boas práticas.',
      )),
      MapEntry('m02', lesson(
        order: 2, id: 'm02', title: 'Fundamentos', duration: '18min',
        content: 'Fundamentos e termos essenciais para avançar no tema.',
      )),
      MapEntry('m03', lesson(
        order: 3, id: 'm03', title: 'Ferramentas', duration: '22min',
        content: 'Ferramentas úteis e como aplicá-las no dia a dia.',
      )),
      MapEntry('m04', quiz(
        order: 4, id: 'm04', title: 'Mini-quiz',
        questions: [
          {
            'q': 'Pergunta 1?',
            'options': ['A', 'B', 'C', 'D'],
            'correctIndex': 1,
            'explanation': 'Explicação da resposta 1.'
          },
          {
            'q': 'Pergunta 2?',
            'options': ['A', 'B', 'C', 'D'],
            'correctIndex': 2,
            'explanation': 'Explicação da resposta 2.'
          },
          {
            'q': 'Pergunta 3?',
            'options': ['A', 'B', 'C', 'D'],
            'correctIndex': 0,
            'explanation': 'Explicação da resposta 3.'
          },
        ],
      )),
      MapEntry('m05', lesson(
        order: 5, id: 'm05', title: 'Casos práticos', duration: '20min',
        content: 'Estudos de caso e análise prática.',
      )),
      MapEntry('m06', lesson(
        order: 6, id: 'm06', title: 'Aplicando no dia a dia', duration: '16min',
        content: 'Checklists e rotinas recomendadas.',
      )),
      MapEntry('m07', lesson(
        order: 7, id: 'm07', title: 'Revisão geral', duration: '10min',
        content: 'Resumo dos pontos-chave do curso.',
      )),
      MapEntry('m08', quiz(
        order: 8, id: 'm08', title: 'Quiz final',
        questions: List.generate(10, (i) => {
          'q': 'Questão ${i+1} do quiz final?',
          'options': ['A', 'B', 'C', 'D'],
          'correctIndex': i % 4,
          'explanation': 'Explicação da questão ${i+1}.'
        }),
      )),
    ];

    for (final e in docs) {
      final ref = modRef.doc(e.key);
      batch.set(ref, e.value);
    }

    await batch.commit();
  }
}