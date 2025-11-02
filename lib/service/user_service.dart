

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Obtém o uid do usuário atualmente autenticado.
  String? get currentUid => _auth.currentUser?.uid;

  /// Retorna um stream em tempo real do photoUrl do usuário logado.
  Stream<String?> get photoUrlStream {
    final uid = currentUid;
    if (uid == null) return const Stream.empty();
    return _firestore.collection('usuarios').doc(uid).snapshots().map(
      (snapshot) => snapshot.data()?['photoUrl'] as String?,
    );
  }

  /// Atualiza o photoUrl do usuário no Firestore.
  Future<void> updatePhotoUrl(String newUrl) async {
    final uid = currentUid;
    if (uid == null) throw Exception('Usuário não autenticado');
    await _firestore.collection('usuarios').doc(uid).update({'photoUrl': newUrl});
  }

  /// Retorna um stream em tempo real de todos os dados do usuário.
  Stream<Map<String, dynamic>?> get userDataStream {
    final uid = currentUid;
    if (uid == null) return const Stream.empty();
    return _firestore.collection('usuarios').doc(uid).snapshots().map(
      (snapshot) => snapshot.data(),
    );
  }

  /// Atualiza campos arbitrários do usuário
  Future<void> updateUserFields(Map<String, dynamic> fields) async {
    final uid = currentUid;
    if (uid == null) throw Exception('Usuário não autenticado');
    await _firestore.collection('usuarios').doc(uid).update(fields);
  }
}