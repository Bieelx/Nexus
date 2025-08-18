import 'package:chatbot_sec4you/auth_exception.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../service/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final senhaController = TextEditingController();
  final nomeController = TextEditingController();
  final sobrenomeController = TextEditingController();

  bool isLogin = true;
  String error = '';

  final Color background = const Color(0xFF121212);
  final Color cardColor = const Color(0xFF1E1E2C);
  final Color purple = const Color(0xFF9C27B0);
  final Color textColor = Colors.white70;

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);

    return Scaffold(
      backgroundColor: background,
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 320,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_person, color: purple, size: 60),
                const SizedBox(height: 16),
                Text(
                  isLogin ? "Bem-vindo de volta!" : "Crie sua conta",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: purple,
                  ),
                ),
                const SizedBox(height: 24),
                if (!isLogin) ...[
                  _buildTextField("Nome", nomeController),
                  const SizedBox(height: 10),
                  _buildTextField("Sobrenome", sobrenomeController),
                  const SizedBox(height: 10),
                ],
                _buildTextField("Email", emailController),
                const SizedBox(height: 10),
                _buildTextField("Senha", senhaController, obscure: true),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: purple,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    onPressed: () async {
                      String email = emailController.text.trim();
                      String senha = senhaController.text;

                      try {
                        if (isLogin) {
                          await auth.login(email, senha);
                        } else {
                          String nome = nomeController.text;
                          String sobrenome = sobrenomeController.text;
                          await auth.registrar(email, senha, nome, sobrenome);
                        }
                      } on AuthException catch (e) {
                        setState(() {
                          error = e.message;
                        });
                      } catch (_) {
                        setState(() {
                          error = 'Erro inesperado. Tente novamente.';
                        });
                      }
                    },
                    icon: Icon(
                      isLogin ? Icons.login : Icons.person_add,
                      color: Colors.white,
                    ),
                    label: Text(
                      isLogin ? "Login" : "Cadastrar",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () {
                    setState(() {
                      isLogin = !isLogin;
                      error = '';
                    });
                  },
                  child: Text(
                    isLogin
                        ? 'Novo por aqui? Cadastre-se'
                        : 'Já tem conta? Faça login',
                    style: TextStyle(
                      color: purple,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (error.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      error,
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {bool obscure = false}) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: TextStyle(color: textColor),
      decoration: InputDecoration(
        hintText: label,
        hintStyle: TextStyle(color: textColor.withOpacity(0.6)),
        filled: true,
        fillColor: const Color(0xFF2B2B3B),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
    );
  }
}