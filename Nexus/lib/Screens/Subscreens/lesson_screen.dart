import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class PdfReaderScreen extends StatefulWidget {
  final String title;
  final String? courseTitle;
  final String? assetPath;
  final String? pdfUrl;

  const PdfReaderScreen({
    super.key,
    required this.title,
    this.courseTitle,
    this.assetPath,
    this.pdfUrl,
  });

  /// Helper para construir a tela usando argumentos vindos da rota.
  static Widget fromRouteArgs(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) {
      return PdfReaderScreen(
        title: (args['title'] as String?) ?? 'Aula',
        courseTitle: args['courseTitle'] as String?,
        assetPath: args['assetPath'] as String?,
        pdfUrl: args['pdfUrl'] as String?,
      );
    }
    return const PdfReaderScreen(title: 'Aula');
  }

  @override
  State<PdfReaderScreen> createState() => _PdfReaderScreenState();
}

/// Wrapper para compatibilidade: alguns pontos do app referenciam `LessonScreen`.
/// Agora usamos composição para evitar conflito de generics de StatefulWidget.
class LessonScreen extends StatelessWidget {
  final String title;
  final String? courseTitle;
  final String? assetPath;
  final String? pdfUrl;

  const LessonScreen({
    super.key,
    required this.title,
    this.courseTitle,
    this.assetPath,
    this.pdfUrl,
  });

  /// Mantém a mesma conveniência de criar a tela a partir dos argumentos da rota.
  static Widget fromRouteArgs(BuildContext context) =>
      PdfReaderScreen.fromRouteArgs(context);

  @override
  Widget build(BuildContext context) {
    return PdfReaderScreen(
      title: title,
      courseTitle: courseTitle,
      assetPath: assetPath,
      pdfUrl: pdfUrl,
    );
  }
}

class _PdfReaderScreenState extends State<PdfReaderScreen> {
  final PdfViewerController _controller = PdfViewerController();
  int _page = 1;
  int _pageCount = 0;
  bool _docError = false;

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
          child: Column(
            children: [
              _Header(title: widget.title, subtitle: widget.courseTitle),
              const SizedBox(height: 8),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      color: const Color(0xFFFAF9F6),
                      child: _buildViewer(),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _BottomBar(
                page: _page,
                pageCount: _pageCount,
                onPrev: _page > 1 ? _controller.previousPage : null,
                onNext: _pageCount == 0
                    ? null
                    : () {
                        if (_page < _pageCount) {
                          _controller.nextPage();
                        } else {
                          // Finalizou a leitura
                          Navigator.of(context).pop(true);
                        }
                      },
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildViewer() {
    if (_docError) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'PDF não disponível.',
            style: TextStyle(color: Colors.black87),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // Força o PDF de teste por padrão
    final String? asset = widget.assetPath ?? 'assets/pdfs/seguranca-digital/mod_01.pdf';
    final String? url = widget.pdfUrl;

    print('Starting asset check...');
    print('Asset path: $asset');
    if (asset != null && asset.isNotEmpty) {
      print('Loading PDF from asset: $asset');
      return _NoScrollOverlay(
        child: SfPdfViewer.asset(
          asset,
          controller: _controller,
          pageLayoutMode: PdfPageLayoutMode.single,
          pageSpacing: 0, // remove espaço entre páginas
          initialZoomLevel: 1.40, // dá um zoom para "preencher" melhor
          enableTextSelection: false,
          enableDoubleTapZooming: false,
          canShowScrollHead: false,
          canShowPaginationDialog: false,
          canShowScrollStatus: false,
          onDocumentLoaded: (details) {
            print('Document loaded with ${details.document.pages.count} pages');
            setState(() {
              _pageCount = details.document.pages.count;
              _page = _controller.pageNumber;
            });
          },
          onPageChanged: (details) {
            setState(() => _page = details.newPageNumber);
          },
          onDocumentLoadFailed: (error) {
            print('Document load failed with error: $error');
            print('Asset load failed: $asset, error: $error');
            setState(() {
              _docError = true;
              print('_docError set to true');
            });
          },
        ),
      );
    }

    print('Starting pdfUrl check...');
    print('pdfUrl: $url');
    if (url != null && url.isNotEmpty) {
      print('Loading PDF from network: $url');
      return _NoScrollOverlay(
        child: SfPdfViewer.network(
          url,
          controller: _controller,
          pageLayoutMode: PdfPageLayoutMode.single,
          pageSpacing: 0,
          initialZoomLevel: 1.40,
          enableTextSelection: false,
          enableDoubleTapZooming: false,
          canShowScrollHead: false,
          canShowPaginationDialog: false,
          canShowScrollStatus: false,
          onDocumentLoaded: (details) {
            print('Document loaded with ${details.document.pages.count} pages');
            setState(() {
              _pageCount = details.document.pages.count;
              _page = _controller.pageNumber;
            });
          },
          onPageChanged: (details) {
            setState(() => _page = details.newPageNumber);
          },
          onDocumentLoadFailed: (error) {
            print('Document load failed with error: $error');
            print('Network load failed: $url, error: $error');
            setState(() {
              _docError = true;
              print('_docError set to true');
            });
          },
        ),
      );
    }

    print('Falling back: PDF não disponível para esta aula. Asset: $asset, Url: $url');
    return const Center(
      child: Text(
        'PDF não disponível para esta aula.',
        style: TextStyle(color: Colors.black87),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String title;
  final String? subtitle;
  const _Header({required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final statusBar = media.padding.top; // SafeArea already applies this
    const desiredTop = 68.0;            // target distance from very top
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
  final int page;
  final int pageCount;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  const _BottomBar({
    required this.page,
    required this.pageCount,
    this.onPrev,
    this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final isLast = pageCount > 0 && page >= pageCount;

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
            _roundButton(Icons.chevron_left, onPrev),
            const SizedBox(width: 16),
            Expanded(child: _pageIndicator(page, pageCount)),
            const SizedBox(width: 16),
            _primaryButton(isLast ? 'Concluir' : 'Próximo', onNext),
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

  Widget _primaryButton(String label, VoidCallback? onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 110,
        height: 39,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            begin: Alignment(0.00, 0.83),
            end: Alignment(0.84, 0.37),
            colors: [
              Color(0xFFAE85E5),
              Color(0xFF8447D6),
              Color(0xFF572698),
            ],
          ),
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

  Widget _pageIndicator(int page, int total) {
    // Para PDFs grandes, exiba "X/Y"
    if (total > 6 || total == 0) {
      return Center(
        child: Text(
          total == 0 ? ' ' : '$page / $total',
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) {
        final active = (i + 1) == page;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 12 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: active ? const Color(0xFFAE85E5) : const Color(0xFF6C52BB),
            borderRadius: BorderRadius.circular(8),
          ),
        );
      }),
    );
  }
}

class _NoScrollOverlay extends StatelessWidget {
  final Widget child;
  const _NoScrollOverlay({required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        // Captura gestos de arraste para impedir scroll manual entre páginas
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onHorizontalDragStart: (_) {},
            onHorizontalDragUpdate: (_) {},
            onHorizontalDragEnd: (_) {},
            onVerticalDragStart: (_) {},
            onVerticalDragUpdate: (_) {},
            onVerticalDragEnd: (_) {},
          ),
        ),
      ],
    );
  }
}
