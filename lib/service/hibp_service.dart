import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Modelo de dados para um vazamento (breach)
class BreachData {
  final String name;
  final String title;
  final String domain;
  final DateTime breachDate;
  final int pwnCount;
  final String description;
  final List<String> dataClasses;
  final bool isVerified;
  final bool isSensitive;

  BreachData({
    required this.name,
    required this.title,
    required this.domain,
    required this.breachDate,
    required this.pwnCount,
    required this.description,
    required this.dataClasses,
    required this.isVerified,
    required this.isSensitive,
  });

  factory BreachData.fromJson(Map<String, dynamic> json) {
    return BreachData(
      name: json['Name'] ?? '',
      title: json['Title'] ?? '',
      domain: json['Domain'] ?? '',
      breachDate: DateTime.parse(json['BreachDate'] ?? '2000-01-01'),
      pwnCount: json['PwnCount'] ?? 0,
      description: json['Description'] ?? '',
      dataClasses: List<String>.from(json['DataClasses'] ?? []),
      isVerified: json['IsVerified'] ?? false,
      isSensitive: json['IsSensitive'] ?? false,
    );
  }

  /// Retorna uma descrição formatada dos tipos de dados vazados
  String get dataClassesSummary {
    if (dataClasses.isEmpty) return 'Não especificado';
    if (dataClasses.length <= 3) return dataClasses.join(', ');
    return '${dataClasses.take(3).join(', ')} e mais ${dataClasses.length - 3}';
  }

  /// Retorna o ano do vazamento
  int get year => breachDate.year;
}

/// Modelo para pastes (colagens públicas)
class PasteData {
  final String source;
  final String id;
  final String? title;
  final DateTime? date;
  final int emailCount;

  PasteData({
    required this.source,
    required this.id,
    this.title,
    this.date,
    required this.emailCount,
  });

  factory PasteData.fromJson(Map<String, dynamic> json) {
    return PasteData(
      source: json['Source'] ?? '',
      id: json['Id'] ?? '',
      title: json['Title'],
      date: json['Date'] != null ? DateTime.parse(json['Date']) : null,
      emailCount: json['EmailCount'] ?? 0,
    );
  }
}

/// Service para integração com Have I Been Pwned API
class HIBPService {
  // API key carregada do arquivo .env
  static String get _apiKey => dotenv.env['HIBP_API_KEY'] ?? '';
  static const String _baseUrl = 'https://haveibeenpwned.com/api/v3';

  // Firebase Cloud Functions URL (configure com o ID do seu projeto)
  // Formato: https://us-central1-SEU_PROJETO_ID.cloudfunctions.net
  static const String _cloudFunctionsUrl =
      'https://us-central1-nexus-app.cloudfunctions.net';

  // Headers padrão para requisições
  static Map<String, String> get _headers => {
        'hibp-api-key': _apiKey,
        'user-agent': 'Nexus-App',
      };

  /// Verifica se um email foi comprometido em vazamentos
  /// Retorna lista de breaches encontrados
  static Future<List<BreachData>> checkEmailBreaches(String email) async {
    try {
      if (kIsWeb) {
        // Na web, usa Firebase Cloud Functions para evitar CORS
        return await _checkEmailBreachesViaCloudFunction(email);
      } else {
        // Mobile/Desktop: acesso direto à API HIBP
        return await _checkEmailBreachesDirect(email);
      }
    } catch (e) {
      throw Exception('Erro de conexão: $e');
    }
  }

  /// Chamada direta à API HIBP (mobile/desktop)
  static Future<List<BreachData>> _checkEmailBreachesDirect(
      String email) async {
    final url = Uri.parse('$_baseUrl/breachedaccount/$email');
    final response = await http.get(url, headers: _headers);

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => BreachData.fromJson(json)).toList();
    } else if (response.statusCode == 404) {
      return [];
    } else if (response.statusCode == 401) {
      throw Exception('API key inválida');
    } else if (response.statusCode == 429) {
      throw Exception('Limite de requisições excedido. Aguarde um momento.');
    } else {
      throw Exception('Erro ao consultar API: ${response.statusCode}');
    }
  }

  /// Chamada via Firebase Cloud Functions (web)
  static Future<List<BreachData>> _checkEmailBreachesViaCloudFunction(
      String email) async {
    final url = Uri.parse('$_cloudFunctionsUrl/checkEmailBreaches');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email}),
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      if (jsonList.isEmpty) return [];
      return jsonList.map((json) => BreachData.fromJson(json)).toList();
    } else if (response.statusCode == 429) {
      throw Exception('Limite de requisições excedido. Aguarde um momento.');
    } else {
      final error = json.decode(response.body);
      throw Exception(error['error'] ?? 'Erro ao consultar vazamentos');
    }
  }

  /// Verifica pastes (colagens públicas) onde o email aparece
  /// Requer API key paga
  static Future<List<PasteData>> checkEmailPastes(String email) async {
    try {
      if (kIsWeb) {
        // Na web, usa Firebase Cloud Functions
        return await _checkEmailPastesViaCloudFunction(email);
      } else {
        // Mobile/Desktop: acesso direto
        return await _checkEmailPastesDirect(email);
      }
    } catch (e) {
      throw Exception('Erro de conexão: $e');
    }
  }

  /// Chamada direta à API HIBP para pastes (mobile/desktop)
  static Future<List<PasteData>> _checkEmailPastesDirect(String email) async {
    final url = Uri.parse('$_baseUrl/pasteaccount/$email');
    final response = await http.get(url, headers: _headers);

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
  }

  /// Chamada via Firebase Cloud Functions para pastes (web)
  static Future<List<PasteData>> _checkEmailPastesViaCloudFunction(
      String email) async {
    final url = Uri.parse('$_cloudFunctionsUrl/checkEmailPastes');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email}),
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      if (jsonList.isEmpty) return [];
      return jsonList.map((json) => PasteData.fromJson(json)).toList();
    } else if (response.statusCode == 403) {
      // Sem permissão para pastes (silenciosamente retorna vazio)
      return [];
    } else if (response.statusCode == 429) {
      throw Exception('Limite de requisições excedido');
    } else {
      // Outros erros (não crítico para pastes)
      return [];
    }
  }

  /// Busca breaches por filtro de domínio (opcional)
  /// Útil para mostrar vazamentos de um site específico
  static Future<List<BreachData>> getAllBreaches({String? domain}) async {
    try {
      String url = '$_baseUrl/breaches';
      if (domain != null && domain.isNotEmpty) {
        url += '?domain=$domain';
      }

      final response = await http.get(Uri.parse(url), headers: _headers);

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
