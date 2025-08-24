import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BoardScreen extends StatefulWidget {
  final String boardName;
  const BoardScreen({super.key, required this.boardName});

  @override
  State<BoardScreen> createState() => _BoardScreenState();
}

class _BoardScreenState extends State<BoardScreen> {
  final TextEditingController _controller = TextEditingController();
  File? _image;
  Map<String, dynamic>? _replyTo;

  @override
  void initState() {
    super.initState();
  }

  void sendPost() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    final now = FieldValue.serverTimestamp();

    final data = <String, dynamic>{
      'text': text,
      'userId': user?.uid,
      'userName': user?.displayName ?? 'Usuário',
      'timestamp': now,
      if (_replyTo != null)
        'replyTo': {
          'text': _replyTo!['text'] ?? '',
          'userId': _replyTo!['userId'],
        },
    };

    await FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.boardName) // Usando o nome do grupo como ID
        .collection('messages')
        .add(data);

    setState(() {
      _controller.clear();
      _image = null; // ignorado por enquanto (sem Storage)
      _replyTo = null;
    });
  }

  String _formatTime(dynamic ts) {
    if (ts is Timestamp) {
      final dt = ts.toDate();
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '$h:$m';
    }
    if (ts is String) return ts;
    return '';
  }

  Widget _replyPreview(Map<String, dynamic> reply) {
    final hasText = reply['text'] != null && reply['text'] != '';
    final hasImage = reply['image'] != null && reply['image'] != '';
    if (!hasText && !hasImage) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(6),
      ),
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          const Icon(Icons.reply, color: Color(0xFF7F2AB1), size: 18),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasText)
                  Text(
                    reply['text'],
                    style: const TextStyle(
                      color: Color(0xFFFAF9F6),
                      fontStyle: FontStyle.italic,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (hasImage)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Container(
                      height: 40,
                      width: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.image, size: 18, color: Colors.white54),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Bolha de mensagem RECEBIDA (alinhada à direita, margem direita 8)
  Widget _buildReceivedBubble(Map<String, dynamic> p) {
    final double maxBubbleW = MediaQuery.of(context).size.width - 16 /*screen right pad*/ - 40 /*avatar*/ - 8 /*gap*/ - 16 /*screen left pad safety*/;
    final String text = (p['text'] ?? '').toString();
    final String time = _formatTime(p['timestamp']);
    final hasImage = p['image'] != null && p['image'] != '';
    final hasReply = p['replyTo'] != null;
    final String userName = p['userName'] ?? 'Usuário';

    final bubble = Container(
      constraints: BoxConstraints(maxWidth: maxBubbleW.clamp(180, double.infinity)),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment(0.08, 0.68),
          end: Alignment(0.59, 0.69),
          colors: [Color(0xFF6638B6), Color(0xFF634A9E)],
        ),
        border: Border.all(color: Color(0xFF6C52BB), width: 1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasReply) _replyPreview(Map<String, dynamic>.from(p['replyTo'])),
          Text(
            userName,
            style: const TextStyle(
              color: Color(0xFFB3A9D6),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (hasImage) const SizedBox.shrink(),
          Text(
            text,
            style: const TextStyle(
              color: Color(0xFFAE85E5),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.bottomRight,
            child: Text(
              time,
              style: const TextStyle(
                color: Color(0xFFAD91D4),
                fontSize: 9,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(right: 16, top: 6, bottom: 6),
      child: Align(
        alignment: Alignment.centerRight,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircleAvatar(radius: 20, backgroundColor: Color(0xFFD9D9D9)),
            const SizedBox(width: 8),
            bubble,
          ],
        ),
      ),
    );
  }

  /// Bolha de mensagem ENVIADA (usuário logado) – alinhada à esquerda, avatar à direita, margem esquerda 8
  Widget _buildSentBubble(Map<String, dynamic> p) {
    final double maxBubbleW = MediaQuery.of(context).size.width - 16 /*screen left pad*/ - 40 /*avatar*/ - 8 /*gap*/ - 16 /*screen right pad safety*/;
    final String text = (p['text'] ?? '').toString();
    final String time = _formatTime(p['timestamp']);
    final hasImage = p['image'] != null && p['image'] != '';
    final hasReply = p['replyTo'] != null;
    final String userName = FirebaseAuth.instance.currentUser?.displayName ?? 'Usuário';

    final bubble = Container(
      constraints: BoxConstraints(maxWidth: maxBubbleW.clamp(180, double.infinity)),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xAD3251A3),
        border: Border.all(color: Color(0xFF678EE6), width: 1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasReply) _replyPreview(Map<String, dynamic>.from(p['replyTo'])),
          Text(
            userName,
            style: const TextStyle(
              color: Color(0xFFB3C2E5),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (hasImage) const SizedBox.shrink(),
          Text(
            text,
            style: const TextStyle(
              color: Color(0xFF9AB5EF),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.bottomRight,
            child: Text(
              time,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 9,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 6, bottom: 6),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            bubble,
            const SizedBox(width: 8),
            const CircleAvatar(radius: 20, backgroundColor: Color(0xFF678EE6)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 68, bottom: 63),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Color(0xFFA259FF)),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 8),
                Text(
                  '<${widget.boardName}./>',
                  style: const TextStyle(
                    color: Color(0xFFA259FF),
                    fontSize: 22,
                    fontFamily: 'JetBrains Mono',
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('groups')
                        .doc(widget.boardName)
                        .collection('messages')
                        .orderBy('timestamp', descending: true)
                        .snapshots(),
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!snap.hasData || snap.data!.docs.isEmpty) {
                        return const Center(
                          child: Text(
                            'Sem mensagens ainda',
                            style: TextStyle(color: Color(0xFFFAF9F6)),
                          ),
                        );
                      }
                      final docs = snap.data!.docs;
                      return ListView.builder(
                        reverse: true,
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final doc = docs[index];
                          final p = doc.data() as Map<String, dynamic>;
                          final isMine = (FirebaseAuth.instance.currentUser?.uid ?? '') == (p['userId'] ?? '');
                          return GestureDetector(
                            onLongPress: () {
                              setState(() {
                                _replyTo = {
                                  'id': doc.id,
                                  'text': p['text'],
                                  'userId': p['userId'],
                                };
                              });
                            },
                            child: isMine
                                ? _buildSentBubble(p)
                                : _buildReceivedBubble(p),
                          );
                        },
                      );
                    },
                  ),
                ),
                if (_replyTo != null)
                  Container(
                    color: Colors.grey[900],
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.reply, color: Color(0xFF7F2AB1), size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (_replyTo!['text'] != null && _replyTo!['text'] != '')
                                Text(
                                  _replyTo!['text'],
                                  style: const TextStyle(
                                    color: Color(0xFFFAF9F6),
                                    fontStyle: FontStyle.italic,
                                    fontSize: 14,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              if (_replyTo!['image'] != null && _replyTo!['image'] != '')
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Container(
                                    height: 40,
                                    width: 40,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: Colors.white10,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Icon(Icons.image, size: 18, color: Colors.white54),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white54),
                          onPressed: () => setState(() => _replyTo = null),
                        ),
                      ],
                    ),
                  ),
                // ===== Input custom (estilo Figma) =====
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
                  child: Row(
                    children: [
                      // Campo de texto estilizado
                      Expanded(
                        child: Container(
                          height: 43,
                          decoration: BoxDecoration(
                            color: const Color(0xB2515767),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFF7884C4),
                              width: 1,
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Row(
                            children: [
                              // Hint + texto
                              Expanded(
                                child: TextField(
                                  controller: _controller,
                                  style: const TextStyle(
                                    color: Color(0xFFFAF9F6),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  decoration: const InputDecoration(
                                    isCollapsed: true,
                                    border: InputBorder.none,
                                    hintText: 'Digite aqui...',
                                    hintStyle: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w600,
                                      height: 1.83,
                                    ),
                                  ),
                                ),
                              ),
                              // Ícone de microfone (placeholder)
                              InkWell(
                                borderRadius: BorderRadius.circular(20),
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Voz indisponível no momento.'),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                                child: const Padding(
                                  padding: EdgeInsets.only(left: 8),
                                  child: Icon(Icons.mic, size: 18, color: Colors.white70),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Botão enviar com gradiente
                      InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: sendPost,
                        child: Container(
                          width: 43,
                          height: 43,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment(0.00, 0.83),
                              end: Alignment(0.84, 0.37),
                              colors: [
                                Color(0xB2AE85E5),
                                Color(0xFF8447D6),
                                Color(0xFF572698),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.send_rounded, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}