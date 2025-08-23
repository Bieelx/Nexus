import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/services.dart'; 
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../service/news_ai_service.dart' as newsai; // Gemini summarizer

class _NewsHttp {
  static final _cache = <String, (DateTime, Map<String, dynamic>)>{};
  static DateTime? _lastCall;
  static const _minGap = Duration(milliseconds: 1200); // NewsAPI: ~1 req/seg

  static Future<Map<String, dynamic>> getJson(Uri uri) async {
    // simple in-memory cache for 10 minutes
    final key = uri.toString();
    final now = DateTime.now();
    final hit = _cache[key];
    if (hit != null && now.difference(hit.$1) < const Duration(minutes: 10)) {
      return hit.$2;
    }

    // respect per-second rate limit
    final last = _lastCall;
    if (last != null) {
      final wait = _minGap - now.difference(last);
      if (wait > Duration.zero) {
        await Future.delayed(wait);
      }
    }

    final resp = await http.get(uri);
    _lastCall = DateTime.now();

    if (resp.statusCode == 429) {
      // Retry-After header (seconds) or backoff default 2.5s, try up to 2 times
      final retryH = resp.headers['retry-after'];
      final backoff = Duration(seconds: int.tryParse(retryH ?? '') ?? 3);
      for (int i = 0; i < 2; i++) {
        await Future.delayed(backoff + Duration(milliseconds: 200));
        final r2 = await http.get(uri);
        _lastCall = DateTime.now();
        if (r2.statusCode == 200) {
          final data = jsonDecode(r2.body) as Map<String, dynamic>;
          _cache[key] = (DateTime.now(), data);
          return data;
        }
      }
      throw Exception('Limite de requisições atingido (429). Tente novamente em instantes.');
    }

    if (resp.statusCode != 200) {
      throw Exception('Falha ao buscar notícias (${resp.statusCode})');
    }

    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    _cache[key] = (DateTime.now(), data);
    return data;
  }
}

/// ===== Firestore cache (30 min TTL) =====
class _NewsCacheItem {
  final String title;
  final String? url;
  final String source;
  final DateTime? createdAt;
  final int points;

  _NewsCacheItem({required this.title, this.url, required this.source, this.createdAt, required this.points});

  Map<String, dynamic> toMap() => {
    'title': title,
    'url': url,
    'source': source,
    'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
    'points': points,
  }..removeWhere((k, v) => v == null);

  static _NewsCacheItem fromMap(Map<String, dynamic> m) => _NewsCacheItem(
    title: (m['title'] ?? '').toString(),
    url: m['url'] as String?,
    source: (m['source'] ?? '').toString(),
    createdAt: m['createdAt'] is Timestamp ? (m['createdAt'] as Timestamp).toDate() : null,
    points: (m['points'] is int) ? m['points'] as int : int.tryParse('${m['points'] ?? 0}') ?? 0,
  );

  NewsItem toNewsItem() => NewsItem(title: title, url: url, source: source, createdAt: createdAt, points: points);
  static _NewsCacheItem fromNewsItem(NewsItem n) => _NewsCacheItem(title: n.title, url: n.url, source: n.source, createdAt: n.createdAt, points: n.points);
}

class _NewsFirestoreCache {
  static const _collection = 'news_cache';
  static const ttl = Duration(minutes: 30);

  static String _docIdFor(NewsFilter f) => switch (f) {
    NewsFilter.todos => 'todos',
    NewsFilter.ia => 'ia',
    NewsFilter.lancamentos => 'lancamentos',
    NewsFilter.ciberseguranca => 'ciberseguranca',
  };

  static Future<List<NewsItem>?> read(NewsFilter f) async {
    try {
      final doc = await FirebaseFirestore.instance.collection(_collection).doc(_docIdFor(f)).get();
      if (!doc.exists) return null;
      final data = doc.data()!;
      final ts = data['updatedAt'];
      if (ts is! Timestamp) return null;
      final updated = ts.toDate();
      if (DateTime.now().difference(updated) > ttl) return null; // stale
      final List items = (data['items'] as List? ?? const []);
      return items
          .whereType<Map<String, dynamic>>()
          .map((m) => _NewsCacheItem.fromMap(m).toNewsItem())
          .toList();
    } catch (_) {
      return null;
    }
  }

  static Future<void> write(NewsFilter f, List<NewsItem> items) async {
    try {
      final maps = items.map(_NewsCacheItem.fromNewsItem).map((e) => e.toMap()).toList();
      await FirebaseFirestore.instance.collection(_collection).doc(_docIdFor(f)).set({
        'updatedAt': Timestamp.fromDate(DateTime.now()),
        'items': maps,
      }, SetOptions(merge: true));
    } catch (_) {
      // ignore cache write errors
    }
  }
}


const String _NEWSAPI_KEY = 'a01552b3fd0343a6af71994149bc785c';

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

enum NewsFilter { todos, ia, lancamentos, ciberseguranca }

extension on NewsFilter {
  String get label {
    switch (this) {
      case NewsFilter.todos: return 'Todos';
      case NewsFilter.ia: return 'IA';
      case NewsFilter.lancamentos: return 'Lançamentos';
      case NewsFilter.ciberseguranca: return 'Cibersegurança';
    }
  }

  String get query {
    switch (this) {
      case NewsFilter.todos:
        return '';
      case NewsFilter.ia:
        return 'IA OR "inteligência artificial" OR LLM OR GPT OR ChatGPT';
      case NewsFilter.lancamentos:
        // restringe a lançamentos ligados a tech/produtos/softwares
        return '(lançamento OR lançou OR "nova versão" OR atualização OR update OR release) AND (app OR software OR sistema OR Windows OR Android OR iOS OR Linux OR Apple OR Google OR Microsoft OR Meta OR Samsung OR WhatsApp OR Instagram)';
      case NewsFilter.ciberseguranca:
        return '(cibersegurança OR cybersecurity OR vulnerabilidade OR CVE OR exploit OR ransomware OR phishing OR "vazamento de dados") AND (site OR servidor OR sistema OR Windows OR Linux OR Android OR iOS OR Microsoft OR Google OR Apple OR cloud OR nuvem)';
    }
  }

  IconData get icon {
    switch (this) {
      case NewsFilter.todos: return Icons.auto_awesome;
      case NewsFilter.ia: return Icons.psychology_alt;
      case NewsFilter.lancamentos: return Icons.rocket_launch;
      case NewsFilter.ciberseguranca: return Icons.shield_outlined;
    }
  }
}

class NewsFeedWidget extends StatefulWidget {
  final String query;
  final VoidCallback? onSummarizeTap;
  const NewsFeedWidget({super.key, this.query = 'AI', this.onSummarizeTap});

  @override
  State<NewsFeedWidget> createState() => _NewsFeedWidgetState();
}

class _NewsFeedWidgetState extends State<NewsFeedWidget> {
  late Future<List<NewsItem>> _future;
  NewsFilter _selected = NewsFilter.todos;
  bool _aiLoading = false;
  List<NewsItem> _lastItems = [];
  String get _currentFilterLabel => _selected.label;

  Future<List<NewsItem>> _getWithCache(NewsFilter f) async {
    // 1) try fresh cache
    final cached = await _NewsFirestoreCache.read(f);
    if (cached != null && cached.isNotEmpty) {
      // schedule silent background refresh if cache is close to expiring
      // (non-blocking)
      // ignore: unawaited_futures
      Future(() async {
        try {
          final fresh = (f == NewsFilter.todos) ? await _fetchAll() : await _fetchNews(f.query);
          await _NewsFirestoreCache.write(f, fresh);
        } catch (_) {}
      });
      return cached;
    }

    // 2) no cache or stale -> fetch now and store
    final fresh = (f == NewsFilter.todos) ? await _fetchAll() : await _fetchNews(f.query);
    // persist for next loads
    await _NewsFirestoreCache.write(f, fresh);
    return fresh;
  }

  String _norm(String s) {
    final lower = s.toLowerCase();
    // remoção simples de acentos comuns (sem libs externas)
    return lower
        .replaceAll('á', 'a').replaceAll('à', 'a').replaceAll('ã', 'a').replaceAll('â', 'a')
        .replaceAll('é', 'e').replaceAll('ê', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o').replaceAll('õ', 'o').replaceAll('ô', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ç', 'c');
  }

  List<NewsItem> _filterLocal(List<NewsItem> items, NewsFilter f) {
    if (f == NewsFilter.todos) return items;

    bool any(String text, List<String> terms) {
      final t = _norm(text);
      for (final k in terms) {
        if (t.contains(_norm(k))) return true;
      }
      return false;
    }

    final coreTech = <String>[
      // plataformas/OS/ecossistemas
      'android','ios','windows','linux','macos','apple','google','microsoft','meta','aws','azure','nuvem','cloud',
      // produtos/termos gerais de tech
      'software','app','aplicativo','sistema','plataforma','site','servidor','rede','data center','datacenter','codigo','código','github','api','chip','gpu','cpu','firmware','hardware','smartphone','notebook','pc','patch','atualizacao','atualização','versao','versão','recurso','feature',
      // marcas comuns no seu app
      'samsung','nvidia','intel','amd','whatsapp','instagram','facebook','x ','twitter','threads','youtube','tiktok'
    ];

    final blacklist = <String>[
      // esporte/política/geral
      'futebol','jogo','torcedor','torcedores','onibus','ônibus','gremio','palmeiras','flamengo','corinthians',
      'eleicao','eleições','senado','camara','câmara','politica','política','governo','trump','ministro','prefeito',
      'crime','assassinato','acidente','chuva','tempo','previsao','previsão','celebridade','famoso','show','concerto',
      'ucrania','ucrânia','guerra','drone','drones','russia','rússia','ataque militar','fronteira'
    ];

    final kws = () {
      switch (f) {
        case NewsFilter.ia:
          return [
            'ia','inteligencia artificial','inteligência artificial','gpt','chatgpt','llm','openai','modelo generativo','machine learning','aprendizado de maquina','aprendizado de máquina','deep learning'
          ];
        case NewsFilter.lancamentos:
          return [
            'lancamento','lançamento','lancou','lançou','nova versao','nova versão','atualizacao','atualização','update','disponivel','disponível','release','anunciou','anuncio','anúncio','chega ao brasil','chega ao mercado','estreia'
          ];
        case NewsFilter.ciberseguranca:
          return [
            'ciberseguranca','cibersegurança','cyber','cybersecurity','seguranca da informacao','segurança da informação','vulnerabilidade','cve','ataque','ransom','ransomware','hacker','malware','phishing','breach','vazamento','dados','exploit','zero-day','patch de seguranca','patch de segurança'
          ];
        case NewsFilter.todos:
          return const <String>[];
      }
    }();

    return items.where((n) {
      final title = n.title;
      final hasTopic = any(title, kws);
      final isTechy = any(title, coreTech);
      final isNoise = any(title, blacklist);

      // IA/Lançamentos/Ciber: precisa bater no tópico + ter sinal de tecnologia + não estar na blacklist
      return hasTopic && isTechy && !isNoise;
    }).toList();
  }

  Future<List<NewsItem>> _fetchAll() async {
    final merged = <NewsItem>[];
    final seen = <String>{};
    final parts = [
      NewsFilter.ia.query,
      NewsFilter.lancamentos.query,
      NewsFilter.ciberseguranca.query,
    ];
    for (final q in parts) {
      final list = await _fetchNews(q);
      for (final n in list) {
        final key = (n.url?.toLowerCase() ?? n.title.toLowerCase());
        if (seen.add(key)) merged.add(n);
      }
      // pequena pausa extra entre chamadas para evitar 429
      await Future.delayed(const Duration(milliseconds: 300));
    }

    merged.sort((a, b) {
      final at = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bt = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final cmp = bt.compareTo(at);
      if (cmp != 0) return cmp;
      return b.points.compareTo(a.points);
    });

    if (merged.isEmpty) {
      final uriTop = Uri.parse('https://newsapi.org/v2/top-headlines').replace(queryParameters: {
        'country': 'br',
        'pageSize': '30',
        'apiKey': _NEWSAPI_KEY,
      });
      final extra = await _loadArticles(uriTop);
      return extra.take(20).toList();
    }
    return merged.take(20).toList();
  }


  Future<List<NewsItem>> _fetchNews(String q) async {
    final f = _selected;
    final qTrim = q.trim();
    final uriEverything = Uri.parse('https://newsapi.org/v2/everything').replace(
      queryParameters: {
        if (qTrim.isNotEmpty) 'q': qTrim,
        'searchIn': 'title,description',
        'language': 'pt',
        'pageSize': '40',
        'sortBy': 'publishedAt',
        'apiKey': _NEWSAPI_KEY,
      },
    );
    final artAll = await _loadArticles(uriEverything);
    var result = _filterLocal(artAll, f);

    if (result.length < 6) {
      final needsTech = f == NewsFilter.ia || f == NewsFilter.ciberseguranca || f == NewsFilter.lancamentos;
      final paramsTop = <String, String>{
        'country': 'br',
        'pageSize': '40',
        'apiKey': _NEWSAPI_KEY,
      };
      if (needsTech) paramsTop['category'] = 'technology';
      if (qTrim.isNotEmpty) paramsTop['q'] = qTrim;
      final uriTop = Uri.parse('https://newsapi.org/v2/top-headlines').replace(queryParameters: paramsTop);
      final artTop = await _loadArticles(uriTop);
      final merged = [...result, ..._filterLocal(artTop, f)];
      final seen = <String>{};
      result = merged.where((n) => seen.add((n.url ?? n.title).toLowerCase())).toList();
    }

    result.sort((a, b) {
      final at = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bt = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bt.compareTo(at);
    });

    return result.take(20).toList();
  }

  Future<List<NewsItem>> _loadArticles(Uri uri) async {
    final jsonMap = await _NewsHttp.getJson(uri);
    final List articles = (jsonMap['articles'] as List? ?? const []);
    return articles.map<NewsItem>((a) {
      final src = (a['source']?['name'] ?? 'Fonte').toString();
      final published = a['publishedAt'] is String ? DateTime.tryParse(a['publishedAt']) : null;
      return NewsItem(
        title: (a['title'] ?? '').toString(),
        url: (a['url'] as String?),
        source: src,
        createdAt: published,
        points: 0,
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

  Future<void> _onTapSummarizeAI() async {
    if (_aiLoading) return;
    setState(() => _aiLoading = true);

    // Abre um loading simples
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    String summary;
    try {
      // Converte a lista visível para o formato esperado pelo serviço
      final itemsForAI = _lastItems.map((n) => newsai.NewsItem(
        title: n.title,
        description: null,
        source: n.source,
        publishedAt: n.createdAt,
        url: n.url,
      )).toList();

      summary = await newsai.NewsAIService.summarize(
        items: itemsForAI,
        filterLabel: _currentFilterLabel,
      );
    } catch (e) {
      summary = 'Não consegui gerar o resumo agora. Tente novamente.\n\nDetalhe: $e';
    } finally {
      if (mounted) Navigator.of(context).pop(); // fecha o loading
      if (mounted) setState(() => _aiLoading = false);
    }

    if (!mounted) return;

    // Exibe resultado
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2A2F3D),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Resumo da Lua',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Copiar',
                  icon: const Icon(Icons.copy, color: Colors.white70),
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: summary));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Resumo copiado.'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Flexible(
              child: SingleChildScrollView(
                child: Text(
                  summary,
                  style: const TextStyle(color: Colors.white70, height: 1.35),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _future = _getWithCache(NewsFilter.todos);
  }

  @override
  Widget build(BuildContext context) {
    const box      = Color(0xB2515767); // fundo semi-transparente, seguindo o mock
    const border   = Color(0xFF7884C4); // borda 1px externa
    const text     = Color(0xFFFAF9F6);
    const purple   = Color(0xFFA259FF);

    return Container(
      height: 300,
      width: double.infinity,
      decoration: BoxDecoration(
        color: box,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border, width: 1),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Expanded(
                child: Text(
                  'Notícias Tech',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white70, size: 18),
                tooltip: 'Atualizar agora',
                onPressed: () async {
                  setState(() => _future = Future.value(const []));
                  try {
                    final fresh = ( _selected == NewsFilter.todos )
                        ? await _fetchAll()
                        : await _fetchNews(_selected.query);
                    await _NewsFirestoreCache.write(_selected, fresh);
                    if (mounted) setState(() => _future = Future.value(fresh));
                  } catch (e) {
                    if (mounted) setState(() => _future = Future.error(e));
                  }
                },
              ),
              GestureDetector(
                onTap: widget.onSummarizeTap ?? _onTapSummarizeAI,
                child: Container(
                  width: 25,
                  height: 25,
                  decoration: const BoxDecoration(
                    color: Color(0xFF6C7691),
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(4),
                  child: SvgPicture.asset(
                    'assets/icons/newsAI.svg',
                    fit: BoxFit.contain,
                    colorFilter: const ColorFilter.mode(Color(0xFFA259FF), BlendMode.srcIn),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _FiltersBar(
            selected: _selected,
            onChanged: (f) {
              setState(() {
                _selected = f;
                _future = _getWithCache(f);
              });
            },
          ),
          const SizedBox(height: 8),
          Expanded(
            child: FutureBuilder<List<NewsItem>>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'Não foi possível carregar as notícias agora. ${snap.error}'.replaceAll('Exception: ', ''),
                        style: const TextStyle(color: text),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                final items = snap.data ?? const [];
                _lastItems = items;
                if (items.isEmpty) {
                  return const Center(
                    child: Text('Sem resultados agora.', style: TextStyle(color: text)),
                  );
                }

                return ListView.separated(
                  itemCount: items.length.clamp(0, 10),
                  separatorBuilder: (_, __) => const Divider(height: 12, thickness: 0.5, color: Colors.black26),
                  itemBuilder: (context, i) {
                    final n = items[i];
                    return Container(
                      decoration: BoxDecoration(
                        color: const Color(0x7F6C7691),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF6C7691), width: 1),
                      ),
                      child: ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        leading: CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.black12,
                          child: Icon(_selected.icon, size: 18, color: purple),
                        ),
                        title: Text(
                          n.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: text, fontWeight: FontWeight.w600, fontSize: 12),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Wrap(
                            spacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              _Tag(label: _selected.label),
                              Text(
                                '${n.source}${n.createdAt != null ? ' • ${n.createdAt!.toLocal().toString().substring(0,16)}' : ''}',
                                style: TextStyle(color: text.withOpacity(0.7), fontSize: 10),
                              ),
                            ],
                          ),
                        ),
                        trailing: const Icon(Icons.open_in_new, color: purple, size: 18),
                        onTap: () => _openUrl(n.url),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FiltersBar extends StatelessWidget {
  final NewsFilter selected;
  final ValueChanged<NewsFilter> onChanged;
  const _FiltersBar({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            const SizedBox(width: 2),
            ...NewsFilter.values.map((f) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(f.label, style: const TextStyle(fontSize: 12)),
                    selected: selected == f,
                    onSelected: (_) => onChanged(f),
                    selectedColor: const Color(0xFF6638B6),
                    backgroundColor: const Color(0xFF484F61),
                    labelStyle: TextStyle(
                      color: selected == f ? const Color(0xFFC1A1EC) : Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                    side: BorderSide(color: selected == f ? const Color(0xFF6C52BB) : const Color(0xFF6C7691)),
                    shape: const StadiumBorder(),
                    visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
                  ),
                )),
            const SizedBox(width: 2),
          ],
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  const _Tag({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF6C7691).withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF6C7691)),
      ),
      child: Text(label, style: const TextStyle(color: Color(0xFFAE85E5), fontSize: 10, fontWeight: FontWeight.w600)),
    );
  }
}