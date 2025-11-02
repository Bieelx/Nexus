import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

const kAccent = Color(0xFFA259FF); // Cor de destaque
const kBg = Color(0xFF121212); // Fundo escuro
const kText = Color(0xFFFAF9F6); // Texto branco
const kTextFieldBg = Color(0xFF333333); // Fundo dos campos de texto
const kTextFieldBorder = Color(0xFF555555); // Cor da borda dos campos de texto

class AlterarIdiomaPage extends StatefulWidget {
  const AlterarIdiomaPage({super.key});

  @override
  _AlterarIdiomaPageState createState() => _AlterarIdiomaPageState();
}

class _AlterarIdiomaPageState extends State<AlterarIdiomaPage> {
  String _selectedLanguage = 'pt'; // Idioma inicial (português)

  @override
  void initState() {
    super.initState();
    _loadLanguageSettings();
  }

  // Função para carregar as configurações de idioma do usuário
  Future<void> _loadLanguageSettings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    if (userDoc.exists) {
      setState(() {
        _selectedLanguage = userDoc['selectedLanguage'] ?? 'pt';
      });
    }
  }

  // Função para salvar as configurações de idioma
  Future<void> _saveLanguageSettings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'selectedLanguage': _selectedLanguage,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Idioma atualizado com sucesso!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao atualizar idioma: $e'),
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
          'Idioma',
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
              'Configurações de Idioma',
              style: TextStyle(
                color: kText,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // Seleção do idioma
            ListTile(
              title: const Text(
                'Português',
                style: TextStyle(color: kText),
              ),
              leading: Radio<String>(
                value: 'pt',
                groupValue: _selectedLanguage,
                onChanged: (String? value) {
                  setState(() {
                    _selectedLanguage = value!;
                  });
                },
                activeColor: kAccent,
              ),
            ),
            ListTile(
              title: const Text(
                'English',
                style: TextStyle(color: kText),
              ),
              leading: Radio<String>(
                value: 'en',
                groupValue: _selectedLanguage,
                onChanged: (String? value) {
                  setState(() {
                    _selectedLanguage = value!;
                  });
                },
                activeColor: kAccent,
              ),
            ),

            const SizedBox(height: 24),

            // Botão para salvar as alterações
            ElevatedButton(
              onPressed: _saveLanguageSettings,
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
