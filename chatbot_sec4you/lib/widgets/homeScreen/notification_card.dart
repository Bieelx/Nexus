import 'package:flutter/material.dart';

class NotificationCard extends StatelessWidget {
  final String count;
  const NotificationCard({Key? key, this.count = '0'}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFFA259FF);
    const darkCard = Color(0xFF393939);

    final w = MediaQuery.of(context).size.width;
    final cardWidth = w * 0.45;
    final cardHeight = cardWidth * 0.64;

    return Container(
      width: cardWidth,
      height: cardHeight,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: darkCard,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Você tem',
            style: const TextStyle(
              color: purple,
              fontSize: 14,
              fontFamily: 'JetBrainsMono',
              fontWeight: FontWeight.w400,
            ),
          ),

          // "9+"
          Text(
            count,
            style: const TextStyle(
              color: purple,
              fontSize: 28,
              fontFamily: 'JetBrainsMono',
              fontWeight: FontWeight.w400,
            ),
          ),

          // "Notificações"
          Text(
            'Notificações',
            style: const TextStyle(
              color: purple,
              fontSize: 14,
              fontFamily: 'JetBrainsMono',
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}