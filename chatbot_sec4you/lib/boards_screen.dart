import 'package:flutter/material.dart';
import 'board_screen.dart';
import 'local_data.dart';

class BoardsScreen extends StatefulWidget {
  const BoardsScreen({super.key});

  @override
  State<BoardsScreen> createState() => _BoardsScreenState();
}

class _BoardsScreenState extends State<BoardsScreen> {
  List boards = [];

  @override
  void initState() {
    super.initState();
    boards = LocalData().getBoards();
  }

  void addBoard() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nova Board'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Nome'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Criar')),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      final ok = await LocalData().addBoard(result);
      if (ok) {
        setState(() => boards = LocalData().getBoards());
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Board já existe!')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        title: const Text(
          '<Fórum./>',
          style: TextStyle(
            color: Color(0xFFFAF9F6),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF1A1A1A),
        iconTheme: const IconThemeData(color: Color(0xFFFAF9F6)),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: addBoard),
        ],
      ),
      body: ListView(
        children: boards.map((b) => ListTile(
          title: Text(
            b['name'],
            style: const TextStyle(color: Color(0xFFFAF9F6)),
          ),
          leading: const Icon(Icons.forum, color: Color(0xFF7F2AB1)),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BoardScreen(boardName: b['name']),
              ),
            );
          },
        )).toList(),
      ),
      bottomNavigationBar: Container(
        color: const Color(0xFF1A1A1A),
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: const Text(
          'Desenvolvido por Gabriel Gramacho, Mikael Palmeira, Gabriel Araujo, Gustavo Teodoro e Kauã Granata • 2025',
          style: TextStyle(
            color: Color(0xFFFAF9F6),
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

