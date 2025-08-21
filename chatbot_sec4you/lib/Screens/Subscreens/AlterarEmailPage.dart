import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

const kAccent = Color(0xFFA259FF); // Cor de destaque
const kBg = Color(0xFF121212); // Fundo escuro
const kText = Color(0xFFFAF9F6); // Texto branco
const kTextFieldBg = Color(0xFF333333); // Fundo dos campos de texto
const kTextFieldBorder = Color(0xFF555555); // Cor da borda dos campos de texto

class AlterarEmailPage extends StatefulWidget {
  const AlterarEmailPage({super.key});

  @override
  _AlterarEmailPageState createState() => _AlterarEmailPageState();
}

class _AlterarEmailPageState extends State<AlterarEmailPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  // Função para salvar as alterações no Firestore
  Future<void> _saveEmailChanges() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await user.updateEmail(_emailController.text);
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'email': _emailController.text,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('E-mail atualizado com sucesso!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao atualizar e-mail: $e'),
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
          'Alterar E-mail',
          style: TextStyle(color: kText),
        ),
        backgroundColor: kAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Campo para o novo e-mail
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Novo E-mail',
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
                    return 'Por favor, insira seu e-mail.';
                  }
                  if (!RegExp(r"^[^@]+@[^@]+\.[^@]+$").hasMatch(value)) {
                    return 'Por favor, insira um e-mail válido.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Botão para salvar as alterações
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState?.validate() ?? false) {
                    _saveEmailChanges();
                  }
                },
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
      ),
    );
  }
}
