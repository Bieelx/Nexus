import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/theme/app_colors.dart';
import '../service/user_service.dart';
import '../service/course_progress_service.dart';

// Telas
import 'profile_page.dart';
import 'course_selection.dart';
import 'Subscreens/course_modules_screen.dart';
import 'quiz_intro_screen.dart'; // ADICIONADO: Import da nova tela de Quiz

// Widgets
import '../widgets/homeScreen/news_feed_widget.dart';
import '../widgets/homeScreen/home_cards.dart'; 

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? firstName;
  final user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadFirstName();
  }

  Future<void> _loadFirstName() async {
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
      if (doc.exists && doc.data()?['nome'] != null) {
        final nomeCompleto = doc.data()!['nome'] as String;
        if (mounted) setState(() => firstName = nomeCompleto.split(' ').first);
      }
    }
    if (firstName == null && mounted) setState(() => firstName = 'Usuário');
  }

  @override
  Widget build(BuildContext context) {
    // --- LÓGICA DE RESPONSIVIDADE ---
    final size = MediaQuery.of(context).size;
    
    const double figmaWidth = 412.0;
    const double figmaHeight = 892.0;
    const double horizontalPadding = 16.0;

    final double widthRatio = size.width / figmaWidth;

    const double smallCardFigmaWidth = 178.0;
    const double smallCardFigmaHeight = 171.0;
    final double smallCardWidth = smallCardFigmaWidth * widthRatio;
    final double smallCardHeight = smallCardFigmaHeight * widthRatio;
    
    final double newsCardWidth = size.width - (horizontalPadding * 2);
    final double newsCardHeight = newsCardWidth * (233 / 380);

    final double topSpacing = size.height * (68 / figmaHeight);
    // ------------------------------------

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: firstName == null
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: topSpacing),
                    _buildHeader(context),
                    const SizedBox(height: 24),
                    _buildCourseCard(),
                    
                    // ADICIONADO: Card do Quiz
                    const SizedBox(height: 24),
                    _buildFeaturedQuizCard(context), 
                    
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        NotificationSummaryCard(
                          width: smallCardWidth,
                          height: smallCardHeight,
                        ),
                        StreaksWidget(
                          width: smallCardWidth,
                          height: smallCardHeight,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16), 
                    NewsFeedWidget(
                      width: newsCardWidth,
                      height: newsCardHeight,
                    ),
                    const SizedBox(height: 120),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Bem-vindo de volta', style: TextStyle(color: Colors.white, fontSize: 24, fontFamily: 'Poppins', fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text('<${firstName ?? 'Usuário'}>', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.primaryPurple, fontSize: 18, fontFamily: 'JetBrainsMono', fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        const SizedBox(width: 16),
        InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfilePage())),
          child: StreamBuilder<String?>(
            stream: UserService().photoUrlStream,
            builder: (context, snapshot) {
              final photoUrl = snapshot.data;
              return Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryPurple,
                ),
                clipBehavior: Clip.antiAlias,
                child: (photoUrl != null && photoUrl.isNotEmpty)
                    ? (photoUrl.startsWith('assets/')
                        ? Image.asset(
                            photoUrl,
                            fit: BoxFit.cover,
                            alignment: Alignment.topCenter,
                          )
                        : Image.network(
                            photoUrl,
                            fit: BoxFit.cover,
                            alignment: Alignment.topCenter,
                            errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 24, color: Colors.white),
                          ))
                    : const Icon(Icons.person, size: 24, color: Colors.white),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCourseCard() {
    if (user == null) {
      return const _PlaceholderCourseCard();
    }
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user!.uid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const _PlaceholderCourseCard(isLoading: true);
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const _PlaceholderCourseCard();
        }
        final userData = snapshot.data!.data() as Map<String, dynamic>;
        final lastCourse = userData['lastAccessedCourse'] as Map<String, dynamic>?;

        if (lastCourse == null || lastCourse['id'] == null) {
          return const _PlaceholderCourseCard();
        }

        final String courseId = lastCourse['id'];
        final String courseName = lastCourse['name'] ?? 'Curso';

        return _ContinueCourseCard(
          uid: user!.uid,
          courseId: courseId,
          courseName: courseName,
        );
      },
    );
  }

  // NOVO WIDGET PARA O CARD DO QUIZ
  Widget _buildFeaturedQuizCard(BuildContext context) {
    // !! IMPORTANTE !!
    // Troque estes IDs pelos IDs reais do seu Firestore
    // para o módulo de quiz que você quer destacar
    const String featuredCourseId = "seguranca-digital"; 
    const String featuredModuleId = "quiz_final"; // (Este ID é um exemplo, use o ID do seu documento)

    return Material(
      color: const Color(0xFF171B27),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => QuizIntroScreen(

              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF6B7691)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quiz Rápido', 
                      style: TextStyle(color: Color(0xFFAE85E5), fontSize: 20, fontWeight: FontWeight.bold)
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Teste seus conhecimentos e ganhe XP!', 
                      style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14)
                    ),
                  ],
                ),
              ),
              SizedBox(width: 16),
              Container(
                width: 50, height: 50,
                decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.primaryPurple),
                child: const Icon(Icons.quiz_outlined, color: Colors.white, size: 28),
              )
            ],
          ),
        ),
      ),
    );
  }
}

// ================================================================
// WIDGETS AUXILIARES (CARD DE CURSO)
// ================================================================

class _ContinueCourseCard extends StatelessWidget {
  final String uid;
  final String courseId;
  final String courseName;
  const _ContinueCourseCard({required this.uid, required this.courseId, required this.courseName});

  @override
  Widget build(BuildContext context) {
    final progressService = CourseProgressService();
    return StreamBuilder<CourseProgress>(
      stream: progressService.watch(uid, courseId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
            return const _PlaceholderCourseCard(isLoading: true);
        }
        final progress = snapshot.data!;
        final percent = (progress.progress * 100).round();
        final currentChapter = progress.completed.length + 1;
        return Material(
          color: const Color(0xFF492F71),
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => CourseModulesScreen(courseId: courseId, courseName: courseName))),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(courseName, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('Capítulo $currentChapter', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14)),
                    ])),
                    const SizedBox(width: 16),
                    Container(width: 50, height: 50, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.primaryPurple), child: const Icon(Icons.play_arrow, color: Colors.white, size: 32)),
                  ]),
                  const SizedBox(height: 20),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: progress.progress, minHeight: 10,
                      backgroundColor: Colors.black.withOpacity(0.3),
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF331F4D)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('$percent% Concluído', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PlaceholderCourseCard extends StatelessWidget {
  final bool isLoading;
  const _PlaceholderCourseCard({this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF492F71),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: isLoading ? null : () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CourseSelectionScreen())),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20.0),
          width: double.infinity,
          height: 158,
          child: isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text('Nenhum curso iniciado', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text('Clique para escolher um curso e começar a aprender!', style: TextStyle(color: Colors.white70, fontSize: 14)),
                ],
              ),
        ),
      ),
    );
  }
}