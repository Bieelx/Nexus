import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LocalData {
  static final LocalData _instance = LocalData._internal();
  factory LocalData() => _instance;
  LocalData._internal();

  List<Map<String, dynamic>> _boards = [];
  Map<String, List<Map<String, dynamic>>> _posts = {};
  Set<String> _favoriteBoards = {};
  Map<String, List<String>> _reports = {}; // boardName -> lista de postIds denunciados

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final boardsStr = prefs.getString('boards');
    if (boardsStr != null) {
      _boards = List<Map<String, dynamic>>.from(jsonDecode(boardsStr));
    } else {
      _boards = [
        {'name': 'geral'},
        {'name': 'tecnologia'},
        {'name': 'games'},
      ];
      await saveBoards();
    }

    final postsStr = prefs.getString('posts');
    if (postsStr != null) {
      final decoded = jsonDecode(postsStr) as Map<String, dynamic>;
      _posts = decoded.map((key, value) =>
        MapEntry(key, List<Map<String, dynamic>>.from(value)));
    }

    final favStr = prefs.getString('favoriteBoards');
    if (favStr != null) {
      _favoriteBoards = Set<String>.from(jsonDecode(favStr));
    }

    final reportsStr = prefs.getString('reports');
    if (reportsStr != null) {
      final decoded = jsonDecode(reportsStr) as Map<String, dynamic>;
      _reports = decoded.map((key, value) =>
        MapEntry(key, List<String>.from(value)));
    }
  }

  Future<void> saveBoards() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('boards', jsonEncode(_boards));
  }

  Future<void> savePosts() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('posts', jsonEncode(_posts));
  }

  Future<void> saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('favoriteBoards', jsonEncode(_favoriteBoards.toList()));
  }

  Future<void> saveReports() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('reports', jsonEncode(_reports));
  }

  List<Map<String, dynamic>> getBoards() => _boards;

  // Favoritar/desfavoritar board
  bool isFavorite(String boardName) => _favoriteBoards.contains(boardName);

  Future<void> toggleFavorite(String boardName) async {
    if (_favoriteBoards.contains(boardName)) {
      _favoriteBoards.remove(boardName);
    } else {
      _favoriteBoards.add(boardName);
    }
    await saveFavorites();
  }

  // Paginação: retorna posts da board, do índice [start] até [start+limit]
  List<Map<String, dynamic>> getPosts(String boardName, {int start = 0, int limit = 20}) {
    final all = _posts[boardName] ?? [];
    final end = (start + limit) > all.length ? all.length : (start + limit);
    return all.sublist(start, end);
  }

  // Adiciona post ou resposta (thread) com suporte a replyTo
  Future<void> addPost(
    String boardName,
    String text,
    String? imagePath, {
    String? parentId, // Se for resposta, parentId é o id do post pai
    Map<String, dynamic>? replyTo, // NOVO: resumo da mensagem respondida
  }) async {
    _posts[boardName] = _posts[boardName] ?? [];
    final postId = DateTime.now().millisecondsSinceEpoch.toString();
    final newPost = {
      'id': postId,
      'text': text,
      'image': imagePath ?? '',
      'date': DateTime.now().toString().substring(0, 16),
      'replies': <Map<String, dynamic>>[],
      'parentId': parentId,
      'replyTo': replyTo, // NOVO: salva o resumo da mensagem respondida
    };

    if (parentId != null) {
      // Adiciona como resposta (thread)
      final parentIndex = _posts[boardName]!.indexWhere((p) => p['id'] == parentId);
      if (parentIndex != -1) {
        _posts[boardName]![parentIndex]['replies'] ??= <Map<String, dynamic>>[];
        (_posts[boardName]![parentIndex]['replies'] as List).add(newPost);
      }
    } else {
      // Adiciona como post principal
      _posts[boardName]!.add(newPost);
    }
    await savePosts();
  }

  // Retorna replies de um post
  List<Map<String, dynamic>> getReplies(String boardName, String postId) {
    final posts = _posts[boardName] ?? [];
    final post = posts.firstWhere((p) => p['id'] == postId, orElse: () => {});
    return List<Map<String, dynamic>>.from(post['replies'] ?? []);
  }

  // Denunciar post
  Future<void> reportPost(String boardName, String postId) async {
    _reports[boardName] = _reports[boardName] ?? [];
    if (!_reports[boardName]!.contains(postId)) {
      _reports[boardName]!.add(postId);
      await saveReports();
    }
  }

  // Verifica se post foi denunciado
  bool isReported(String boardName, String postId) {
    return _reports[boardName]?.contains(postId) ?? false;
  }

  // Adiciona uma nova board
  Future<bool> addBoard(String name) async {
    if (_boards.any((b) => b['name'] == name)) return false;
    _boards.add({'name': name});
    await saveBoards();
    return true;
  }
}