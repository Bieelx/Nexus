import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class NewsItem {
  final String title;
  final String? url;
  final String source;
  final DateTime? createdAt;
  final int points;

  NewsItem({
    required this.title,
    required this.url,
    required this.source,
    required this.createdAt,
    required this.points,
  });
}

class NewsFeedWidget extends StatefulWidget {
  /// Ex.: "cybersecurity", "infosec", "technology", "ai"
  final String query;

  const NewsFeedWidget({super.key, this.query = 'AI'});

  @override
  State<NewsFeedWidget> createState() => _NewsFeedWidgetState();
}

class _NewsFeedWidgetState extends State<NewsFeedWidget> {
  late Future<List<NewsItem>> _future;

  @override
  void initState() {
    super.initState();
    _future = _fetchNews(widget.query);
  }

  Future<List<NewsItem>> _fetchNews(String q) async {
    final uri = Uri.parse(
      // Stories recentes; mude "search" -> "search_by_date" pra priorizar novidade
      'https://hn.algolia.com/api/v1/search?tags=story&query=$q',
    );

    final resp = await http.get(uri);
    if (resp.statusCode != 200) {
      throw Exception('Falha ao buscar notícias (${resp.statusCode})');
    }

    final json = jsonDecode(resp.body) as Map<String, dynamic>;
    final hits = (json['hits'] as List).cast<Map<String, dynamic>>();

    return hits.map((h) {
      return NewsItem(
        title: (h['title'] ?? '').toString(),
        url: (h['url'] as String?),
        source: (h['author'] ?? 'HN').toString(),
        createdAt: h['created_at'] != null ? DateTime.tryParse(h['created_at']) : null,
        points: (h['points'] ?? 0) is int ? h['points'] as int : 0,
      );
    }).toList();
  }

  Future<void> _openUrl(String? url) async {
    if (url == null || url.isEmpty) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Se já criou seu AppColors, use; senão mantenha esses defaults
    const box = Color(0xFF393939);
    const text = Color(0xFFFAF9F6);
    const purple = Color(0xFFA259FF);

    return Container(
      height: 274,
      width: double.infinity,
      decoration: BoxDecoration(
        color: box,
        borderRadius: BorderRadius.circular(29),
      ),
      padding: const EdgeInsets.all(12),
      child: FutureBuilder<List<NewsItem>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Text(
                'Erro ao carregar notícias:\n${snap.error}',
                style: const TextStyle(color: text),
                textAlign: TextAlign.center,
              ),
            );
          }
          final items = snap.data ?? const [];
          if (items.isEmpty) {
            return const Center(
              child: Text('Sem resultados agora.', style: TextStyle(color: text)),
            );
          }

          // Layout tipo “map card”: conteúdo à direita, deixando “respiro” à esquerda
          return Row(
            children: [
              const SizedBox(width: 16), // margem à esquerda pra lembrar o antigo layout
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: ListView.separated(
                    itemCount: items.length.clamp(0, 10), // limita a 10
                    separatorBuilder: (_, __) => const Divider(
                      height: 12, thickness: 0.5, color: Colors.black26),
                    itemBuilder: (context, i) {
                      final n = items[i];
                      return ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                        title: Text(
                          n.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: text,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          '${n.source}${n.points > 0 ? ' • ${n.points} pts' : ''}'
                          '${n.createdAt != null ? ' • ${n.createdAt!.toLocal().toString().substring(0,16)}' : ''}',
                          style: TextStyle(color: text.withOpacity(0.7), fontSize: 12),
                        ),
                        trailing: const Icon(Icons.open_in_new, color: purple, size: 18),
                        onTap: () => _openUrl(n.url),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}