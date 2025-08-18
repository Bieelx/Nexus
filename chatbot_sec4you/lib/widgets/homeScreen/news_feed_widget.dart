import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

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
  const NewsFeedWidget({super.key, this.query = 'AI'});

  @override
  State<NewsFeedWidget> createState() => _NewsFeedWidgetState();
}

class _NewsFeedWidgetState extends State<NewsFeedWidget> {
  late Future<List<NewsItem>> _future;
  NewsFilter _selected = NewsFilter.todos;

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
    // Merge das três buscas principais (IA, Lançamentos, Cibersegurança)
    final futures = <Future<List<NewsItem>>>[
      _fetchNews(NewsFilter.ia.query),
      _fetchNews(NewsFilter.lancamentos.query),
      _fetchNews(NewsFilter.ciberseguranca.query),
    ];
    final lists = await Future.wait(futures);
    final merged = <NewsItem>[];

    final seen = <String>{};
    for (final list in lists) {
      for (final n in list) {
        final key = (n.url?.toLowerCase() ?? n.title.toLowerCase());
        if (seen.add(key)) merged.add(n);
      }
    }

    merged.sort((a, b) {
      final at = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bt = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final cmp = bt.compareTo(at); // mais recente primeiro
      if (cmp != 0) return cmp;
      return (b.points).compareTo(a.points); // desempate por pontos
    });

    if (merged.isEmpty) {
      // Fallback global: Top headlines BR (sem filtro) para não retornar vazio em "Todos"
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

  Future<Map<String, dynamic>> _getJson(Uri uri) async {
    final resp = await http.get(uri);
    if (resp.statusCode != 200) {
      throw Exception('Falha ao buscar notícias (${resp.statusCode})');
    }
    return jsonDecode(resp.body) as Map<String, dynamic>;
  }

  Future<List<NewsItem>> _fetchNews(String q) async {
    final f = _selected; // usa o filtro atualmente selecionado
    final qTrim = q.trim();

    // Base 1: everything (mundo inteiro em PT) priorizando título/descrição
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

    // Se ficou curto, tentamos top-headlines no BR (categoria tecnologia quando fizer sentido)
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
      // remove duplicados por URL ou título
      final seen = <String>{};
      result = merged.where((n) => seen.add((n.url ?? n.title).toLowerCase())).toList();
    }

    // Ordena por data desc
    result.sort((a, b) {
      final at = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bt = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bt.compareTo(at);
    });

    return result.take(20).toList();
  }

  Future<List<NewsItem>> _loadArticles(Uri uri) async {
    final jsonMap = await _getJson(uri);
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

  @override
  void initState() {
    super.initState();
    _future = _fetchAll();
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
          const Text('Notícias Tech',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          _FiltersBar(
            selected: _selected,
            onChanged: (f) {
              setState(() {
                _selected = f;
                _future = (f == NewsFilter.todos) ? _fetchAll() : _fetchNews(f.query);
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
                    child: Text('Não foi possível carregar as notícias agora. Tente novamente em instantes.', style: const TextStyle(color: text)),
                  );
                }
                final items = snap.data ?? const [];
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