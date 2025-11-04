import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Importe o Firestore
import 'package:flutter_markdown/flutter_markdown.dart';

class LessonScreen extends StatefulWidget {
  // Agora precisamos saber de ONDE carregar os dados
  final String courseId;
  final String moduleId;

  // O 'title' e 'courseTitle' virão do Firebase
  // mas podemos recebê-los para exibir enquanto carrega
  final String? initialTitle; 

  const LessonScreen({
    super.key,
    required this.courseId,
    required this.moduleId,
    this.initialTitle,
  });

  /// Helper para construir a tela usando argumentos vindos da rota.
  static Widget fromRouteArgs(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) {
      // Supondo que sua tela anterior (lista de módulos) passe esses IDs
      return LessonScreen(
        courseId: args['courseId'] as String? ?? 'seguranca-digital-iniciantes',
        moduleId: args['moduleId'] as String? ?? 'mod-01',
        initialTitle: (args['title'] as String?) ?? 'Carregando...',
      );
    }
    // Fallback para teste
    return const LessonScreen(
      courseId: 'seguranca-digital-iniciantes',
      moduleId: 'mod-01',
      initialTitle: 'Carregando...',
    );
  }

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  final ScrollController _scrollController = ScrollController();
  late Future<DocumentSnapshot> _lessonFuture;
  
  double _fontSize = 16.0; 
  bool _isAtEnd = false; 

  @override
  void initState() {
    super.initState();
    // Prepara o Future para buscar o documento do módulo
    _lessonFuture = FirebaseFirestore.instance
        .collection('courses')
        .doc(widget.courseId)
        .collection('modules')
        .doc(widget.moduleId)
        .get();
        
    _scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 100) {
      if (!_isAtEnd) setState(() => _isAtEnd = true);
    } else {
      if (_isAtEnd) setState(() => _isAtEnd = false);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _zoomIn() => setState(() => _fontSize = (_fontSize + 2).clamp(12.0, 28.0));
  void _zoomOut() => setState(() => _fontSize = (_fontSize - 2).clamp(12.0, 28.0));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(0.54, 0.51),
            end: Alignment(-0.04, 0.95),
            colors: [Color(0xFF1B202E), Color(0xFF252C3A)],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: FutureBuilder<DocumentSnapshot>(
            // O Future agora busca os dados do Firebase
            future: _lessonFuture,
            builder: (context, snapshot) {
              
              // Pega os dados do módulo ou usa fallbacks
              String title = widget.initialTitle ?? 'Carregando...';
              String markdownContent = '';
              bool isLoading = true;
              
              if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
                final data = snapshot.data!.data() as Map<String, dynamic>;
                title = data['title'] as String? ?? 'Aula';
                markdownContent = data['content'] as String? ?? 'Erro: Conteúdo não encontrado.';
                isLoading = false;
              } else if (snapshot.hasError) {
                title = 'Erro';
                markdownContent = 'Erro ao carregar a aula. Tente novamente.';
                isLoading = false;
              }
              
              // O build da UI é feito aqui dentro
              return Column(
                children: [
                  _Header(title: title, subtitle: null), // Simplifiquei o Header
                  const SizedBox(height: 8),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          color: const Color(0xFFFAF9F6), // Fundo "papel"
                          child: _buildMarkdownViewer(markdownContent, isLoading),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _BottomBar(
                    onZoomOut: _zoomOut,
                    onZoomIn: _zoomIn,
                    onConcluir: _isAtEnd ? () => Navigator.of(context).pop(true) : null,
                  ),
                  const SizedBox(height: 12),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  /// Este widget agora recebe o conteúdo como parâmetro
  Widget _buildMarkdownViewer(String markdownData, bool isLoading) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (markdownData.startsWith('Erro:')) {
      return Center(
        child: Text(markdownData, style: const TextStyle(color: Colors.black87)),
      );
    }
    
    return Scrollbar(
      controller: _scrollController,
      child: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(20.0), // Padding interno
        child: MarkdownBody(
          data: markdownData,
          styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
            p: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: _fontSize,
                  color: Colors.black87,
                  height: 1.5,
                ),
            h1: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontSize: _fontSize + 8,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
            h2: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontSize: _fontSize + 4,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
          ),
        ),
      ),
    );
  }
}

// ==========================================================
// Widgets de UI (Sem alteração da sua versão anterior)
// =O HEADER FOI SIMPLIFICADO PORQUE O FUTUREBUILDER O CONTROLA
// ==========================================================

class _Header extends StatelessWidget {
  final String title;
  final String? subtitle;
  const _Header({required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    // Mantive sua lógica de padding complexa
    final media = MediaQuery.of(context);
    final statusBar = media.padding.top;
    const desiredTop = 68.0; 
    final double topPad = (desiredTop - statusBar).clamp(0.0, 200.0).toDouble();

    return Padding(
      padding: EdgeInsets.fromLTRB(16, topPad, 16, 0),
      child: Row(
        children: [
          const SizedBox(width: 8),
          const _BackButton(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (subtitle != null && subtitle!.isNotEmpty)
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 32),
        ],
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => Navigator.of(context).maybePop(),
        child: const Padding(
          padding: EdgeInsets.all(8.0),
          child: Icon(Icons.chevron_left, color: Color(0xFFAE85E5), size: 28),
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final VoidCallback? onZoomOut;
  final VoidCallback? onZoomIn;
  final VoidCallback? onConcluir;

  const _BottomBar({
    this.onZoomOut,
    this.onZoomIn,
    this.onConcluir,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 55,
        decoration: BoxDecoration(
          color: const Color(0xB2434958),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            _roundButton(Icons.remove, onZoomOut), 
            const SizedBox(width: 8),
            _roundButton(Icons.add, onZoomIn), 
            const SizedBox(width: 8),
            const Icon(Icons.format_size, color: Colors.white70, size: 20),
            const Spacer(), 
            _primaryButton(
              'Concluir', 
              onConcluir,
              isEnabled: onConcluir != null 
            ),
          ],
        ),
      ),
    );
  }

  Widget _roundButton(IconData icon, VoidCallback? onTap) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 39,
        height: 39,
        decoration: const BoxDecoration(
          color: Color(0xFF434958),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }

  Widget _primaryButton(String label, VoidCallback? onTap, {bool isEnabled = true}) {
    const activeGradient = LinearGradient(
      begin: Alignment(0.00, 0.83),
      end: Alignment(0.84, 0.37),
      colors: [
        Color(0xFFAE85E5),
        Color(0xFF8447D6),
        Color(0xFF572698),
      ],
    );
    const disabledGradient = LinearGradient(
      colors: [Color(0xFF6f6f6f), Color(0xFF6f6f6f)],
    );

    return InkWell(
      onTap: onTap, 
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 110,
        height: 39,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: isEnabled ? activeGradient : disabledGradient,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(
            color: Color(0xFFFEF7FF),
            fontSize: 12,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
            height: 1.83,
          ),
        ),
      ),
    );
  }
}