import 'dart:math';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

/// Estrutura mínima que o serviço entende.
/// Se já tiver seu próprio modelo, só passe os campos abaixo para o método [summarize].
class NewsItem {
  final String title;
  final String? description;
  final String? source;
  final DateTime? publishedAt;
  final String? url;

  NewsItem({
    required this.title,
    this.description,
    this.source,
    this.publishedAt,
    this.url,
  });
}

class NewsAIService {
  static const String _fallbackApiKey = 'AIzaSyBLryOa1F6EqFGvHD8XYokectsx58GX7mc';

  /// Gera um resumo em PT‑BR das notícias visíveis.
  /// - [items] passe os itens já filtrados na tela (ex.: _filteredArticles).
  /// - [filterLabel] algo como "Todos", "IA", "Lançamentos", "CyberSegurança".
  static Future<String> summarize({
    required List<NewsItem> items,
    required String filterLabel,
  }) async {
    final String key = (dotenv.env['GEMINI_API_KEY'] ?? _fallbackApiKey).trim();

    if (items.isEmpty) {
      return 'Não há notícias suficientes para resumir no momento.';
    }

    // Limita a quantidade para evitar prompt gigante.
    final chunk = items.take(min(12, items.length)).toList();

    // Monta um bloco com as notícias (título + desc + fonte).
    final newsBlock = StringBuffer();
    for (var i = 0; i < chunk.length; i++) {
      final n = chunk[i];
      newsBlock.writeln('''
${i + 1}. Título: ${n.title}
   Resumo: ${n.description ?? '-'}
   Fonte: ${n.source ?? '-'} ${n.publishedAt != null ? '(${n.publishedAt})' : ''}
   Link: ${n.url ?? '-'}
''');
    }

    final prompt = '''
Você é a assistente **Lua** da Nexus. Resuma em **português brasileiro** as notícias abaixo considerando o filtro ativo: "$filterLabel".

Formate **exatamente** assim (Markdown):
# Resumo — Filtro: "$filterLabel"

## Lançamentos
- **Título** — 1 frase objetiva. _[Fonte • Data]_

## IA
- **Título** — 1 frase objetiva. _[Fonte • Data]_

## Cybersegurança
- **Título** — 1 frase objetiva. _[Fonte • Data]_

## Outros
- **Título** — 1 frase objetiva. _[Fonte • Data]_

### Sugestões de leitura
1. **Título curto** — URL
2. **Título curto** — URL

Regras obrigatórias:
- Máximo de **6 itens no total** somados entre as seções.
- Só mostre **seções com itens** (NÃO exiba seções vazias).
- Use frases curtas (≤ 20 palavras), diretas e sem opinião.
- Se houver riscos/alertas, prefixe a linha com **⚠️**.
- A fonte deve ser apenas o nome (sem URL) e a data em formato `dd/mm`.
- Em “Sugestões de leitura”, inclua 1–2 links dos itens **mais relevantes** com título curto.
- Não invente dados ou links; se faltar URL, omita o item em Sugestões.

Notícias:
${newsBlock.toString()}
''';

    String localFallback({Object? error}) {
      // Agrupa superficialmente por palavras‑chave
      final lanc = <String>[];
      final ia = <String>[];
      final cyber = <String>[];
      final outros = <String>[];

      for (final n in chunk) {
        final t = n.title.toLowerCase();
        String firstSentence;
        final descSentences = n.description?.split('.').toList();
        if (descSentences != null) {
          descSentences.removeWhere((s) => s.trim().isEmpty);
        }
        firstSentence = (descSentences != null && descSentences.isNotEmpty)
            ? '${descSentences.first.trim()}.'
            : 'Sem resumo.';
        if (t.contains('lançament') || t.contains('launch')) {
          lanc.add('• **${n.title}** — $firstSentence');
        } else if (t.contains('ia') || t.contains('ai') || t.contains('gemini') || t.contains('siri')) {
          ia.add('• **${n.title}** — $firstSentence');
        } else if (t.contains('seguran') || t.contains('vazament') || t.contains('security')) {
          cyber.add('• **${n.title}** — $firstSentence');
        } else {
          outros.add('• **${n.title}** — $firstSentence');
        }
      }

      String section(String title, List<String> items) =>
          items.isEmpty ? '' : '\n## $title\n${items.take(6).join("\n")}';

      final header = '# Resumo — Filtro: "$filterLabel"';
      final body = [
        section('Lançamentos', lanc),
        section('IA', ia),
        section('Cybersegurança', cyber),
        section('Outros', outros),
      ].where((s) => s.isNotEmpty).join('\n');

      final prefix = error != null
          ? '(Resumo local – erro ao chamar Gemini: $error)\n'
          : '(Resumo local – configure GEMINI_API_KEY p/ melhorar)\n';

      return '$prefix$header\n$body';
    }

    // Se não tiver chave, devolve um fallback local (não trava a UI).
    if (key.isEmpty) {
      return localFallback();
    }

    // Gemini oficial (google_generative_ai)
    try {
      final model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: key,
      );

      final response = await model.generateContent([Content.text(prompt)]);
      final text = response.text?.trim();
      if (text == null || text.isEmpty) {
        return localFallback(error: 'resposta vazia');
      }
      return text;
    } catch (e) {
      // Fallback em caso de erro na chamada do Gemini
      return localFallback(error: e);
    }
  }
}

extension _FirstSentence on String {
  String? get firstOrNull {
    final s = trim();
    if (s.isEmpty) return null;
    final i = s.indexOf('.');
    return i == -1 ? s : s.substring(0, i + 1);
  }
}