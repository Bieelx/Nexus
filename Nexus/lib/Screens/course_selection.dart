import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import './Subscreens/course_modules_screen.dart';

class CourseInfo {
  final String title;
  final String level;
  final int modules;
  final String duration;
  final String description;
  final VoidCallback? onTap;

  const CourseInfo({
    required this.title,
    required this.level,
    required this.modules,
    required this.duration,
    required this.description,
    this.onTap,
  });
}

class CourseSelectionScreen extends StatefulWidget {
  // Novo parâmetro para a função de voltar para Home
  final VoidCallback? onBackToHome;
  
  const CourseSelectionScreen({super.key, this.onBackToHome});

  @override
  State<CourseSelectionScreen> createState() => _CourseSelectionScreenState();
}

class _CourseSelectionScreenState extends State<CourseSelectionScreen> {
  @override
  void initState() {
    super.initState();
    _ensureSeed();
  }

  Future<void> _ensureSeed() async {
    final db = FirebaseFirestore.instance;
    final snap = await db.collection('courses').limit(1).get();
    if (snap.size == 0) {
      await seedBaseCourses();
    }
  }

  @override
  Widget build(BuildContext context) {
    final double topSpacing = MediaQuery.of(context).size.height * (68 / 892);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: topSpacing),
              // Passando a função de callback para o Header
              _Header(onBackTap: widget.onBackToHome), 
              const SizedBox(height: 24),
              const Text(
                'Aprenda sobre segurança digital de forma interativa e gamificada, suba de nível e ganhe recompensas.',
                style: TextStyle(
                  color: Color(0xFFC6C5C3),
                  fontSize: 12,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
                future: FirebaseFirestore.instance.collection('courses').orderBy('order').get(),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: Padding(padding: EdgeInsets.all(32.0), child: CircularProgressIndicator()));
                  }
                  if (snap.hasError || !snap.hasData) {
                    return const Center(child: Text('Erro ao carregar cursos.', style: TextStyle(color: Colors.white70)));
                  }

                  final docs = snap.data!.docs.where((doc) => (doc.data()['isActive'] ?? true) == true).toList();

                  if (docs.isEmpty) {
                    return const Center(child: Text('Nenhum curso disponível agora.', style: TextStyle(color: Colors.white70)));
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, i) {
                      final doc = docs[i];
                      final data = doc.data();
                      final info = CourseInfo(
                        title: data['title'] ?? '',
                        level: data['level'] ?? 'Básico',
                        modules: (data['modulesCount'] as int?) ?? 0,
                        duration: data['duration'] ?? '—',
                        description: data['descriptionShort'] ?? '',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CourseModulesScreen(
                                courseId: doc.id,
                                courseName: data['title'] ?? '',
                              ),
                            ),
                          );
                        },
                      );
                      return _CourseCard(course: info);
                    },
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

class _Header extends StatelessWidget {
  // Novo parâmetro para receber a função de callback
  final VoidCallback? onBackTap;
  const _Header({this.onBackTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Material(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            // Usando a função recebida no onTap
            onTap: onBackTap,
            borderRadius: BorderRadius.circular(12),
            child: const SizedBox(
              width: 44,
              height: 44,
              child: Icon(Icons.home_outlined, color: Colors.white, size: 22), // Ícone de Home
            ),
          ),
        ),
        const SizedBox(width: 16),
        const Text(
          'Cursos',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

Future<void> seedBaseCourses() async {
  final db = FirebaseFirestore.instance;
  final batch = db.batch();
  final entries = <String, Map<String, dynamic>>{
    'seguranca-digital': {
      'title': 'Segurança digital', 'level': 'Básico', 'planMin': 'free',
      'descriptionShort': 'Conceitos essenciais para proteger contas, senhas e dispositivos.', 'order': 1,
    },
    'inteligencia-artificial': {
      'title': 'Inteligência Artificial', 'level': 'Intermediário', 'planMin': 'silver',
      'descriptionShort': 'Fundamentos práticos de IA aplicada ao dia a dia e segurança.', 'order': 2,
    },
    'phishing': {
      'title': 'Phishing', 'level': 'Básico', 'planMin': 'free',
      'descriptionShort': 'Como identificar, prevenir e reportar golpes e engenharia social.', 'order': 3,
    },
    'analise-de-dados': {
      'title': 'Análise de Dados', 'level': 'Intermediário', 'planMin': 'silver',
      'descriptionShort': 'Coleta, tratamento e leitura crítica de dados para decisão.', 'order': 4,
    },
    'criptografia-aplicada': {
      'title': 'Criptografia aplicada', 'level': 'Avançado', 'planMin': 'gold',
      'descriptionShort': 'Chaves, cifras, TLS, boas práticas e armadilhas no mundo real.', 'order': 5,
    },
  };

  for (final e in entries.entries) {
    final ref = db.collection('courses').doc(e.key);
    batch.set(ref, {
      ...e.value,
      'modulesCount': 0, 'duration': '—', 'isActive': true,
      'createdAt': FieldValue.serverTimestamp(), 'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
  await batch.commit();
}

class _CourseCard extends StatelessWidget {
  const _CourseCard({required this.course});
  final CourseInfo course;

  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.sizeOf(context).width < 380;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: course.onTap,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 114),
        decoration: ShapeDecoration(
          color: const Color(0xFF171B27),
          shape: RoundedRectangleBorder(
            side: const BorderSide(width: 1, color: Color(0xFF6B7691)),
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(color: const Color(0xFF8447D6), borderRadius: BorderRadius.circular(5)),
                    child: const Icon(Icons.shield, color: Colors.white, size: 16),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      course.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Color(0xFFAE85E5), fontSize: 16, fontFamily: 'Poppins', fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  _LevelBadge(text: course.level),
                  const SizedBox(width: 10),
                  Text(
                    '${course.modules} módulos  •  ${course.duration}',
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontFamily: 'Poppins', fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                course.description,
                softWrap: true,
                maxLines: isNarrow ? 3 : 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xFFC6C5C3), fontSize: 10, fontFamily: 'Poppins', fontWeight: FontWeight.w600, height: 1.3),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class _LevelBadge extends StatelessWidget {
  const _LevelBadge({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1.5),
      decoration: ShapeDecoration(
        gradient: const LinearGradient(
          begin: Alignment(-0.00, 0.47),
          end: Alignment(1.07, 0.47),
          colors: [Color(0xFF6638B6), Color(0xFF654DB0)],
        ),
        shape: RoundedRectangleBorder(
          side: const BorderSide(width: 1, color: Color(0xFF6C53BB)),
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Color(0xFFAE85E5), fontSize: 10, fontFamily: 'Poppins', fontWeight: FontWeight.w500),
      ),
    );
  }
}