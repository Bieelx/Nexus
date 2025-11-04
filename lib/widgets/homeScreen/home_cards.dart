import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../../service/xp_service.dart';

// ================================================================
// Widget 1: Cartão de Notificações
// ================================================================

class NotificationSummaryCard extends StatelessWidget {
  final VoidCallback? onTap;
  final double width;
  final double height;

  const NotificationSummaryCard({
    super.key, 
    this.onTap,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    const Color bgBlue = Color(0xAD3251A3);
    const Color borderBlue = Color(0xFF678EE6);
    const Color titleBlue = Color(0xFF9AB5EF);

    final String? uid = FirebaseAuth.instance.currentUser?.uid;
    final stream = uid == null
        ? Stream.value(0)
        : FirebaseFirestore.instance.collection('users').doc(uid).snapshots().map((doc) {
            return doc.data()?['unreadCount'] as int? ?? 0;
          });

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width, // Usa o tamanho calculado
        height: height, // Usa o tamanho calculado
        decoration: BoxDecoration(
          color: bgBlue,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderBlue),
        ),
        child: Stack(
          children: [
            Positioned(
              top: 12,
              left: 12,
              child: Icon(Icons.notifications_active_rounded, color: borderBlue, size: 24),
            ),
            Center(
              child: StreamBuilder<int>(
                stream: stream,
                builder: (context, snapshot) {
                  final count = snapshot.data ?? 0;
                  final countText = count > 9 ? '9+' : '$count';

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Você tem', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      Text(countText, style: TextStyle(color: borderBlue, fontSize: 22, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Text('Notificações', style: TextStyle(color: titleBlue, fontSize: 16, fontWeight: FontWeight.w600)),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ================================================================
// Widget 2: Cartão de Frequência (Streaks)
// ================================================================

class StreaksWidget extends StatefulWidget {
  final double width;
  final double height;
  
  const StreaksWidget({
    super.key,
    required this.width,
    required this.height,
  });

  @override
  State<StreaksWidget> createState() => _StreaksWidgetState();
}

class _StreaksWidgetState extends State<StreaksWidget> {
  late Stream<DocumentSnapshot> _streakStream;
  String? _uid;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('pt_BR');
    _uid = FirebaseAuth.instance.currentUser?.uid;
    _streakStream = _uid != null
        ? FirebaseFirestore.instance.collection('streaks').doc(_uid).snapshots()
        : const Stream.empty();
  }

  Future<void> _registerStreak(int currentStreak, DateTime? lastCheckIn) async {
    if (_uid == null) return;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    int newStreakCount = 1;
    if (lastCheckIn != null) {
      final yesterday = today.subtract(const Duration(days: 1));
      if (lastCheckIn == yesterday) newStreakCount = currentStreak + 1;
    }
    await FirebaseFirestore.instance.collection('streaks').doc(_uid).set({
      'streakCount': newStreakCount,
      'lastCheckIn': Timestamp.fromDate(today),
    });
    await XpService().addXp(_uid!, 25);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _streakStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(width: widget.width, height: widget.height, alignment: Alignment.center, child: const CircularProgressIndicator());
        }
        int streakCount = 0;
        DateTime? lastCheckIn;
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          streakCount = data['streakCount'] ?? 0;
          lastCheckIn = (data['lastCheckIn'] as Timestamp?)?.toDate();
        }
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final bool isRegisteredToday = lastCheckIn == today;

        return isRegisteredToday
            ? _buildRegisteredCard(streakCount, lastCheckIn)
            : _buildUnregisteredCard(streakCount, lastCheckIn);
      },
    );
  }

  Widget _buildUnregisteredCard(int streakCount, DateTime? lastCheckIn) {
    const Color bgColor = Color(0xFF434958);
    const Color borderColor = Color(0xFF72D08A);
    const Color buttonBgColor = Color(0xB24F8347);

    return Container(
      width: widget.width, // Usa o tamanho calculado
      height: widget.height, // Usa o tamanho calculado
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: borderColor)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          const Icon(Icons.local_fire_department_outlined, color: Colors.grey, size: 32),
          const Text('Frequência', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          Text('$streakCount Dia${streakCount == 1 ? '' : 's'}', style: const TextStyle(color: Color(0xFF7B8295), fontSize: 22, fontWeight: FontWeight.w600)),
          OutlinedButton(
            onPressed: () => _registerStreak(streakCount, lastCheckIn),
            style: OutlinedButton.styleFrom(
              backgroundColor: buttonBgColor, side: const BorderSide(color: borderColor),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            child: const Text('Registrar frequência', style: TextStyle(color: borderColor, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisteredCard(int streakCount, DateTime? lastCheckIn) {
    const Color bgColor = Color(0xB24F8347);
    const Color borderColor = Color(0xFF72D08A);
    const Color streakColor = Color(0xFF43D660);

    return Container(
      width: widget.width, // Usa o tamanho calculado
      height: widget.height, // Usa o tamanho calculado
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: borderColor)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          const Icon(Icons.local_fire_department, color: borderColor, size: 32),
          const Text('Frequência', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          Text('$streakCount Dia${streakCount == 1 ? '' : 's'}', style: const TextStyle(color: streakColor, fontSize: 22, fontWeight: FontWeight.w600)),
          _buildWeekDays(streakCount, lastCheckIn),
        ],
      ),
    );
  }

  Widget _buildWeekDays(int streakCount, DateTime? lastCheckIn) {
    final List<String> weekDayInitials = DateFormat.E('pt_BR').dateSymbols.SHORTWEEKDAYS.map((d) => d.toUpperCase()[0]).toList();
    final orderedWeekDays = [weekDayInitials[0], weekDayInitials[1], weekDayInitials[2], weekDayInitials[3], weekDayInitials[4], weekDayInitials[5], weekDayInitials[6]];
    final todayWeekday = DateTime.now().weekday % 7;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (index) {
        final int dayDifference = todayWeekday - index;
        final bool isActive = dayDifference >= 0 && dayDifference < streakCount;
        return Container(
          width: 18, height: 18,
          decoration: BoxDecoration(color: isActive ? const Color(0xFF73D18A) : const Color(0xFF6C7691), shape: BoxShape.circle),
          alignment: Alignment.center,
          child: Text(orderedWeekDays[index], style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
        );
      }),
    );
  }
}