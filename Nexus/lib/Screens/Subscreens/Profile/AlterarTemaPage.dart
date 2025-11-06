import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

const kAccent = Color(0xFFA259FF); // Cor de destaque
const kBg = Color(0xFF121212); // Fundo escuro
const kText = Color(0xFFFAF9F6); // Texto branco
const kTextFieldBg = Color(0xFF333333); // Fundo dos campos de texto
const kTextFieldBorder = Color(0xFF555555); // Cor da borda dos campos de texto

class AlterarTemaPage extends StatefulWidget {
  const AlterarTemaPage({super.key});

  @override
  _AlterarTemaPageState createState() => _AlterarTemaPageState();
}

class _AlterarTemaPageState extends State<AlterarTemaPage> {
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _loadThemeSettings();
  }

  // Função para carregar as configurações de tema do usuário
  Future<void> _loadThemeSettings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    if (userDoc.exists) {
      setState(() {
        _isDarkMode = userDoc['isDarkMode'] ?? false;
      });
    }
  }

  // Função para salvar as configurações de tema
  Future<void> _saveThemeSettings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'isDarkMode': _isDarkMode,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Configurações de tema atualizadas!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao atualizar configurações de tema: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Tema',
          style: TextStyle(color: kText),
        ),
        backgroundColor: kAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // Título
            const Text(
              'Configurações de Tema',
              style: TextStyle(
                color: kText,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // Modo escuro ou claro
            SwitchListTile(
              title: const Text(
                'Modo Escuro',
                style: TextStyle(color: kText),
              ),
              value: _isDarkMode,
              onChanged: (bool value) {
                setState(() {
                  _isDarkMode = value;
                });
              },
              activeColor: kAccent,
              activeTrackColor: kAccent.withOpacity(0.6),
              inactiveThumbColor: Colors.grey,
              inactiveTrackColor: Colors.grey.withOpacity(0.4),
            ),

            const SizedBox(height: 24),

            // Botão para salvar as alterações
            ElevatedButton(
              onPressed: _saveThemeSettings,
              child: const Text('Salvar Alterações'),
              style: ElevatedButton.styleFrom(
                foregroundColor: kText,
                backgroundColor: kAccent,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
