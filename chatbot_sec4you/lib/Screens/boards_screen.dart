import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'Subscreens/group_screen.dart';
import 'Subscreens/timeline_feed.dart';
import '../widgets/forum/forum_switcher.dart'; 
import '../widgets/forum/group_card.dart';
import '../core/theme/app_colors.dart'; 
import 'package:firebase_auth/firebase_auth.dart';

String _normalize(String s) {
  return s
      .toLowerCase()
      .replaceAll('á', 'a')
      .replaceAll('à', 'a')
      .replaceAll('â', 'a')
      .replaceAll('ã', 'a')
      .replaceAll('é', 'e')
      .replaceAll('ê', 'e')
      .replaceAll('í', 'i')
      .replaceAll('ó', 'o')
      .replaceAll('ô', 'o')
      .replaceAll('õ', 'o')
      .replaceAll('ú', 'u')
      .replaceAll('ç', 'c');
}

_GroupTheme _themeFor(String idOrName) {
  final key = _normalize(idOrName);

  // Roxo (gamer)
  const purple = _GroupTheme(
    gradient: [Color(0xFF6638B6), Color(0xFF634A9E)],
    border: Color(0xFF6C52BB),
    desc: Color(0xFFD5C4F3),
    user: Color(0xFFA259FF),
  );

  // Azul (geral)
  const blue = _GroupTheme(
    gradient: [Color(0xFF3251A3), Color(0xFF2E3F7A)],
    border: Color(0xFF678EE6),
    desc: Color(0xFF9AB5EF),
    user: Color(0xFF678EE6),
  );

  // Vermelho (cibersegurança)
  const red = _GroupTheme(
    gradient: [Color(0xFF834748), Color(0xFF5E3334)],
    border: Color(0xFFD07274),
    desc: Color(0xFFD58F90),
    user: Color(0xFFD64344),
  );

  // Verde (dúvidas)
  const green = _GroupTheme(
    gradient: [Color(0xFF2E8B57), Color(0xFF236C44)],
    border: Color(0xFF58C08A),
    desc: Color(0xFFA8E0C7),
    user: Color(0xFF58C08A),
  );

  if (key.contains('geral')) return blue;
  if (key.contains('duvida')) return green;
  if (key.contains('gamer')) return purple;
  if (key.contains('ciber')) return red;

  // fallback: roxo
  return purple;
}

class BoardsScreen extends StatefulWidget {
  const BoardsScreen({super.key});

  @override
  State<BoardsScreen> createState() => _BoardsScreenState();
}

class _GroupTheme {
  final List<Color> gradient;
  final Color border;
  final Color desc;    // descrição
  final Color user;    // cor do "nome do usuário" na última msg
  const _GroupTheme({
    required this.gradient,
    required this.border,
    required this.desc,
    required this.user,
  });
}

class _BoardsScreenState extends State<BoardsScreen> {
  bool _showGroups = true;
  Future<void> _openCreatePostSheet() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Faça login para postar.')),
    );
    return;
  }

  final controller = TextEditingController();
  bool isPosting = false;

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF2A2F3E),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) {
      final viewInset = MediaQuery.of(ctx).viewInsets.bottom;
      return Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + viewInset),
        child: StatefulBuilder(
          builder: (context, setSheetState) {
            Future<void> submit() async {
              final text = controller.text.trim();
              if (text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Escreva algo antes de publicar.')),
                );
                return;
              }
              setSheetState(() => isPosting = true);
              try {
                await FirebaseFirestore.instance.collection('posts').add({
                  'text': text,
                  'authorId': user.uid,
                  'authorName': user.displayName ?? 'Usuário',
                  'createdAt': FieldValue.serverTimestamp(),
                  'parentId': null, // raiz (não é reply/thread)
                  'likes': 0,
                  'commentsCount': 0,
                });
                Navigator.of(context).pop(); // fecha o sheet
                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(content: Text('Post publicado!')),
                );
              } catch (e) {
                setSheetState(() => isPosting = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erro ao publicar: $e')),
                );
              }
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Novo post',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  maxLines: 6,
                  maxLength: 500,
                  style: const TextStyle(color: Colors.white, fontFamily: 'Poppins'),
                  decoration: InputDecoration(
                    hintText: 'Escreva algo…',
                    hintStyle: const TextStyle(color: Colors.white70, fontFamily: 'Poppins'),
                    filled: true,
                    fillColor: const Color(0xFF3A4052),
                    counterStyle: const TextStyle(color: Colors.white54, fontFamily: 'Poppins'),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF6C52BB)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.primaryPurple, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: isPosting ? null : () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white24),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          textStyle: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
                        ),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: isPosting ? null : submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryPurple,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          textStyle: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700),
                        ),
                        child: isPosting
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Publicar'),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      );
    },
  );
}

  Future<void> addBoard() async {
    final controller = TextEditingController();
    final descriptionController = TextEditingController();

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Novo Grupo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(labelText: 'Nome do grupo'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: 'Descrição (opcional)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(context, {
              'name': controller.text.trim(),
              'description': descriptionController.text.trim(),
            }),
            child: const Text('Criar'),
          ),
        ],
      ),
    );

    if (result == null) return;

    final name = result['name'] ?? '';
    final description = result['description'] ?? '';

    if (name.isEmpty) return;

    // cria um id "slug"
    String id = name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_\$'), '');

    if (id.isEmpty) id = DateTime.now().millisecondsSinceEpoch.toString();

    final groups = FirebaseFirestore.instance.collection('groups');

    try {
      final doc = await groups.doc(id).get();
      if (doc.exists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Grupo já existe.')),
          );
        }
        return;
      }

      await groups.doc(id).set({
        'name': name,
        'description': description,
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessage': '',
        'lastMessageAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Grupo "$name" criado.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Falha ao criar grupo: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupsRef = FirebaseFirestore.instance.collection('groups');

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: Container(
          color: Colors.transparent,
          padding: const EdgeInsets.only(top: 68, left: 16),
          alignment: Alignment.topLeft,
          child: const Text(
            '<Fórum./>',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Color(0xFF8447D6),
              fontFamily: 'Poppins',
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          ForumSwitcher(
            showGroups: _showGroups,
            onChanged: (val) => setState(() => _showGroups = val),
          ),
          Expanded(
            child: _showGroups ? _buildGroupsList() : const TimelineFeed(),
          ),
        ],
      ),
      // 👇 FAB só na Timeline
      floatingActionButton: _showGroups
          ? null
          : FloatingActionButton.extended(
              onPressed: _openCreatePostSheet,
              backgroundColor: AppColors.primaryPurple,
              icon: const Icon(Icons.edit),
              label: const Text(
                'Postar',
                style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
              ),
            ),
    );
  }

  Widget _buildGroupsList() {
    final groupsRef = FirebaseFirestore.instance.collection('groups');

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: groupsRef.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Erro ao carregar grupos', style: TextStyle(color: Colors.white)));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];
        debugPrint('🔥 Groups loaded: ${docs.length}');
        if (docs.isEmpty) {
          return const Center(
            child: Text(
              'Nenhum grupo encontrado.',
              style: TextStyle(color: Colors.white70),
            ),
          );
        }

        return ListView.separated(
          itemCount: docs.length,
          separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.white12),
          itemBuilder: (context, index) {
            final data = docs[index].data();
            final name = (data['name'] ?? '') is String ? data['name'] as String : data['name']?.toString() ?? '';
            final description = (data['description'] ?? '') is String ? data['description'] as String : data['description']?.toString() ?? '';
            final lastMessage = (data['lastMessage'] ?? '') is String ? data['lastMessage'] as String : data['lastMessage']?.toString() ?? '';

            final id = docs[index].id;
            final theme = _themeFor(name.isNotEmpty ? name : id);

            final preview = lastMessage.isNotEmpty ? lastMessage : description;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: GroupCard(
                title: '<${name.isNotEmpty ? name : id}/>',
                description: description.isNotEmpty ? description : 'Sem descrição',
                lastMessageUser: 'User',
                lastMessageText: preview.isNotEmpty ? preview : 'Sem mensagens ainda',
                gradient: theme.gradient,
                borderColor: theme.border,
                onEnter: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => BoardScreen(boardName: name)),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  // (removed _buildTimeline)
}

