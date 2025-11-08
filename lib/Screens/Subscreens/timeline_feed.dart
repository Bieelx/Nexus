import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../profile_page.dart';

class TimelineFeed extends StatelessWidget {
  const TimelineFeed({super.key});

  @override
  Widget build(BuildContext context) {
    // Vamos calcular a altura da navbar + safe area + o próprio FAB
    // para que o último item da lista possa rolar para cima
    const double bottomClearance = 170.0; // Ajuste este valor se necessário

    final postsRef = FirebaseFirestore.instance
        .collection('posts')
        .where('parentId', isNull: true)
        .orderBy('createdAt', descending: true)
        .limit(50);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: postsRef.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Erro ao carregar timeline', style: TextStyle(color: Colors.white)));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(child: Text('Sem posts ainda 🙂', style: TextStyle(color: Colors.white70)));
        }
        return ListView.separated(
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          // CORREÇÃO DO PADDING INFERIOR:
          padding: const EdgeInsets.fromLTRB(16, 12, 16, bottomClearance),
          itemBuilder: (context, index) {
            final snap = docs[index];
            final data = snap.data();
            
            final authorId = data['authorId'] as String?;
            final text = data['text'] as String? ?? '';
            final likes = (data['likes'] as int?) ?? 0;
            final likedBy = (data['likedBy'] as List?)?.map((e) => e.toString()).toList() ?? [];

            final ts = data['createdAt'] as Timestamp?;
            final dt = ts?.toDate();
            String timeAgo = '';
            if (dt != null) {
              final diff = DateTime.now().difference(dt);
              if (diff.inMinutes < 60) timeAgo = '${diff.inMinutes}m';
              else if (diff.inHours < 24) timeAgo = '${diff.inHours}h';
              else timeAgo = '${diff.inDays}d';
            }

            final uid = FirebaseAuth.instance.currentUser?.uid;
            final isLiked = uid != null && likedBy.contains(uid);

            return _PostCard(
              postId: snap.id,
              authorId: authorId,
              text: text,
              timeLabel: timeAgo,
              likeCount: likes,
              isLiked: isLiked,
            );
          },
        );
      },
    );
  }
}

class _PostCard extends StatefulWidget {
  final String postId;
  final String? authorId;
  final String text;
  final String timeLabel;
  final int likeCount;
  final bool isLiked;

  const _PostCard({
    required this.postId, this.authorId, required this.text,
    required this.timeLabel, required this.likeCount, required this.isLiked,
  });

  @override
  State<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<_PostCard> {
  String _resolvedAuthorName = 'Usuário';
  String _resolvedUsername = '';
  String? _resolvedAuthorPhotoUrl;

  @override
  void initState() {
    super.initState();
    _resolveAuthorData();
  }

  Future<void> _resolveAuthorData() async {
    if (widget.authorId == null) return;
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(widget.authorId).get();
      if (userDoc.exists && mounted) {
        final data = userDoc.data()!;
        final nome = data['nome'] as String? ?? '';
        final sobrenome = data['sobrenome'] as String? ?? '';
        final username = data['username'] as String? ?? '';
        final fullName = '$nome $sobrenome'.trim();
        
        setState(() {
          _resolvedAuthorName = fullName.isNotEmpty ? fullName : 'Usuário';
          _resolvedUsername = username;
          // Corrigido: 'authorPhotoUrl' -> 'photoUrl' para bater com seu DB
          _resolvedAuthorPhotoUrl = data['photoUrl'] as String?;
        });
      }
    } catch (e) { /* silent fail */ }
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'U';
    final first = parts.first[0];
    final last = parts.length > 1 && parts.last.isNotEmpty ? parts.last[0] : '';
    return (first + last).toUpperCase();
  }
  
  Future<void> _toggleLike() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final postRef = FirebaseFirestore.instance.collection('posts').doc(widget.postId);
    await postRef.update({
      'likedBy': widget.isLiked ? FieldValue.arrayRemove([user.uid]) : FieldValue.arrayUnion([user.uid]),
      'likes': FieldValue.increment(widget.isLiked ? -1 : 1),
    });
  }

  Future<void> _openComments(BuildContext context) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF202634),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _CommentsSheet(postId: widget.postId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2B3242),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x334D5A7A)),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(36),
                onTap: () {
                  if (widget.authorId != null) {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => ProfilePage(userId: widget.authorId)));
                  }
                },
                child: CircleAvatar(
                  radius: 18,
                  backgroundImage: _resolvedAuthorPhotoUrl != null && _resolvedAuthorPhotoUrl!.isNotEmpty ? NetworkImage(_resolvedAuthorPhotoUrl!) : null,
                  backgroundColor: AppColors.primaryPurple,
                  child: (_resolvedAuthorPhotoUrl == null || _resolvedAuthorPhotoUrl!.isEmpty)
                      ? Text(_initials(_resolvedAuthorName), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
                      : null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _resolvedAuthorName,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14, fontFamily: 'Poppins'),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (_resolvedUsername.isNotEmpty)
                          Text(
                            '@$_resolvedUsername',
                            style: const TextStyle(color: AppColors.primaryPurple, fontSize: 12, fontFamily: 'Poppins'),
                            overflow: TextOverflow.ellipsis,
                          ),
                        if (_resolvedUsername.isNotEmpty)
                          const Text(" · ", style: TextStyle(color: Colors.white54, fontSize: 12)),
                        Text(
                          widget.timeLabel,
                          style: const TextStyle(color: Colors.white54, fontSize: 12, fontFamily: 'Poppins'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.more_horiz, color: Colors.white54, size: 18),
            ],
          ),
          const SizedBox(height: 10),
          Text(widget.text, style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4, fontFamily: 'Poppins')),
          const SizedBox(height: 12),
          const Divider(color: Color(0x22FFFFFF), height: 1),
          const SizedBox(height: 8),
          Row(
            children: [
              _ActionIcon(
                onTap: _toggleLike,
                icon: widget.isLiked ? Icons.favorite : Icons.favorite_border,
                label: widget.likeCount.toString(),
                color: widget.isLiked ? AppColors.primaryPurple : Colors.white70,
              ),
              const SizedBox(width: 18),
              _CommentIcon(
                postId: widget.postId,
                onTap: () => _openComments(context),
              ),
              const SizedBox(width: 18),
              _ActionIcon(onTap: () {}, icon: Icons.share_outlined, label: '0'),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  final VoidCallback onTap;
  final IconData icon;
  final String label;
  final Color? color;
  const _ActionIcon({required this.onTap, required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color ?? Colors.white70),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'Poppins')),
          ],
        ),
      ),
    );
  }
}

class _CommentIcon extends StatelessWidget {
  final String postId;
  final VoidCallback onTap;
  const _CommentIcon({required this.postId, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('posts').doc(postId).collection('comments').snapshots(),
      builder: (context, snapshot) {
        final count = snapshot.data?.docs.length ?? 0;
        return _ActionIcon(
          onTap: onTap,
          icon: Icons.mode_comment_outlined,
          label: count.toString(),
        );
      },
    );
  }
}

class _CommentsSheet extends StatefulWidget {
  final String postId;
  const _CommentsSheet({required this.postId});
  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  final TextEditingController _controller = TextEditingController();
  bool _sending = false;

  Future<void> _send() async {
    final user = FirebaseAuth.instance.currentUser;
    final text = _controller.text.trim();
    if (user == null || text.isEmpty) return;

    setState(() => _sending = true);
    try {
      final userSnap = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final currentUserData = userSnap.data() ?? {};
      final authorName = '${currentUserData['nome'] ?? ''} ${currentUserData['sobrenome'] ?? ''}'.trim();

      await FirebaseFirestore.instance.collection('posts').doc(widget.postId).collection('comments').add({
        'text': text,
        'authorId': user.uid,
        'authorName': authorName.isNotEmpty ? authorName : 'Usuário',
        'username': currentUserData['username'] ?? '',
        'authorPhotoUrl': currentUserData['photoUrl'] ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      });
      _controller.clear();
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text('Comentários', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
            ),
            const Divider(color: Color(0x22FFFFFF), height: 1),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance.collection('posts').doc(widget.postId).collection('comments').orderBy('createdAt').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  final docs = snapshot.data!.docs;
                  if (docs.isEmpty) return const Center(child: Text('Seja o primeiro a comentar!', style: TextStyle(color: Colors.white70)));
                  return ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final c = docs[index].data();
                      return _CommentTile(
                        authorName: c['authorName'] ?? 'Usuário',
                        text: c['text'] ?? '',
                        createdAt: c['createdAt'],
                        authorPhotoUrl: c['authorPhotoUrl'] ?? '',
                      );
                    },
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0x22FFFFFF)))),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1, maxLines: 4,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Escreva um comentário…',
                        hintStyle: TextStyle(color: Colors.white70),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  IconButton(onPressed: _sending ? null : _send, icon: const Icon(Icons.send_rounded, color: Colors.white)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  final String authorName, text, authorPhotoUrl;
  final Timestamp? createdAt;
  const _CommentTile({required this.authorName, required this.text, this.createdAt, required this.authorPhotoUrl});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(radius: 14, backgroundImage: authorPhotoUrl.isNotEmpty ? NetworkImage(authorPhotoUrl) : null),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(authorName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(text, style: const TextStyle(color: Colors.white, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}