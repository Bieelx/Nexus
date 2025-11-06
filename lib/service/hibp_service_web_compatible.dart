import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'hibp_service.dart'; // Importa os modelos BreachData e PasteData

/// Service para integração com Have I Been Pwned API
/// Com suporte para Web (via proxy) e Mobile/Desktop (direto)
class HIBPServiceWebCompatible {
  // API key carregada do arquivo .env
  static String get _apiKey => dotenv.env['HIBP_API_KEY'] ?? '';
  static const String _baseUrl = 'https://haveibeenpwned.com/api/v3';

  // Proxy CORS para web (usa AllOrigins como fallback)
  static const String _corsProxyUrl = 'https://api.allorigins.win/raw?url=';

  // Headers padrão para requisições
  static Map<String, String> get _headers => {
        'hibp-api-key': _apiKey,
        'user-agent': 'Nexus-App',
      };

  /// Monta a URL com ou sem proxy dependendo da plataforma
  static String _buildUrl(String endpoint) {
    final url = '$_baseUrl$endpoint';

    if (kIsWeb) {
      // Na web, usa proxy CORS
      // Encode a URL para passar pelo proxy
      return '$_corsProxyUrl${Uri.encodeComponent(url)}';
    } else {
      // Mobile/Desktop: acesso direto
      return url;
    }
  }

  /// Faz requisição GET com tratamento especial para web
  static Future<http.Response> _makeRequest(String endpoint) async {
    if (kIsWeb) {
      // Na web, não podemos adicionar headers customizados devido ao CORS
      // Vamos tentar usar um proxy diferente que aceita headers

      // Opção 1: Usar CORS Anywhere (pode estar bloqueado)
      final corsAnywhereUrl = 'https://cors-anywhere.herokuapp.com/$_baseUrl$endpoint';

      try {
        // Tenta com CORS Anywhere
        final response = await http.get(
          Uri.parse(corsAnywhereUrl),
          headers: _headers,
        );
        return response;
      } catch (e) {
        // Se falhar, tenta com AllOrigins (sem headers customizados)
        final allOriginsUrl = '$_corsProxyUrl${Uri.encodeComponent('$_baseUrl$endpoint')}';
        final response = await http.get(Uri.parse(allOriginsUrl));
        return response;
      }
    } else {
      // Mobile/Desktop: acesso direto com headers
      final response = await http.get(
        Uri.parse('$_baseUrl$endpoint'),
        headers: _headers,
      );
      return response;
    }
  }

  /// Verifica se um email foi comprometido em vazamentos
  /// Retorna lista de breaches encontrados
  static Future<List<BreachData>> checkEmailBreaches(String email) async {
    try {
      final endpoint = '/breachedaccount/$email';
      final response = await _makeRequest(endpoint);

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((json) => BreachData.fromJson(json)).toList();
      } else if (response.statusCode == 404) {
        // 404 significa que não foi encontrado nenhum vazamento
        return [];
      } else if (response.statusCode == 401) {
        throw Exception('API key inválida');
      } else if (response.statusCode == 429) {
        throw Exception('Limite de requisições excedido. Aguarde um momento.');
      } else {
        throw Exception('Erro ao consultar API: ${response.statusCode}');
      }
    } catch (e) {
      if (kIsWeb && e.toString().contains('CORS')) {
        throw Exception('Erro de CORS. Por favor, teste em um dispositivo móvel ou desktop.');
      }
      throw Exception('Erro de conexão: $e');
    }
  }

  /// Verifica pastes (colagens públicas) onde o email aparece
  /// Requer API key paga
  static Future<List<PasteData>> checkEmailPastes(String email) async {
    try {
      final endpoint = '/pasteaccount/$email';
      final response = await _makeRequest(endpoint);

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((json) => PasteData.fromJson(json)).toList();
      } else if (response.statusCode == 404) {
        return [];
      } else if (response.statusCode == 401) {
        throw Exception('API key inválida ou sem permissão para pastes');
      } else if (response.statusCode == 429) {
        throw Exception('Limite de requisições excedido');
      } else {
        throw Exception('Erro ao consultar pastes: ${response.statusCode}');
      }
    } catch (e) {
      if (kIsWeb && e.toString().contains('CORS')) {
        // Silenciosamente falha em pastes na web (não crítico)
        return [];
      }
      throw Exception('Erro de conexão: $e');
    }
  }

  /// Busca breaches por filtro de domínio (opcional)
  static Future<List<BreachData>> getAllBreaches({String? domain}) async {
    try {
      String endpoint = '/breaches';
      if (domain != null && domain.isNotEmpty) {
        endpoint += '?domain=$domain';
      }

      final response = await _makeRequest(endpoint);

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((json) => BreachData.fromJson(json)).toList();
      } else {
        throw Exception('Erro ao buscar breaches: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro de conexão: $e');
    }
  }

  /// Retorna um resumo formatado dos vazamentos
  static String getBreachSummary(List<BreachData> breaches) {
    if (breaches.isEmpty) return 'Nenhum vazamento encontrado! ✅';

    final count = breaches.length;
    final sites = breaches.map((b) => b.title).take(3).join(', ');
    final more = count > 3 ? ' e mais ${count - 3}' : '';

    return 'Encontrado em $count vazamento${count > 1 ? 's' : ''}: $sites$more';
  }

  /// Retorna estatísticas dos vazamentos
  static Map<String, dynamic> getBreachStatistics(List<BreachData> breaches) {
    if (breaches.isEmpty) {
      return {
        'total': 0,
        'verified': 0,
        'sensitive': 0,
        'dataTypes': <String>[],
        'mostRecent': null,
      };
    }

    final verified = breaches.where((b) => b.isVerified).length;
    final sensitive = breaches.where((b) => b.isSensitive).length;
    final allDataClasses = breaches
        .expand((b) => b.dataClasses)
        .toSet()
        .toList()
      ..sort();

    breaches.sort((a, b) => b.breachDate.compareTo(a.breachDate));
    final mostRecent = breaches.first;

    return {
      'total': breaches.length,
      'verified': verified,
      'sensitive': sensitive,
      'dataTypes': allDataClasses,
      'mostRecent': mostRecent,
    };
  }
}
