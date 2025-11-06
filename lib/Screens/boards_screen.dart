import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'Subscreens/group_screen.dart';
import 'Subscreens/timeline_feed.dart';
import '../widgets/forum/forum_switcher.dart';
import '../widgets/forum/group_card.dart';
import '../core/theme/app_colors.dart';

class BoardsScreen extends StatefulWidget {
  const BoardsScreen({super.key});

  @override
  State<BoardsScreen> createState() => _BoardsScreenState();
}

class _BoardsScreenState extends State<BoardsScreen> {
  bool _showGroups = true;

  void _onSwitcherChanged(bool showGroups) {
    setState(() {
      _showGroups = showGroups;
    });
  }

  void _openCreatePostSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF2A2F3E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => const _CreatePostSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: Padding(
          padding: const EdgeInsets.only(top: 68, left: 16),
          child: Align(
            alignment: Alignment.topLeft,
            child: Text(
              '<Fórum./>',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: AppColors.primaryPurple,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          ForumSwitcher(
            showGroups: _showGroups,
            onChanged: _onSwitcherChanged,
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _showGroups
                  ? const _GroupsListView(key: ValueKey('groups'))
                  : const TimelineFeed(key: ValueKey('timeline')),
            ),
          ),
        ],
      ),
      floatingActionButton: _showGroups
          ? null
          : Padding(
              padding: const EdgeInsets.only(bottom: 70.0),
              child: FloatingActionButton.extended(
                onPressed: _openCreatePostSheet,
                backgroundColor: AppColors.primaryPurple,
                icon: const Icon(Icons.edit, color: Colors.white),
                label: const Text(
                  'Postar',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

class _GroupsListView extends StatelessWidget {
  const _GroupsListView({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('groups').orderBy('lastMessageAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Erro ao carregar grupos', style: TextStyle(color: Colors.white)));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(child: Text('Nenhum grupo encontrado.', style: TextStyle(color: Colors.white70)));
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data();
            final name = data['name'] as String? ?? 'Grupo sem nome';
            final description = data['description'] as String? ?? 'Sem descrição';
            final lastMessage = data['lastMessage'] as String? ?? '';
            final preview = lastMessage.isNotEmpty ? lastMessage : description;
            final theme = _GroupTheme.fromId(doc.id);

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: GroupCard(
                title: '<$name/>',
                description: description,
                lastMessageUser: 'User',
                lastMessageText: preview,
                gradient: theme.gradient,
                borderColor: theme.border,
                onEnter: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => BoardScreen(boardId: doc.id, boardName: name)),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}

class _CreatePostSheet extends StatefulWidget {
  const _CreatePostSheet();

  @override
  State<_CreatePostSheet> createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends State<_CreatePostSheet> {
  final _controller = TextEditingController();
  bool _isPosting = false;

  Future<void> _submitPost() async {
    final user = FirebaseAuth.instance.currentUser;
    final text = _controller.text.trim();

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Faça login para postar.')));
      return;
    }

    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Escreva algo antes de publicar.')));
      return;
    }

    setState(() => _isPosting = true);

    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final userData = userDoc.data() ?? {};
      final authorName = (userData['nome'] as String? ?? 'Usuário').trim();
      final username = userData['username'] as String? ?? '';
      final authorPhotoUrl = userData['authorPhotoUrl'] as String? ?? '';

      await FirebaseFirestore.instance.collection('posts').add({
        'text': text,
        'authorId': user.uid,
        'authorName': authorName,
        'username': username,
        'authorPhotoUrl': authorPhotoUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'parentId': null,
        'likes': 0,
        'likedBy': [],
        'commentsCount': 0,
      });

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Post publicado!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao publicar: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isPosting = false);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + viewInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Novo post', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 16, color: Colors.white)),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            maxLines: 6,
            maxLength: 500,
            autofocus: true,
            style: const TextStyle(color: Colors.white, fontFamily: 'Poppins'),
            decoration: InputDecoration(
              hintText: 'Escreva algo…',
              hintStyle: const TextStyle(color: Colors.white70, fontFamily: 'Poppins'),
              filled: true,
              fillColor: const Color(0xFF3A4052),
              counterStyle: const TextStyle(color: Colors.white54, fontFamily: 'Poppins'),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF6C52BB))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.primaryPurple, width: 2)),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isPosting ? null : () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white24), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: const Text('Cancelar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isPosting ? null : _submitPost,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryPurple, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: _isPosting
                      ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Publicar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GroupTheme {
  final List<Color> gradient;
  final Color border;

  const _GroupTheme({required this.gradient, required this.border});

  static _GroupTheme fromId(String id) {
    final key = id.toLowerCase();
    if (key.contains('geral')) return const _GroupTheme(gradient: [Color(0xFF3251A3), Color(0xFF2E3F7A)], border: Color(0xFF678EE6));
    if (key.contains('duvida')) return const _GroupTheme(gradient: [Color(0xFF2E8B57), Color(0xFF236C44)], border: Color(0xFF58C08A));
    if (key.contains('gamer')) return const _GroupTheme(gradient: [Color(0xFF6638B6), Color(0xFF634A9E)], border: Color(0xFF6C52BB));
    if (key.contains('ciber')) return const _GroupTheme(gradient: [Color(0xFF834748), Color(0xFF5E3334)], border: Color(0xFFD07274));
    return const _GroupTheme(gradient: [Color(0xFF6638B6), Color(0xFF634A9E)], border: Color(0xFF6C52BB));
  }
}