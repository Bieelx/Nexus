import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nexus_app/service/course_progress_service.dart'; 
import 'package:nexus_app/main.dart';

// As classes e funções no topo (ModuleSeed, generateGenericSeeds) permanecem as mesmas.
// Se precisar delas, me avise para eu incluir.

enum ModuleStatus { done, available, locked }

class CourseModulesScreen extends StatefulWidget {
  final String courseId;
  final String courseName;
  const CourseModulesScreen({super.key, required this.courseId, required this.courseName});

  @override
  State<CourseModulesScreen> createState() => _CourseModulesScreenState();
}

class _CourseModulesScreenState extends State<CourseModulesScreen> {
  late final String _uid;
  late final CourseProgressService _progressService;
  bool _editMode = false;

  @override
  void initState() {
    super.initState();
    _uid = FirebaseAuth.instance.currentUser?.uid ?? 'guest';
    _progressService = CourseProgressService();
    _bootstrapCourseIfEmpty();
    _progressService.updateLastAccessed(uid: _uid, courseId: widget.courseId, courseName: widget.courseName);
  }

  Future<void> _bootstrapCourseIfEmpty() async {
    final modsRef = FirebaseFirestore.instance.collection('courses').doc(widget.courseId).collection('modules');
    final hasAny = await modsRef.limit(1).get().then((snap) => snap.docs.isNotEmpty);
    if (hasAny) return;
    // Sua lógica de `seed` pode ser adicionada aqui se necessário.
  }
  
  void _toggleEditMode() => setState(() => _editMode = !_editMode);

  @override
  Widget build(BuildContext context) {
    final topSpacing = MediaQuery.of(context).size.height * (68 / 892);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            SizedBox(height: topSpacing),
            _Header(
              courseName: widget.courseName,
              isEditMode: _editMode,
              onLongPress: _toggleEditMode,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _ModuleList(
                courseId: widget.courseId,
                uid: _uid,
                progressService: _progressService,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String courseName;
  final bool isEditMode;
  final VoidCallback onLongPress;

  const _Header({required this.courseName, required this.isEditMode, required this.onLongPress});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          Material(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const MainNavigation()),
                  (Route<dynamic> route) => false,
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: const SizedBox(
                width: 44,
                height: 44,
                child: Icon(Icons.home_outlined, color: Colors.white, size: 22),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onLongPress: onLongPress,
              child: Text(
                isEditMode ? '$courseName  •  EDIT' : courseName,
                style: const TextStyle(color: Colors.white, fontSize: 20, fontFamily: 'Poppins', fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModuleList extends StatelessWidget {
  final String courseId;
  final String uid;
  final CourseProgressService progressService;

  const _ModuleList({
    required this.courseId, required this.uid, required this.progressService,
  });

  Stream<QuerySnapshot<Map<String, dynamic>>> _modulesStream() {
    return FirebaseFirestore.instance.collection('courses').doc(courseId).collection('modules').orderBy('order').snapshots();
  }

  Future<void> _markModuleDone(String moduleId, int moduleOrder, int totalModules) async {
    await progressService.markCompleted(
      uid: uid, courseId: courseId, moduleId: moduleId,
      moduleOrder: moduleOrder, totalModules: totalModules,
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<CourseProgress>(
      stream: progressService.watch(uid, courseId),
      builder: (context, progressSnap) {
        final courseProgress = progressSnap.data ?? CourseProgress.empty();
        final completedModules = courseProgress.completed;

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _modulesStream(),
          builder: (context, modSnap) {
            if (modSnap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!modSnap.hasData || modSnap.data!.docs.isEmpty) {
              return const Center(child: Text('Nenhum módulo encontrado.', style: TextStyle(color: Colors.white70)));
            }

            final modules = modSnap.data!.docs;
            final total = modules.length;
            final doneCount = completedModules.length;

            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              children: [
                _ProgressCard(percent: courseProgress.progress, done: doneCount, total: total),
                const SizedBox(height: 24),
                ...List.generate(modules.length, (i) {
                  final doc = modules[i];
                  final data = doc.data();
                  
                  // ===================== CORREÇÃO APLICADA AQUI =====================
                  // Calculamos a ordem em uma variável separada e bem definida.
                  final int moduleOrder = (data['order'] as num?)?.toInt() ?? i;

                  ModuleStatus status;
                  if (completedModules.contains(doc.id)) {
                    status = ModuleStatus.done;
                  } else if (doneCount == moduleOrder) { // Agora a comparação é simples e direta.
                    status = ModuleStatus.available;
                  } else {
                    status = ModuleStatus.locked;
                  }
                  // =================================================================
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: _ModuleCard(
                      title: data['title'] ?? '',
                      subtitle: data['description'] ?? '',
                      info: '${data['difficulty'] ?? ''} • ${data['durationMin'] ?? 0}min',
                      xp: (data['xp'] as num?)?.toInt() ?? 0,
                      status: status,
                      onTap: () async {
                        if (status != ModuleStatus.available) return;
                        
                        final completed = await Navigator.of(context).pushNamed(
                          '/lesson',
                          arguments: {'title': data['title'], 'assetPath': data['pdfAsset']},
                        );

                        if (completed == true) {
                          await _markModuleDone(doc.id, moduleOrder, total);
                        }
                      },
                    ),
                  );
                }),
                 const SizedBox(height: 24),
              ],
            );
          },
        );
      },
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.percent, required this.done, required this.total});
  final double percent;
  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF171B27),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF6B7691), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              _Square(color: Color(0xFF8447D6), size: 28, radius: 5),
              SizedBox(width: 8),
              Text('Progresso do curso', style: TextStyle(color: Color(0xFFAE85E5), fontSize: 16, fontFamily: 'Poppins', fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text('Aulas realizadas: $done/$total', style: const TextStyle(color: Color(0xFFD9D9D9), fontSize: 10, fontFamily: 'Poppins', fontWeight: FontWeight.w500)),
              const Spacer(),
              Text('${(percent * 100).round()}%', style: const TextStyle(color: Color(0xFFAE85E5), fontSize: 20, fontFamily: 'Poppins', fontWeight: FontWeight.w700)),
              const SizedBox(width: 4),
              const Text('completo', style: TextStyle(color: Colors.white, fontSize: 10, fontFamily: 'Poppins', fontWeight: FontWeight.w400)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 12,
              backgroundColor: const Color(0x9B7A7777),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF8447D6)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String info;
  final int xp;
  final ModuleStatus status;
  final VoidCallback? onTap;
  
  const _ModuleCard({
    required this.title,
    required this.subtitle,
    required this.info,
    required this.xp,
    required this.status,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color bg, border, titleColor, infoColor, iconColor, chipBg, chipText;

    switch (status) {
      case ModuleStatus.done:
        bg = const Color(0xAD32A370); border = const Color(0xFF67E69C); titleColor = const Color(0xFF9AEFBE);
        infoColor = const Color(0xFF9AEFBE); iconColor = const Color(0xFF9AEFBE); chipBg = const Color(0xFF9AEFBE); chipText = const Color(0xFF0EC058);
        break;
      case ModuleStatus.available:
        bg = const Color(0xB2634A9E); border = const Color(0xFF8447D6); titleColor = const Color(0xFFC9ADEF);
        infoColor = const Color(0xFFCAAEEF); iconColor = const Color(0xFFCAAEEF); chipBg = const Color(0xFFCAAEEF); chipText = const Color(0xFF9243FA);
        break;
      case ModuleStatus.locked:
        bg = const Color(0xB29C3F3F); border = const Color(0xFFD17374); titleColor = const Color(0xFFD17374);
        infoColor = const Color(0xFFD17374); iconColor = const Color(0xFFD17374); chipBg = const Color(0xFFD17374); chipText = const Color(0xFFD53A3C);
        break;
    }

    return Opacity(
      opacity: status == ModuleStatus.locked ? 0.7 : 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16), border: Border.all(color: border, width: 1)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Square(size: 35, color: Colors.white, radius: 8),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(color: titleColor, fontSize: 16, fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFFC6C5C3), fontSize: 10, fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(info, style: TextStyle(color: infoColor, fontSize: 11, fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: chipBg, borderRadius: BorderRadius.circular(4)),
                          child: Text('+$xp XP', style: TextStyle(color: chipText, fontSize: 11, fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(width: 20, height: 20, decoration: BoxDecoration(color: iconColor, shape: BoxShape.circle)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Square extends StatelessWidget {
  const _Square({required this.color, required this.size, required this.radius});
  final Color color;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(width: size, height: size, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(radius)));
  }
}