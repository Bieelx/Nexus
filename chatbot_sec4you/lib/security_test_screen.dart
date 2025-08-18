import 'package:flutter/material.dart';

class SecurityTestScreen extends StatelessWidget {
  const SecurityTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0D0D0D),
      appBar: AppBar(
        title: Text(
          'Teste - Alertas de Segurança',
          style: TextStyle(
            color: Color(0xFFFAF9F6),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Color(0xFF1A1A1A),
        iconTheme: IconThemeData(color: Color(0xFFFAF9F6)),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.security,
              color: Color(0xFF7F2AB1),
              size: 64,
            ),
            SizedBox(height: 16),
            Text(
              'Navegação Funcionou! ✅',
              style: TextStyle(
                color: Colors.green,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'A tela de alertas será carregada aqui',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF7F2AB1),
                foregroundColor: Colors.white,
              ),
              child: Text('Voltar'),
            ),
          ],
        ),
      ),
    );
  }
}
