import 'package:nexus_app/core/auth_exception.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'security_event_service.dart';

class AuthService with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb ? '480594485086-i5jvje51qbdjtn0v3hip2c73taaq1hvn.apps.googleusercontent.com' : null,
  );

  User? usuario;
  bool isLoading = true;

  AuthService() {
    _authCheck();
  }

  void _authCheck() {
    _auth.authStateChanges().listen((User? user) async {
      usuario = user;
      if (user != null) {
        await _ensureUserDocument(user);
      }
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
      final cred = await _auth.createUserWithEmailAndPassword(email: email, password: senha);
      final uid = cred.user!.uid;

      await _firestore.runTransaction((transaction) async {
        final usernameRef = _firestore.collection('usernames').doc(usernameLower);
        final usernameDoc = await transaction.get(usernameRef);

        if (usernameDoc.exists) {
          await cred.user?.delete();
          throw AuthException('Este username já está em uso. Escolha outro.');
        }

        transaction.set(usernameRef, {'uid': uid, 'createdAt': FieldValue.serverTimestamp()});

        final userRef = _firestore.collection('users').doc(uid);
        transaction.set(userRef, {
          'nome': nome,
          'sobrenome': sobrenome,
          'username': usernameLower,
          'email': email,
          'createdAt': FieldValue.serverTimestamp(),
        });
      });

      await cred.user?.updateDisplayName(usernameLower);
      await cred.user?.reload();
      usuario = _auth.currentUser;
      notifyListeners();
      return cred.user;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') throw AuthException('A senha é muito fraca!');
      if (e.code == 'email-already-in-use') throw AuthException('Este email já está cadastrado');
      throw AuthException('Erro ao registrar: ${e.message}');
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Ocorreu um erro inesperado. Tente novamente.');
    }
  }

  Future<void> login(String email, String senha) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(email: email, password: senha);
      await SecurityEventService.logLoginAttempt(email: email, success: true);
      // Garante que o documento do usuário exista no Firestore
      await _ensureUserDocument(cred.user);
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      if (e.code == 'user-not-found') errorMessage = 'Email não encontrado. Cadastre-se.';
      else if (e.code == 'wrong-password') errorMessage = 'Senha incorreta. Tente novamente';
      else errorMessage = 'Erro ao logar: ${e.message}';
      
      await SecurityEventService.logLoginAttempt(email: email, success: false, errorMessage: errorMessage);
      throw AuthException(errorMessage);
    }
  }

  /// Cria o documento do usuário no Firestore se ele não existir
  Future<void> _ensureUserDocument(User? user) async {
    if (user == null) return;
    try {
      final docRef = _firestore.collection('users').doc(user.uid);
      final doc = await docRef.get();
      if (!doc.exists) {
        final email = user.email ?? '';
        final nome = user.displayName ?? email.split('@').first;
        print('📝 Criando documento do usuário no Firestore para: $email');
        await docRef.set({
          'nome': nome,
          'sobrenome': '',
          'username': email.split('@').first.toLowerCase(),
          'email': email,
          'createdAt': FieldValue.serverTimestamp(),
        });
        print('✅ Documento do usuário criado com sucesso.');
      } else {
        final data = doc.data();
        print('✅ Documento do usuário já existe. nome: ${data?['nome']}');
      }
    } catch (e) {
      print('❌ Erro ao garantir documento do usuário: $e');
    }
  }

  // ===============================================
  //     NOVO MÉTODO PARA O LOGIN COM GOOGLE
  // ===============================================
  Future<void> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return; // Usuário cancelou

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        // Se for um usuário novo, salva os dados no Firestore
        if (userCredential.additionalUserInfo?.isNewUser == true) {
          final nome = googleUser.displayName?.split(' ').first ?? '';
          final sobrenome = googleUser.displayName?.split(' ').last ?? '';
          final email = user.email ?? '';
          // Cria um username a partir do email, mas verifica se já existe
          final usernameBase = email.split('@').first.toLowerCase();
          
          await _firestore.runTransaction((transaction) async {
            final usernameRef = _firestore.collection('usernames').doc(usernameBase);
            final usernameDoc = await transaction.get(usernameRef);

            if (usernameDoc.exists) {
              // Username já existe, não podemos criar o usuário.
              // Desfaz o login do Firebase e do Google
              await user.delete();
              await _googleSignIn.signOut();
              throw AuthException('Um usuário com o username "$usernameBase" (derivado do seu email) já existe.');
            }

            // Reserva o username
            transaction.set(usernameRef, {
              'uid': user.uid,
              'createdAt': FieldValue.serverTimestamp(),
            });

            // Salva dados principais do usuário
            final userRef = _firestore.collection('users').doc(user.uid);
            transaction.set(userRef, {
              'nome': nome,
              'sobrenome': sobrenome,
              'username': usernameBase,
              'email': email,
              'photoUrl': user.photoURL,
              'createdAt': FieldValue.serverTimestamp(),
            });
          });
          await user.updateDisplayName(usernameBase);
          await user.reload();
        }
        // Se for um usuário antigo, o _authCheck já cuidará de fazer o login
        usuario = _auth.currentUser;
        notifyListeners();
      }
    } on FirebaseAuthException catch (e) {
      throw AuthException("Erro do Firebase: ${e.message}");
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException("Ocorreu um erro inesperado durante o login com Google.");
    }
  }

  Future<void> logout() async {
    await _googleSignIn.signOut(); // Adiciona o logout do Google
    await _auth.signOut();
  }
}