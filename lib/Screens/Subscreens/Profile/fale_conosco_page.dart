import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Para pegar o e-mail do usuário
import 'package:url_launcher/url_launcher.dart'; // Pacote que adicionamos

class FaleConoscoPage extends StatefulWidget {
  FaleConoscoPage({Key? key}) : super(key: key);

  @override
  State<FaleConoscoPage> createState() => _FaleConoscoPageState();
}

class _FaleConoscoPageState extends State<FaleConoscoPage> {
  final _assuntoController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  Future<void> _enviarChamadoPorEmail() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final String assunto = _assuntoController.text;
    final String descricao = _descricaoController.text;
    final String? userEmail = FirebaseAuth.instance.currentUser?.email;
    final String? userName = FirebaseAuth.instance.currentUser?.displayName;

    final String emailDeSuporte = 'suporte.nexus.sac@gmail.com';

    final String body = 
        "$descricao\n\n" + // A descrição do usuário
        "\n" +
        "Atenciosamente,\n" +
        "Nome: $userName\n" +
        "E-mail: $userEmail\n";
    
    final String subjectEncoded = Uri.encodeComponent('[APP NEXUS] $assunto');

    final String bodyEncoded = Uri.encodeComponent(body).replaceAll('+', '%20');

    final Uri emailLaunchUri = Uri.parse(
      'mailto:$emailDeSuporte?subject=$subjectEncoded&body=$bodyEncoded'
    );

    try {
      if (await canLaunchUrl(emailLaunchUri)) {
        await launchUrl(emailLaunchUri);
        Navigator.of(context).pop();
      } else {
        throw Exception('Não foi possível abrir o app de e-mail.');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B202E),
      appBar: AppBar(
        title: const Text('Fale Conosco'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _assuntoController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Assunto',
                  labelStyle: TextStyle(color: Colors.white70),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white54),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
                validator: (value) =>
                    (value == null || value.isEmpty) ? 'Por favor, insira um assunto.' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descricaoController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Descrição do Problema',
                  labelStyle: TextStyle(color: Colors.white70),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white54),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
                maxLines: 6,
                validator: (value) =>
                    (value == null || value.isEmpty) ? 'Por favor, descreva o problema.' : null,
              ),
              const SizedBox(height: 24),
              
              ElevatedButton(
                onPressed: _enviarChamadoPorEmail,
                child: const Text('Abrir App de E-mail'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}