import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class TimelineFeed extends StatelessWidget {
  const TimelineFeed({super.key});

  String _normalize(String s) => s.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '_');

  @override
  Widget build(BuildContext context) {
    final postsRef = FirebaseFirestore.instance
        .collection('posts')
        .where('parentId', isNull: true)
        .orderBy('createdAt', descending: true)
        .limit(50);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: postsRef.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Text('Erro ao carregar timeline', style: TextStyle(color: Colors.white)),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(
            child: Text('Sem posts ainda 🙂', style: TextStyle(color: Colors.white70)),
          );
        }

        return ListView.separated(
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          itemBuilder: (context, index) {
            final snap = docs[index];
            final data = snap.data();

            final text = (data['text'] ?? '').toString();
            final authorName = (data['authorName'] ?? 'Usuário').toString();
            final authorHandle =
                (data['authorHandle'] ?? _normalize(authorName)).toString();
            final likes = (data['likes'] ?? 0) is int
                ? data['likes'] as int
                : int.tryParse('${data['likes']}') ?? 0;
            final likedBy = (data['likedBy'] ?? []) is List
                ? List<String>.from(data['likedBy'] as List)
                : <String>[];

            final ts = data['createdAt'] as Timestamp?;
            final dt = ts?.toDate();
            final now = DateTime.now();
            String timeAgo = '';
            if (dt != null) {
              final diff = now.difference(dt);
              if (diff.inMinutes < 60) {
                timeAgo = '${diff.inMinutes}m';
              } else if (diff.inHours < 24) {
                timeAgo = '${diff.inHours}h';
              } else {
                timeAgo = '${diff.inDays}d';
              }
            }

            final uid = FirebaseAuth.instance.currentUser?.uid;
            final isLiked = uid != null && likedBy.contains(uid);

            return _PostCard(
              postId: snap.id,
              text: text,
              authorName: authorName,
              authorHandle: '@$authorHandle',
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

class _PostCard extends StatelessWidget {
  final String postId;
  final String text;
  final String authorName;
  final String authorHandle;
  final String timeLabel;
  final int likeCount;
  final bool isLiked;

  const _PostCard({
    required this.postId,
    required this.text,
    required this.authorName,
    required this.authorHandle,
    required this.timeLabel,
    required this.likeCount,
    required this.isLiked,
  });

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return 'U';
    final first = parts.first.isNotEmpty ? parts.first[0] : '';
    final last = parts.length > 1 && parts.last.isNotEmpty ? parts.last[0] : '';
    return (first + last).toUpperCase();
  }

  Future<void> _toggleLike(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Faça login para curtir.')),
      );
      return;
    }

    final postRef = FirebaseFirestore.instance.collection('posts').doc(postId);
    await FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(postRef);
      if (!snap.exists) return;

      final data = snap.data() as Map<String, dynamic>;
      final currentLikes = (data['likes'] ?? 0) is int
          ? data['likes'] as int
          : int.tryParse('${data['likes']}') ?? 0;
      final likedBy = (data['likedBy'] ?? []) is List
          ? List<String>.from(data['likedBy'] as List)
          : <String>[];

      final already = likedBy.contains(user.uid);
      if (already) {
        tx.update(postRef, {
          'likedBy': FieldValue.arrayRemove([user.uid]),
          'likes': currentLikes > 0 ? currentLikes - 1 : 0,
        });
      } else {
        tx.update(postRef, {
          'likedBy': FieldValue.arrayUnion([user.uid]),
          'likes': currentLikes + 1,
        });
      }
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
      builder: (ctx) => _CommentsSheet(postId: postId),
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
          // Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar
              Container(
                height: 36,
                width: 36,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFFA259FF), Color(0xFF8447D6)],
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  _initials(authorName),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Nome + handle + menu
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            authorName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              fontFamily: 'Poppins',
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.more_horiz, color: Colors.white54, size: 18),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$authorHandle · $timeLabel',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Texto
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              height: 1.4,
              fontFamily: 'Poppins',
            ),
          ),

          const SizedBox(height: 12),
          const Divider(color: Color(0x22FFFFFF), height: 1),
          const SizedBox(height: 8),

          // Ações
          Row(
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => _toggleLike(context),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isLiked ? Icons.favorite : Icons.favorite_border,
                        size: 18,
                        color: isLiked ? AppColors.primaryPurple : Colors.white70,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$likeCount',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 18),
              // Comments (live count)
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('posts')
                    .doc(postId)
                    .collection('comments')
                    .orderBy('createdAt', descending: false)
                    .snapshots(),
                builder: (context, snap) {
                  final count = snap.data?.docs.length ?? 0;
                  return InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => _openComments(context),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.mode_comment_outlined, color: Colors.white70, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            '$count',
                            style: const TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'Poppins'),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 18),
              _ActionIcon(icon: Icons.share_outlined, label: '0', onTap: () {}),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionIcon({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white70, size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'Poppins'),
            ),
          ],
        ),
      ),
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
      final usersRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      final userSnap = await usersRef.get();
      final authorName = (userSnap.data()?['name'] ?? user.email ?? 'Usuário') as String;

      await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .collection('comments')
          .add({
        'text': text,
        'authorId': user.uid,
        'authorName': authorName,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _controller.clear();
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sheetPadding = MediaQuery.of(context).viewInsets;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: sheetPadding.bottom),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.8,
          child: Column(
            children: [
              // Header
              Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                alignment: Alignment.centerLeft,
                child: const Text(
                  'Comentários',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontFamily: 'Poppins', fontWeight: FontWeight.w600),
                ),
              ),
              const Divider(color: Color(0x22FFFFFF), height: 1),

              // Lista de comentários
              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('posts')
                      .doc(widget.postId)
                      .collection('comments')
                      .orderBy('createdAt', descending: false)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const Center(child: Text('Erro ao carregar', style: TextStyle(color: Colors.white70)));
                    }
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final docs = snapshot.data!.docs;
                    if (docs.isEmpty) {
                      return const Center(child: Text('Seja o primeiro a comentar!', style: TextStyle(color: Colors.white70)));
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: docs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final c = docs[index].data();
                        return _CommentTile(
                          authorName: (c['authorName'] ?? 'Usuário').toString(),
                          text: (c['text'] ?? '').toString(),
                          createdAt: c['createdAt'] as Timestamp?,
                        );
                      },
                    );
                  },
                ),
              ),

              // Campo de envio
              Container(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: Color(0x22FFFFFF))),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF2B3242),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0x334D5A7A)),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: TextField(
                          controller: _controller,
                          minLines: 1,
                          maxLines: 4,
                          style: const TextStyle(color: Colors.white, fontFamily: 'Poppins'),
                          decoration: const InputDecoration(
                            hintText: 'Escreva um comentário…',
                            hintStyle: TextStyle(color: Colors.white70, fontFamily: 'Poppins'),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _sending ? null : _send,
                      icon: const Icon(Icons.send_rounded, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  final String authorName;
  final String text;
  final Timestamp? createdAt;
  const _CommentTile({required this.authorName, required this.text, required this.createdAt});

  String _timeAgo(DateTime? dt) {
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Avatar simples
        Container(
          height: 28,
          width: 28,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(colors: [Color(0xFFA259FF), Color(0xFF8447D6)]),
          ),
          alignment: Alignment.center,
          child: Text(
            authorName.isNotEmpty ? authorName[0].toUpperCase() : 'U',
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      authorName,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontFamily: 'Poppins'),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _timeAgo(createdAt?.toDate()),
                    style: const TextStyle(color: Colors.white54, fontSize: 12, fontFamily: 'Poppins'),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                text,
                style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4, fontFamily: 'Poppins'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}