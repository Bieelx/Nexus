import 'package:flutter/material.dart';

void main() {
  runApp(TestApp());
}

class TestApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Teste Navegação',
      home: TestHome(),
    );
  }
}

class TestHome extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Teste')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                print('Navegando...');
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => TestSecond()),
                );
              },
              child: Text('Testar Navegação'),
            ),
          ],
        ),
      ),
    );
  }
}

class TestSecond extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Segunda Tela')),
      body: Center(
        child: Text('Navegação Funcionou!'),
      ),
    );
  }
}
