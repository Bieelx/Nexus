import 'package:nexus_app/core/auth_exception.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'security_event_service.dart';

class AuthService with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? usuario;
  bool isLoading = true;

  AuthService() {
    _authCheck();
  }

  void _authCheck() {
    _auth.authStateChanges().listen((User? user) {
      usuario = user;
      isLoading = false;
      notifyListeners();
    });
  }

Future<User?> registrar(
  String email,
  String senha,
  String nome,
  String username,
  String sobrenome,
) async {
  final usernameLower = username.toLowerCase();

  try {
    // 1. Criar usuário no Firebase Auth primeiro
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: senha,
    );
    final uid = cred.user!.uid;

    // 2. Usar transação para garantir unicidade do username
    await _firestore.runTransaction((transaction) async {
      final usernameRef = _firestore.collection('usernames').doc(usernameLower);
      final usernameDoc = await transaction.get(usernameRef);

      if (usernameDoc.exists) {
        // Se o username já existe, cancelamos e apagamos o usuário recém-criado do Auth
        await cred.user?.delete();
        throw AuthException('Este username já está em uso. Escolha outro.');
      }

      // Reserva o username
      transaction.set(usernameRef, {
        'uid': uid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Salva dados principais do usuário
      final userRef = _firestore.collection('users').doc(uid);
      transaction.set(userRef, {
        'nome': nome,
        'sobrenome': sobrenome,
        'username': usernameLower,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });

    // Atualiza displayName
    await cred.user?.updateDisplayName(usernameLower);
    await cred.user?.reload();
    usuario = _auth.currentUser;
    notifyListeners();

    return cred.user;
  } on FirebaseAuthException catch (e) {
    if (e.code == 'weak-password') {
      throw AuthException('A senha é muito fraca!');
    } else if (e.code == 'email-already-in-use') {
      throw AuthException('Este email já está cadastrado');
    } else {
      throw AuthException('Erro ao registrar: ${e.message}');
    }
  } catch (e) {
    // Tratamento explícito para username duplicado
    if (e is AuthException &&
        e.message == 'Este username já está em uso. Escolha outro.') {
      throw AuthException('Este username já está em uso. Escolha outro.');
    }
    // Tratamento explícito para email duplicado
    if (e is FirebaseAuthException && e.code == 'email-already-in-use') {
      throw AuthException('Este email já está cadastrado.');
    }
    // Tratamento explícito para username duplicado (caso a exceção não seja AuthException)
    if (e is Exception &&
        e.toString().contains('username já está em uso')) {
      throw AuthException('Este username já está em uso. Escolha outro.');
    }
    // Erro inesperado
    throw AuthException('Ocorreu um erro inesperado. Tente novamente.');
  }
}

  Future<void> login(String email, String senha) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: senha);
      
      // ✅ Registra login bem-sucedido
      await SecurityEventService.logLoginAttempt(
        email: email,
        success: true,
      );
      
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      
      if (e.code == 'user-not-found') {
        errorMessage = 'Email não encontrado. Cadastre-se.';
      } else if (e.code == 'wrong-password') {
        errorMessage = 'Senha incorreta. Tente novamente';
      } else {
        errorMessage = 'Erro ao logar: ${e.message}';
      }
      
      // ❌ Registra tentativa de login falhada
      await SecurityEventService.logLoginAttempt(
        email: email,
        success: false,
        errorMessage: errorMessage,
      );
      
      throw AuthException(errorMessage);
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }
}