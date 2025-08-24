import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chatbot_sec4you/service/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _senhaCtrl = TextEditingController();
  final _nomeCtrl = TextEditingController();
  final _sobrenomeCtrl = TextEditingController();

  bool _isRegister = false;
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _senhaCtrl.dispose();
    _nomeCtrl.dispose();
    _sobrenomeCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final auth = context.read<AuthService>();
      if (_isRegister) {
        await auth.registrar(
          _emailCtrl.text.trim(),
          _senhaCtrl.text.trim(),
          _nomeCtrl.text.trim(),
          _sobrenomeCtrl.text.trim(),
        );
      } else {
        await auth.login(
          _emailCtrl.text.trim(),
          _senhaCtrl.text.trim(),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _isRegister ? 'Criar conta' : 'Entrar',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFFA259FF),
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Email
                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: _dec('E-mail'),
                    validator: (v) => (v == null || !v.contains('@'))
                        ? 'Informe um e-mail válido'
                        : null,
                  ),
                  const SizedBox(height: 12),

                  // Senha
                  TextFormField(
                    controller: _senhaCtrl,
                    obscureText: true,
                    decoration: _dec('Senha'),
                    validator: (v) => (v == null || v.length < 6)
                        ? 'Mínimo de 6 caracteres'
                        : null,
                  ),

                  if (_isRegister) ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _nomeCtrl,
                      decoration: _dec('Nome'),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Informe o nome'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _sobrenomeCtrl,
                      decoration: _dec('Sobrenome'),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Informe o sobrenome'
                          : null,
                    ),
                  ],

                  const SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFA259FF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(_isRegister ? 'Registrar' : 'Entrar'),
                  ),

                  const SizedBox(height: 12),

                  TextButton(
                    onPressed: _loading
                        ? null
                        : () => setState(() => _isRegister = !_isRegister),
                    child: Text(
                      _isRegister
                          ? 'Já tem conta? Entrar'
                          : 'Criar uma conta',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _dec(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      filled: true,
      fillColor: const Color(0xFF2A2F3C),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF7884C4)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF7884C4)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFA259FF), width: 1.6),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }
}