import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

const kAccent = Color(0xFFA259FF); // Cor de destaque
const kBg = Color(0xFF121212); // Fundo escuro
const kText = Color(0xFFFAF9F6); // Texto branco
const kTextFieldBg = Color(0xFF333333); // Fundo dos campos de texto
const kTextFieldBorder = Color(0xFF555555); // Cor da borda dos campos de texto

class AlterarSenhaPage extends StatefulWidget {
  const AlterarSenhaPage({super.key});

  @override
  _AlterarSenhaPageState createState() => _AlterarSenhaPageState();
}

class _AlterarSenhaPageState extends State<AlterarSenhaPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _currentPasswordController;
  late TextEditingController _newPasswordController;
  late TextEditingController _confirmPasswordController;

  @override
  void initState() {
    super.initState();
    _currentPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Função para alterar a senha do usuário
  Future<void> _changePassword() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Verifica se a nova senha e a confirmação coincidem
    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('As senhas não coincidem!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      // Primeiro, reautentica o usuário
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: _currentPasswordController.text,
      );

      // Tenta reautenticar o usuário
      await user.reauthenticateWithCredential(credential);

      // Atualiza a senha
      await user.updatePassword(_newPasswordController.text);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Senha atualizada com sucesso!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao atualizar senha: $e'),
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
          'Alterar Senha',
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
              // Campo para a senha atual
              TextFormField(
                controller: _currentPasswordController,
                decoration: InputDecoration(
                  labelText: 'Senha Atual',
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
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira sua senha atual.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Campo para a nova senha
              TextFormField(
                controller: _newPasswordController,
                decoration: InputDecoration(
                  labelText: 'Nova Senha',
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
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira sua nova senha.';
                  }
                  if (value.length < 6) {
                    return 'A nova senha deve ter pelo menos 6 caracteres.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Campo para confirmar a nova senha
              TextFormField(
                controller: _confirmPasswordController,
                decoration: InputDecoration(
                  labelText: 'Confirmar Nova Senha',
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
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, confirme sua nova senha.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Botão para salvar as alterações
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState?.validate() ?? false) {
                    _changePassword();
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
