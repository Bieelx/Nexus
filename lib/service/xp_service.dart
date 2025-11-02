import 'package:cloud_firestore/cloud_firestore.dart';

class XpService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Adiciona XP ao usuário, verifica se sobe de nível e atualiza Firestore.
  Future<void> addXp(String userId, int amount) async {
    final userRef = _firestore.collection('users').doc(userId);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(userRef);
      if (!snapshot.exists) {
        // Se usuário não existe, cria com valores iniciais
        final int initialLevel = 1;
        final int initialXp = amount;
        final String classTag = getClassTag(initialLevel);
        transaction.set(userRef, {
          'xp': initialXp,
          'level': initialLevel,
          'classTag': classTag,
        });
        return;
      }
      int xp = (snapshot.data()?['xp'] ?? 0) as int;
      int level = (snapshot.data()?['level'] ?? 1) as int;
      xp += amount;
      // Loop para múltiplos níveis em caso de muito XP
      while (xp >= xpNeededForLevel(level) && level < 50) {
        xp -= xpNeededForLevel(level);
        level += 1;
      }
      // Atualiza Firestore
      final String classTag = getClassTag(level);
      transaction.update(userRef, {
        'xp': xp,
        'level': level,
        'classTag': classTag,
      });
    });
  }

  /// Retorna o XP necessário para alcançar o próximo nível.
  int xpNeededForLevel(int level) {
    // Nível 1 → 150, 2 → 200, depois dobra até máximo 800
    if (level == 1) return 150;
    if (level == 2) return 200;
    int xp = 200;
    for (int l = 3; l <= level; l++) {
      xp *= 2;
      if (xp > 800) xp = 800;
    }
    return xp;
  }

  /// Retorna a tag de classe com base no nível.
  String getClassTag(int level) {
    if (level >= 1 && level <= 5) return "Estagiário";
    if (level >= 6 && level <= 10) return "Júnior";
    if (level >= 11 && level <= 15) return "Pleno";
    if (level >= 16 && level <= 20) return "Sênior";
    if (level >= 21 && level <= 25) return "Especialista";
    if (level >= 26 && level <= 30) return "Líder";
    if (level >= 31 && level <= 35) return "Gerente";
    if (level >= 36 && level <= 40) return "Diretor";
    if (level >= 41 && level <= 45) return "Executivo";
    if (level >= 46 && level <= 50) return "Mestre";
    return "Desconhecido";
  }

  /// Retorna um Stream dos dados de XP, nível e classe do usuário em tempo real.
  Stream<Map<String, dynamic>> listenToXp(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((snapshot) {
      final data = snapshot.data() ?? {};
      final int level = data['level'] ?? 1;
      final int xp = data['xp'] ?? 0;
      final int xpNeeded = xpNeededForLevel(level);

      return {
        'xp': xp,
        'level': level,
        'classTag': data['classTag'] ?? getClassTag(level),
        'xpNeeded': xpNeeded,
      };
    });
  }
}
