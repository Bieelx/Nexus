import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nexus_app/service/xp_service.dart';

class StreaksWidget extends StatefulWidget {
  const StreaksWidget({Key? key}) : super(key: key);

  @override
  _StreaksWidgetState createState() => _StreaksWidgetState();
}

class _StreaksWidgetState extends State<StreaksWidget> {
  int _streakCount = 0;
  DateTime? _lastCheckIn;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStreak();
  }

  Future<void> _loadStreak() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _loading = false;
      });
      return;
    }
    final doc = await FirebaseFirestore.instance.collection('streaks').doc(user.uid).get();
    if (doc.exists) {
      final data = doc.data()!;
      Timestamp? lastCheckInTimestamp = data['lastCheckIn'];
      DateTime? lastCheckIn;
      if (lastCheckInTimestamp != null) {
        lastCheckIn = lastCheckInTimestamp.toDate();
      }
      setState(() {
        _lastCheckIn = lastCheckIn;
        _streakCount = data['streakCount'] ?? 0;
        _loading = false;
      });
    } else {
      setState(() {
        _streakCount = 0;
        _lastCheckIn = null;
        _loading = false;
      });
    }
  }

  Future<void> _registerStreak() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (_lastCheckIn != null) {
      final lastCheckInDay = DateTime(_lastCheckIn!.year, _lastCheckIn!.month, _lastCheckIn!.day);
      if (lastCheckInDay == today) {
        // Already registered today, keep the streak count as is
        return;
      }
    }

    int newStreakCount = 1;
    if (_lastCheckIn != null) {
      final yesterday = today.subtract(const Duration(days: 1));
      final lastCheckInDay = DateTime(_lastCheckIn!.year, _lastCheckIn!.month, _lastCheckIn!.day);
      if (lastCheckInDay == yesterday) {
        newStreakCount = _streakCount + 1;
      } else if (lastCheckInDay.isBefore(yesterday)) {
        newStreakCount = 1;
      }
    }

    await FirebaseFirestore.instance.collection('streaks').doc(user.uid).set({
      'streakCount': newStreakCount,
      'lastCheckIn': Timestamp.fromDate(today),
    });

    await XpService().addXp(user.uid, 25);

    setState(() {
      _streakCount = newStreakCount;
      _lastCheckIn = today;
    });
  }

  bool get _isRegisteredToday {
    if (_lastCheckIn == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastCheckInDay = DateTime(_lastCheckIn!.year, _lastCheckIn!.month, _lastCheckIn!.day);
    return lastCheckInDay == today;
  }

  @override
  Widget build(BuildContext context) {
    final double containerWidth = 178;
    final double containerHeight = 171;
    final List<String> weekDayInitials = ['D', 'S', 'T', 'Q', 'Q', 'S', 'S'];

    if (_loading) {
      return Container(
        width: containerWidth,
        height: containerHeight,
        decoration: BoxDecoration(
          color: const Color(0xFF434958),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF72D08A)),
        ),
        alignment: Alignment.center,
        child: const CircularProgressIndicator(
          color: Color(0xFF72D08A),
        ),
      );
    }

    if (!_isRegisteredToday) {
      // Estado não registrado
      return Container(
        width: containerWidth,
        height: containerHeight,
        decoration: BoxDecoration(
          color: const Color(0xFF434958),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF72D08A)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Frequência',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              '$_streakCount Dia${_streakCount == 1 ? '' : 's'}',
              style: const TextStyle(
                color: Color(0xFF7B8295),
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(
              width: 99,
              height: 22,
              child: OutlinedButton(
                onPressed: () {
                  _registerStreak();
                },
                style: OutlinedButton.styleFrom(
                  backgroundColor: const Color(0xB24F8347),
                  side: const BorderSide(color: Color(0xFF73D18A)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: EdgeInsets.zero,
                ),
                child: const Center(
                  child: Text(
                    'Registrar frequência',
                    style: TextStyle(
                      color: Color(0xFF72D08A),
                      fontSize: 12,
                      fontWeight: FontWeight.normal,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      // Estado registrado
      return Container(
        width: containerWidth,
        height: containerHeight,
        decoration: BoxDecoration(
          color: const Color(0xB24F8347),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF72D08A)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Icon(
              Icons.local_fire_department,
              color: Color(0xFF72D08A),
              size: 32,
            ),
            const Text(
              'Frequência',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              '$_streakCount Dia${_streakCount == 1 ? '' : 's'}',
              style: const TextStyle(
                color: Color(0xFF43D660),
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(7, (index) {
                final now = DateTime.now();
                int todayIndex = now.weekday % 7; // Domingo = 0, Sábado = 6
                int activeDays = _streakCount;
                bool isActive = false;

                if (_lastCheckIn != null && activeDays > 0) {
                  int diff = todayIndex - index;
                  if (diff < 0) diff += 7;
                  isActive = diff < activeDays;
                }

                Color circleColor =
                    isActive ? const Color(0xFF73D18A) : const Color(0xFF6C7691);
                String dayInitial = weekDayInitials[index];
                return Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: circleColor,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    dayInitial,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 10,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      );
    }
  }
}
