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
      appBar: AppBar(
        title: const Text(
          '<Fórum./>',
          style: TextStyle(
            color: Color(0xFFFAF9F6),
            fontWeight: FontWeight.bold,
          ),
        ),
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
    );
  }
}

