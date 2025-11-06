import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Notification summary card (blue) used on HomeScreen
/// It mirrors the previous integrated style but now fetches the
/// unread notifications count from Firestore in real-time.
///
/// Firestore expected structure (example):
/// Collection: posts
///   - authorId: string (owner of the post)
///   - likeCount: number (optional, preferred)
///   - likedBy:   array<string> (optional, fallback if likeCount not present)
/// This card sums all likes across the current user's posts in real-time.
///
/// Usage:
/// NotificationSummaryCardBlue(onTap: () { /* open notifications */ })
class NotificationSummaryCardBlue extends StatefulWidget {
  const NotificationSummaryCardBlue({super.key, this.onTap});
  final VoidCallback? onTap;

  @override
  State<NotificationSummaryCardBlue> createState() => _NotificationSummaryCardBlueState();
}

class _NotificationSummaryCardBlueState extends State<NotificationSummaryCardBlue>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressCtl;

  @override
  void initState() {
    super.initState();
    _pressCtl = AnimationController(
      vsync: this,
      lowerBound: 0.0,
      upperBound: 0.06, // scale effect intensity
      duration: const Duration(milliseconds: 110),
    );
  }

  @override
  void dispose() {
    _pressCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Responsive sizing based on a 412w x 892h reference
    final w = MediaQuery.of(context).size.width;
    final baseW = 412.0;
    final scale = (w / baseW).clamp(0.82, 1.25);

    final cardW = 178.0 * scale;
    final cardH = 171.0 * scale;

    // Colors from the Figma spec you shared
    const bgBlue = Color(0xAD3251A3); // ~blue background with alpha
    const borderBlue = Color(0xFF678EE6);
    const titleBlue = Color(0xFF9AB5EF);
    const labelBlue = Color(0xFFB8CBF4);

    final uid = FirebaseAuth.instance.currentUser?.uid;

    // Listen to all posts authored by the current user
    final stream = uid == null
        ? const Stream<QuerySnapshot>.empty()
        : FirebaseFirestore.instance
            .collection('posts')
            .where('authorId', isEqualTo: uid)
            .snapshots();

    return GestureDetector(
      onTapDown: (_) => _pressCtl.forward(),
      onTapCancel: () => _pressCtl.reverse(),
      onTapUp: (_) {
        _pressCtl.reverse();
        widget.onTap?.call();
      },
      child: AnimatedBuilder(
        animation: _pressCtl,
        builder: (context, child) {
          final scaleVal = 1 - _pressCtl.value; // small bounce press
          return Transform.scale(
            scale: scaleVal,
            child: child,
          );
        },
        child: Container(
          width: cardW,
          height: cardH,
          decoration: ShapeDecoration(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Stack(
            children: [
              // Background card
              Positioned.fill(
                child: Container(
                  decoration: ShapeDecoration(
                    color: bgBlue,
                    shape: RoundedRectangleBorder(
                      side: const BorderSide(width: 1, color: borderBlue),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    shadows: const [
                      BoxShadow(
                        color: Color(0x3F000000),
                        blurRadius: 4,
                        offset: Offset(0, 4),
                      )
                    ],
                  ),
                ),
              ),

              // Bell icon (top-right)
              Positioned(
                right: 10 * scale,
                top: 10 * scale,
                child: Icon(
                  Icons.notifications_active_rounded,
                  color: borderBlue,
                  size: 24 * scale,
                ),
              ),

              // Texts stacked vertically
              Positioned.fill(
                child: StreamBuilder<QuerySnapshot>(
                  stream: stream,
                  builder: (context, snapshot) {
                    int count = 0;
                    if (snapshot.hasError) {
                      count = 0;
                    } else if (snapshot.hasData) {
                      for (final doc in snapshot.data!.docs) {
                        final data = doc.data() as Map<String, dynamic>;
                        if (data.containsKey('likeCount') && data['likeCount'] is num) {
                          count += (data['likeCount'] as num).toInt();
                        } else if (data['likedBy'] is List) {
                          count += (data['likedBy'] as List).length;
                        }
                      }
                    }

                    final countText = count > 9 ? '9+' : '$count';

                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // "Você tem"
                        Padding(
                          padding: EdgeInsets.only(top: 6 * scale),
                          child: Text(
                            'Você tem',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16 * scale,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w700,
                              height: 1.38,
                            ),
                          ),
                        ),

                        // Count
                        Padding(
                          padding: EdgeInsets.only(top: 6 * scale),
                          child: Text(
                            countText,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: borderBlue,
                              fontSize: 22 * scale,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                              height: 1.0,
                            ),
                          ),
                        ),

                        // "Curtidas"
                        Padding(
                          padding: EdgeInsets.only(top: 6 * scale),
                          child: Text(
                            'Curtidas',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: titleBlue,
                              fontSize: 16 * scale,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                              height: 1.38,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}