import 'package:chatbot_sec4you/Screens/profile_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

const kBg = Color(0xFF121212); // Fundo escuro
const kCard = Color(0xFF2A2A2A); // Cartões com fundo levemente mais claro
const kText = Colors.white; // Texto branco
const kTextFieldBg = Color(
  0xFF333333,
); // Fundo dos campos de texto, tom mais suave de cinza
const kTextFieldBorder = Color(0xFF555555); // Cor da borda dos campos de texto

class AlterarProfilePage extends StatefulWidget {
  const AlterarProfilePage({super.key});

  @override
  _AlterarProfilePageState createState() => _AlterarProfilePageState();
}

class _AlterarProfilePageState extends State<AlterarProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _roleController;
  late TextEditingController _aboutMeController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _roleController = TextEditingController();
    _aboutMeController = TextEditingController();

    _loadUserProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _roleController.dispose();
    _aboutMeController.dispose();
    super.dispose();
  }

  // Função para carregar os dados do usuário no Firestore
  Future<void> _loadUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDoc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
    if (userDoc.exists) {
      setState(() {
        _nameController.text = userDoc['displayName'] ?? 'Nome Padrão';
        _roleController.text = userDoc['tag'] ?? 'Cargo Padrão';
        _aboutMeController.text = userDoc['aboutMe'] ?? 'Descrição Padrão';
      });
    }
  }

  // Função para salvar as alterações no Firestore
  Future<void> _saveProfileChanges() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'displayName': _nameController.text,
        'tag': _roleController.text,
        'aboutMe': _aboutMeController.text,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Perfil atualizado com sucesso!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao atualizar perfil: $e'),
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
          'Alterar Perfil',
          style: TextStyle(color: kText),
        ), // Cor do texto da AppBar
        backgroundColor: kAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Campo para o nome
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Nome',
                  labelStyle: TextStyle(color: kText), // Cor do label
                  filled: true,
                  fillColor: kTextFieldBg, // Cor do fundo
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: kTextFieldBorder,
                    ), // Cor da borda
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: kText,
                    ), // Cor da borda quando focado
                  ),
                ),
                style: TextStyle(color: kText), // Cor do texto
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira seu nome.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Campo para o cargo
              TextFormField(
                controller: _roleController,
                decoration: InputDecoration(
                  labelText: 'Cargo',
                  labelStyle: TextStyle(color: kText),
                  filled: true,
                  fillColor: kTextFieldBg,
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: kTextFieldBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: kText),
                  ),
                ),
                style: TextStyle(color: kText),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira seu cargo.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Campo para a descrição "Sobre mim"
              TextFormField(
                controller: _aboutMeController,
                decoration: InputDecoration(
                  labelText: 'Sobre mim',
                  labelStyle: TextStyle(color: kText),
                  filled: true,
                  fillColor: kTextFieldBg,
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: kTextFieldBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: kText),
                  ),
                ),
                maxLines: 5,
                style: TextStyle(color: kText),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira uma descrição sobre você.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Botão para salvar as alterações
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState?.validate() ?? false) {
                    _saveProfileChanges();
                  }
                },
                child: const Text('Salvar Alterações'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: kText, backgroundColor: kAccent, // Cor do texto do botão (garante que o texto seja branco)
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
