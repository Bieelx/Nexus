import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nexus_app/service/course_progress_service.dart';
import 'package:nexus_app/main.dart';
import 'package:timeline_tile/timeline_tile.dart';

// =================================================================
// ESTRUTURAS DE DADOS E FUNÇÕES AUXILIARES
// =================================================================

class ModuleSeed {
  final String title;
  final String description;
  final int durationMin;
  final String difficulty;
  final int xp;
  final String? pdfAsset;

  const ModuleSeed({
    required this.title,
    required this.description,
    required this.durationMin,
    required this.difficulty,
    required this.xp,
    this.pdfAsset,
  });

  Map<String, dynamic> toMap(int order) => {
        'title': title,
        'description': description,
        'durationMin': durationMin,
        'difficulty': difficulty,
        'xp': xp,
        'order': order,
        'createdAt': FieldValue.serverTimestamp(),
        if (pdfAsset != null) 'pdfAsset': pdfAsset,
      };
}

List<ModuleSeed> generateGenericSeeds(String courseId) {
  final List<ModuleSeed> seeds = [];
  for (int i = 0; i < 7; i++) {
    final n = i + 1;
    seeds.add(ModuleSeed(
      title: 'Módulo $n: Introdução',
      description: 'Conteúdo introdutório do curso "$courseId". Conceitos, exemplos e boas práticas.',
      durationMin: 12,
      difficulty: 'Fácil',
      xp: 25,
      pdfAsset: 'assets/pdfs/$courseId/mod_${n.toString().padLeft(2, '0')}.pdf',
    ));
  }
  seeds.add(ModuleSeed(
    title: 'Quiz final',
    description: 'Avalie seu conhecimento com um quiz de 10 perguntas. Concluindo o quiz você desbloqueia o certificado.',
    durationMin: 5,
    difficulty: 'Médio',
    xp: 50,
    pdfAsset: 'assets/pdfs/$courseId/quiz.pdf',
  ));
  return seeds;
}

enum ModuleStatus { done, available, locked }

// =================================================================
// TELA PRINCIPAL
// =================================================================

class CourseModulesScreen extends StatefulWidget {
  final String courseId;
  final String courseName;
  const CourseModulesScreen(
      {super.key, required this.courseId, required this.courseName});

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
    _progressService.updateLastAccessed(
        uid: _uid, courseId: widget.courseId, courseName: widget.courseName);
  }

  Future<void> _bootstrapCourseIfEmpty() async {
    final modsRef = FirebaseFirestore.instance
        .collection('courses')
        .doc(widget.courseId)
        .collection('modules');
    final hasAny =
        await modsRef.limit(1).get().then((snap) => snap.docs.isNotEmpty);
    if (hasAny) return;

    final seeds = generateGenericSeeds(widget.courseId);
    final batch = FirebaseFirestore.instance.batch();
    for (int i = 0; i < seeds.length; i++) {
      batch.set(modsRef.doc(), seeds[i].toMap(i));
    }
    await batch.commit();
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

// =================================================================
// WIDGETS DA TELA
// =================================================================

class _Header extends StatelessWidget {
  final String courseName;
  final bool isEditMode;
  final VoidCallback onLongPress;

  const _Header(
      {required this.courseName,
      required this.isEditMode,
      required this.onLongPress});

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
                  MaterialPageRoute(
                      builder: (context) => const MainNavigation()),
                  (Route<dynamic> route) => false,
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: const SizedBox(
                width: 44,
                height: 44,
                child: Icon(Icons.arrow_back, color: Colors.white, size: 22),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onLongPress: onLongPress,
              child: Text(
                isEditMode ? '$courseName  •  EDIT' : courseName,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600),
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
    required this.courseId,
    required this.uid,
    required this.progressService,
  });

  Stream<QuerySnapshot<Map<String, dynamic>>> _modulesStream() {
    return FirebaseFirestore.instance
        .collection('courses')
        .doc(courseId)
        .collection('modules')
        .orderBy('order')
        .snapshots();
  }

  Future<void> _markModuleDone(
      String moduleId, int moduleOrder, int totalModules) async {
    await progressService.markCompleted(
      uid: uid,
      courseId: courseId,
      moduleId: moduleId,
      moduleOrder: moduleOrder,
      totalModules: totalModules,
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
              return const Center(
                  child: Text('Nenhum módulo encontrado.',
                      style: TextStyle(color: Colors.white70)));
            }

            final modules = modSnap.data!.docs;
            final total = modules.length;
            final doneCount = completedModules.length;

            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: modules.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 24.0),
                    child: _ProgressCard(
                        percent: courseProgress.progress,
                        done: doneCount,
                        total: total),
                  );
                }

                final moduleIndex = index - 1;
                final doc = modules[moduleIndex];
                final data = doc.data();
                final int moduleOrder =
                    (data['order'] as num?)?.toInt() ?? moduleIndex;

                ModuleStatus status;
                if (completedModules.contains(doc.id)) {
                  status = ModuleStatus.done;
                } else if (doneCount == moduleOrder) {
                  status = ModuleStatus.available;
                } else {
                  status = ModuleStatus.locked;
                }

                // ========== CORREÇÃO 1: Cor da linha ANTES (baseada no módulo ATUAL) ==========
                Color beforeLineColor = const Color(0xFF434958);
                if (status == ModuleStatus.done) {
                  beforeLineColor = const Color(0xFF0FC059);
                } else if (status == ModuleStatus.available) {
                  beforeLineColor = const Color(0xFF8447D6);
                }

                // ========== CORREÇÃO 2: Cor da linha DEPOIS (baseada no PRÓXIMO módulo) ==========
                Color afterLineColor = const Color(0xFF434958);
                if (moduleIndex < modules.length - 1) {
                  final nextDoc = modules[moduleIndex + 1];
                  final int nextModuleOrder =
                      (nextDoc.data()['order'] as num?)?.toInt() ??
                          (moduleIndex + 1);
                  
                  ModuleStatus nextStatus;
                  if (completedModules.contains(nextDoc.id)) {
                    nextStatus = ModuleStatus.done;
                  } else if (doneCount == nextModuleOrder) {
                    nextStatus = ModuleStatus.available;
                  } else {
                    nextStatus = ModuleStatus.locked;
                  }
                  
                  if (nextStatus == ModuleStatus.done) {
                    afterLineColor = const Color(0xFF0FC059);
                  } else if (nextStatus == ModuleStatus.available) {
                    afterLineColor = const Color(0xFF8447D6);
                  }
                }

                // ========== CORREÇÃO 3: Cards centralizados com timeline junto ==========
                return TimelineTile(
                  axis: TimelineAxis.vertical,
                  alignment: TimelineAlign.manual,
                  lineXY: 0.15, // Posiciona a linha ~15% da esquerda (ajuste conforme necessário)
                  isFirst: moduleIndex == 0,
                  isLast: moduleIndex == modules.length - 1,

                  beforeLineStyle: LineStyle(
                    color: beforeLineColor,
                    thickness: 2,
                  ),
                  afterLineStyle: LineStyle(
                    color: afterLineColor,
                    thickness: 2,
                  ),
                  
                  indicatorStyle: IndicatorStyle(
                    width: 24,
                    height: 24,
                    indicator: _TimelineIndicator(status: status),
                  ),
                  
                  // Card centralizado no espaço disponível à direita da timeline
                  endChild: Center(
                    child: _buildModuleContent(
                      context, 
                      doc.id, 
                      data, 
                      status, 
                      moduleOrder, 
                      total
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildModuleContent(
      BuildContext context,
      String docId,
      Map<String, dynamic> data,
      ModuleStatus status,
      int moduleOrder,
      int total) {
    
    // Tamanho fixo do card
    const double cardSize = 128.0;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ModuleCard(
            cardSize: cardSize,
            title: data['title'] ?? '',
            xp: (data['xp'] as num?)?.toInt() ?? 0,
            status: status,
            onTap: () async {
              if (status != ModuleStatus.available) return;
              final completed = await Navigator.of(context).pushNamed(
                '/lesson',
                arguments: {
                  'title': data['title'],
                  'assetPath': data['pdfAsset']
                },
              );
              if (completed == true) {
                await _markModuleDone(docId, moduleOrder, total);
              }
            },
          ),
          const SizedBox(height: 16),
          _ModuleText(
            title: data['title'] ?? '',
            info:
                '${data['difficulty'] ?? ''} • ${data['durationMin'] ?? 0}min',
            status: status,
          ),
        ],
      ),
    );
  }
}

// =================================================================
// WIDGETS DE ESTILO
// =================================================================

class _DashedLine extends StatelessWidget {
  final Color color;
  final double dashWidth;
  final double dashSpace;
  final double thickness;

  const _DashedLine({
    required this.color,
    this.dashWidth = 6.0,
    this.dashSpace = 6.0,
    this.thickness = 2.0,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final boxHeight = constraints.maxHeight;
        final dashCount = (boxHeight / (dashWidth + dashSpace)).floor();
        return Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(dashCount, (_) {
            return Container(
              width: thickness,
              height: dashWidth,
              color: color,
            );
          }),
        );
      },
    );
  }
}

class _TimelineIndicator extends StatelessWidget {
  final ModuleStatus status;
  const _TimelineIndicator({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color, innerColor;
    switch (status) {
      case ModuleStatus.done:
        color = const Color(0xFF0FC059);
        innerColor = Colors.white;
        break;
      case ModuleStatus.available:
        color = const Color(0xFF8447D6);
        innerColor = const Color(0xFFCAAEEF);
        break;
      case ModuleStatus.locked:
      default:
        color = const Color(0xFF434958);
        innerColor = const Color(0xFF171C27);
        break;
    }
    return Container(
      decoration: BoxDecoration(
        color: innerColor,
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 4),
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard(
      {required this.percent, required this.done, required this.total});
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
        children: [
          Row(
            children: [
              Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                      color: const Color(0xFF8447D6),
                      borderRadius: BorderRadius.circular(5)),
                  child:
                      const Icon(Icons.shield, color: Colors.white, size: 16)),
              const SizedBox(width: 8),
              const Text('Progresso do curso',
                  style: TextStyle(
                      color: Color(0xFFAE85E5),
                      fontSize: 16,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w500)),
              const Spacer(),
              Text('${(percent * 100).round()}%',
                  style: const TextStyle(
                      color: Color(0xFFAE85E5),
                      fontSize: 16,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 12,
              backgroundColor: const Color(0x9B7A7777),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Color(0xFF8447D6)),
            ),
          ),
          const SizedBox(height: 4),
          Text('Aulas realizadas: $done/$total',
              style: const TextStyle(
                  color: Color(0xFFD9D9D9),
                  fontSize: 10,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  final double cardSize;
  final String title;
  final int xp;
  final ModuleStatus status;
  final VoidCallback? onTap;

  const _ModuleCard({
    required this.cardSize,
    required this.title,
    required this.xp,
    required this.status,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color gradientStart, gradientEnd, shadowColor, innerColor, indicatorColor;
    IconData iconData;
    Widget? indicatorChild;
    double iconSize = cardSize * 0.5;

    switch (status) {
      case ModuleStatus.done:
        gradientStart = const Color(0xFF33A471);
        gradientEnd = const Color(0xFF0FC059);
        shadowColor = const Color(0x4C00C850);
        innerColor = const Color(0xFF2A3F35);
        indicatorColor = const Color(0xFF0EC058);
        iconData = Icons.shield_outlined;
        indicatorChild = const Icon(Icons.check, color: Colors.white, size: 16);
        break;
      case ModuleStatus.available:
        gradientStart = const Color(0xFF8447D6);
        gradientEnd = const Color(0xFF634A9E);
        shadowColor = const Color(0x948447D6);
        innerColor = const Color(0xFF2D2440);
        indicatorColor = const Color(0xFFCAAEEF);
        iconData = Icons.play_arrow;
        indicatorChild = Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF8447D6).withOpacity(0.7)));
        iconSize = cardSize * 0.625;
        break;
      case ModuleStatus.locked:
        gradientStart = const Color(0xFF9C3F3F);
        gradientEnd = const Color(0xFF6D2C2C);
        shadowColor = const Color(0x19000000);
        innerColor = const Color(0xFF3A2828);
        indicatorColor = const Color(0xFFD17374);
        iconData = Icons.lock_outline;
        indicatorChild = const Icon(Icons.lock, color: Colors.white, size: 14);
        break;
    }

    return Opacity(
      opacity: status == ModuleStatus.locked ? 0.6 : 1.0,
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: cardSize,
          height: cardSize,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [gradientStart, gradientEnd],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: shadowColor.withOpacity(0.4),
                  blurRadius: status == ModuleStatus.locked ? 6 : 15,
                  spreadRadius: status == ModuleStatus.locked ? -4 : 0,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                      color: innerColor,
                      borderRadius: BorderRadius.circular(22)),
                  child: Icon(iconData,
                      color: Colors.white.withOpacity(0.8), size: iconSize),
                ),
                Positioned(
                  top: -8,
                  right: -8,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                        color: indicatorColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4))
                        ]),
                    alignment: Alignment.center,
                    child: indicatorChild,
                  ),
                ),
                Positioned(
                  bottom: -16,
                  left: 0,
                  right: 0,
                  child: Center(child: _XpChip(status: status, xp: xp)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _XpChip extends StatelessWidget {
  final ModuleStatus status;
  final int xp;
  const _XpChip({required this.status, required this.xp});

  @override
  Widget build(BuildContext context) {
    Color bgColor, textColor;
    switch (status) {
      case ModuleStatus.done:
        bgColor = const Color(0xFF9BF0BE);
        textColor = const Color(0xFF0EC058);
        break;
      case ModuleStatus.available:
        bgColor = const Color(0xFFCAAEEF);
        textColor = const Color(0xFF9243FA);
        break;
      case ModuleStatus.locked:
        bgColor = const Color(0x7FD17374);
        textColor = const Color(0xFFD63A3C);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Text('+$xp XP',
          style: TextStyle(
              color: textColor,
              fontSize: 11,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600)),
    );
  }
}

class _ModuleText extends StatelessWidget {
  final String title;
  final String info;
  final ModuleStatus status;
  const _ModuleText(
      {required this.title, required this.info, required this.status});

  @override
  Widget build(BuildContext context) {
    Color titleColor, infoColor;
    switch (status) {
      case ModuleStatus.done:
        titleColor = const Color(0xFF9BF0BE);
        infoColor = const Color(0xFF9BF0BE);
        break;
      case ModuleStatus.available:
        titleColor = const Color(0xFFCAAEEF);
        infoColor = const Color(0xFFCAAEEF);
        break;
      case ModuleStatus.locked:
        titleColor = const Color(0xFFD17374);
        infoColor = const Color(0xFFD17374);
        break;
    }

    return Opacity(
      opacity: status == ModuleStatus.locked ? 0.6 : 1.0,
      child: Column(
        children: [
          Text(title,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: titleColor,
                  fontSize: 15,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(info,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: infoColor,
                  fontSize: 10,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}