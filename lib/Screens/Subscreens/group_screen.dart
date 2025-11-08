import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';

class BoardScreen extends StatefulWidget {
  final String boardId;
  final String boardName;
  // ###################### NOVOS CAMPOS ######################
  final IconData iconData;
  final Color iconBackgroundColor;
  // ########################################################

  const BoardScreen({
    super.key,
    required this.boardId,
    required this.boardName,
    // ###################### NOVOS CAMPOS ######################
    required this.iconData,
    required this.iconBackgroundColor,
    // ########################################################
  });

  @override
  State<BoardScreen> createState() => _BoardScreenState();
}

class _BoardScreenState extends State<BoardScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  Future<void> _sendMessage() async {
    final user = FirebaseAuth.instance.currentUser;
    final text = _messageController.text.trim();

    if (user == null || text.isEmpty) {
      return;
    }

    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final userData = userDoc.data() ?? {};
    final authorName = (userData['nome'] as String? ?? 'Usuário').trim();
    final authorPhotoUrl = userData['photoUrl'] as String? ?? '';

    final groupDocRef = FirebaseFirestore.instance.collection('groups').doc(widget.boardId);
    final newMessageRef = groupDocRef.collection('messages').doc();
    final batch = FirebaseFirestore.instance.batch();

    batch.set(newMessageRef, {
      'text': text,
      'senderId': user.uid,
      'senderName': authorName.isNotEmpty ? authorName : (user.displayName ?? 'Usuário'),
      'senderPhotoUrl': authorPhotoUrl,
      'createdAt': FieldValue.serverTimestamp(),
    });

    batch.update(groupDocRef, {
      'lastMessage': text,
      'lastMessageAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();

    _messageController.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B202E),
      appBar: AppBar(
        // ###################### APPBAR ATUALIZADA ######################
        title: Row(
          children: [
            // 1. O Ícone e a Caixa Colorida
            Container(
              width: 30, // Um pouco menor que no card
              height: 30,
              decoration: ShapeDecoration(
                color: widget.iconBackgroundColor, // Cor vinda da tela anterior
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Icon(widget.iconData, color: Colors.white, size: 18), // Ícone vindo da tela anterior
            ),
            const SizedBox(width: 12),
            // 2. A Coluna de Texto (como no design)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.boardName, style: const TextStyle(fontSize: 16)),
                Text(
                  '245 membros online', // TODO: Esse dado ainda é estático
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ],
        ),
        // ##############################################################
        backgroundColor: const Color(0xFF2A2F3E),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () { /* TODO: Ações do menu */ },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('groups')
                  .doc(widget.boardId)
                  .collection('messages')
                  .orderBy('createdAt', descending: true)
                  .limit(50)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final messages = snapshot.data!.docs;

                WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index].data() as Map<String, dynamic>;
                    final bool isMe = message['senderId'] == FirebaseAuth.instance.currentUser?.uid;
                    
                    final ts = message['createdAt'] as Timestamp?;
                    String time = '';
                    if (ts != null) {
                      time = DateFormat('HH:mm').format(ts.toDate());
                    }

                    return _MessageBubble(
                      senderName: message['senderName'] ?? '',
                      senderPhotoUrl: message['senderPhotoUrl'] as String?,
                      text: message['text'] ?? '',
                      time: time,
                      isMe: isMe,
                    );
                  },
                );
              },
            ),
          ),
          _MessageInputField(
            controller: _messageController,
            onSendPressed: _sendMessage,
          ),
        ],
      ),
    );
  }
}

class _MessageInputField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSendPressed;

  const _MessageInputField({required this.controller, required this.onSendPressed});

  @override
  Widget build(BuildContext context) {
    final double bottomSafeArea = MediaQuery.of(context).padding.bottom;
    final double keyboardPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(
        8,
        8,
        8,
        16 + (keyboardPadding > bottomSafeArea ? keyboardPadding : bottomSafeArea)
      ),
      color: const Color(0xFF2A2F3E),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.attach_file, color: Colors.white70),
            onPressed: () { /* TODO: Anexar arquivo */ },
          ),
          Expanded(
            child: TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Digite sua mensagem...',
                hintStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: const Color(0xFF3A4052),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.emoji_emotions_outlined, color: Colors.white70),
                  onPressed: () { /* TODO: Abrir seletor de emoji */ },
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: const BoxDecoration(
              color: AppColors.primaryPurple,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white, size: 20),
              onPressed: onSendPressed,
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final String senderName;
  final String? senderPhotoUrl;
  final String text;
  final String time;
  final bool isMe;

  const _MessageBubble({
    required this.senderName,
    this.senderPhotoUrl,
    required this.text,
    required this.time,
    required this.isMe,
  });

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    final first = parts.first[0];
    final last = parts.length > 1 && parts.last.isNotEmpty ? parts.last[0] : '';
    return (first + last).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    if (isMe) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Flexible(
            child: Container(
              margin: const EdgeInsets.only(left: 48, top: 4, bottom: 4, right: 8),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: AppColors.primaryPurple,
              ),
              child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 15)),
            ),
          ),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundImage: (senderPhotoUrl != null && senderPhotoUrl!.isNotEmpty)
                ? NetworkImage(senderPhotoUrl!)
                : null,
            backgroundColor: AppColors.primaryPurple.withOpacity(0.3),
            child: (senderPhotoUrl == null || senderPhotoUrl!.isEmpty)
                ? Text(
                    _getInitials(senderName),
                    style: const TextStyle(color: AppColors.primaryPurple, fontWeight: FontWeight.bold, fontSize: 14),
                  )
                : null,
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      senderName,
                      style: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      time,
                      style: const TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: const Color(0xFF3A4052),
                  ),
                  child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 15)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}