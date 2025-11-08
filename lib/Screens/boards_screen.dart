import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'Subscreens/group_screen.dart';
import 'Subscreens/timeline_feed.dart';
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
    const double kBottomNavBarHeight = 92.0;

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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: _NewForumSwitcher(
              showGroups: _showGroups,
              onChanged: _onSwitcherChanged,
            ),
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
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton.extended(
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
                const SizedBox(height: kBottomNavBarHeight), 
              ],
            ),
    );
  }
}

// --- CLASSE AUXILIAR PARA DEFINIR ÍCONES E CORES ---
class GroupDisplayInfo {
  final IconData iconData;
  final Color backgroundColor;

  const GroupDisplayInfo({required this.iconData, required this.backgroundColor});

  static GroupDisplayInfo fromId(String id) {
    final key = id.toLowerCase();
    if (key.contains('geral')) return const GroupDisplayInfo(iconData: Icons.tag, backgroundColor: Color(0xFF58B038)); // Verde
    if (key.contains('dev')) return const GroupDisplayInfo(iconData: Icons.code, backgroundColor: Color(0xFF4C8DFF)); // Azul
    if (key.contains('gamer')) return const GroupDisplayInfo(iconData: Icons.gamepad_outlined, backgroundColor: Color(0xFFFFCC00)); // Amarelo
    if (key.contains('ciber')) return const GroupDisplayInfo(iconData: Icons.security_outlined, backgroundColor: Color(0xFFFF3B30)); // Vermelho
    if (key.contains('duvida')) return const GroupDisplayInfo(iconData: Icons.help_outline, backgroundColor: Color(0xFF6C52BB)); // Roxo
    return const GroupDisplayInfo(iconData: Icons.forum_outlined, backgroundColor: Color(0xFFA259FF)); 
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
          padding: const EdgeInsets.fromLTRB(0, 8, 0, 110),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data();
            
            final name = data['name'] as String? ?? 'Grupo sem nome';
            final description = data['description'] as String? ?? 'Sem descrição';
            final lastMessage = data['lastMessage'] as String? ?? '';
            final preview = lastMessage.isNotEmpty ? lastMessage : description;
            
            final memberCount = (data['memberCount'] as int?) ?? 0;
            final postCount = (data['postCount'] as int?) ?? 0;
            
            final displayInfo = GroupDisplayInfo.fromId(doc.id);

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: GroupCard(
                title: '<$name/>',
                description: description,
                lastMessageUser: 'User',
                lastMessageText: preview,
                onEnter: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => BoardScreen(
                      boardId: doc.id, 
                      boardName: name,
                      // ###################### CORREÇÃO AQUI ######################
                      // Passando os dados do ícone para a próxima tela
                      iconData: displayInfo.iconData,
                      iconBackgroundColor: displayInfo.backgroundColor,
                      // ###########################################################
                    )),
                  );
                },
                iconData: displayInfo.iconData,
                iconBackgroundColor: displayInfo.backgroundColor,
                memberCount: memberCount,
                postCount: postCount,
              ),
            );
          },
        );
      },
    );
  }
}

// ... (Resto do arquivo: _CreatePostSheet, _NewForumSwitcher, _SwitcherButton...)
// ... (COLE O RESTO DO SEU ARQUIVO boards_screen.dart AQUI)
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

class _NewForumSwitcher extends StatelessWidget {
  final bool showGroups;
  final ValueChanged<bool> onChanged;

  const _NewForumSwitcher({
    required this.showGroups,
    required this.onChanged,
  });

  static const backgroundColor = Color(0xFF3F4968);
  static const activeGradient = LinearGradient(
    begin: Alignment(0.00, 0.50),
    end: Alignment(1.00, 0.50),
    colors: [Color(0xFFA259FF), Color(0xFF8447D6)],
  );
  static const activeTextColor = Colors.white;
  static const inactiveTextColor = Color(0xFFC6C5C3); 

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width - 32;
    
    return Container(
      width: screenWidth,
      height: 33,
      padding: const EdgeInsets.all(3),
      decoration: ShapeDecoration(
        color: backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            alignment: showGroups ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: (screenWidth - 6) / 2,
              height: 27,
              decoration: ShapeDecoration(
                gradient: activeGradient,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: _SwitcherButton(
                  text: 'Timeline',
                  icon: Icons.chat_bubble_outline,
                  isActive: !showGroups,
                  activeColor: activeTextColor,
                  inactiveColor: inactiveTextColor,
                  onTap: () {
                    onChanged(false);
                  },
                ),
              ),
              Expanded(
                child: _SwitcherButton(
                  text: 'Grupos',
                  icon: Icons.people_outline,
                  isActive: showGroups,
                  activeColor: activeTextColor,
                  inactiveColor: inactiveTextColor,
                  onTap: () {
                    onChanged(true);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SwitcherButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final bool isActive;
  final Color activeColor;
  final Color inactiveColor;
  final VoidCallback onTap;

  const _SwitcherButton({
    required this.text,
    required this.icon,
    required this.isActive,
    required this.activeColor,
    required this.inactiveColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color color = isActive ? activeColor : inactiveColor;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: 27,
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Text(
                text,
                style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}