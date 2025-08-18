import 'package:flutter/material.dart';

class GroupCard extends StatelessWidget {
  final String title;                // ex: "<Geral/>"
  final String description;          // ex: "Discussões, perguntas..."
  final String lastMessageUser;      // ex: "LabubuBobbieGoods"
  final String lastMessageText;      // ex: "Acho que deveríamos..."
  final List<Color> gradient;        // ex: [Color(0xFF6638B6), Color(0xFF634A9E)]
  final Color borderColor;           // ex: Color(0xFF6C52BB)
  final VoidCallback onEnter;

  const GroupCard({
    super.key,
    required this.title,
    required this.description,
    required this.lastMessageUser,
    required this.lastMessageText,
    required this.gradient,
    required this.borderColor,
    required this.onEnter,
  });

  @override
  Widget build(BuildContext context) {
    // Responsividade: escala relativa ao layout de referência (380px)
    final maxW = MediaQuery.of(context).size.width;
    final usableW = (maxW - 32).clamp(0, 380); // 16px de padding lateral
    final scale = usableW / 380.0;
    final cardH = 180.0 * scale;

    const titleSize = 20.0;
    const bodySize  = 12.0;

    return Container(
      width: usableW.toDouble(),
      height: cardH,
      decoration: ShapeDecoration(
        gradient: LinearGradient(
          begin: const Alignment(0.08, 0.68),
          end: const Alignment(0.59, 0.69),
          colors: gradient,
        ),
        shape: RoundedRectangleBorder(
          side: BorderSide(width: 1, color: borderColor),
          borderRadius: BorderRadius.circular(16 * scale),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(16 * scale),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Linha: Título + botão Entrar (alinhado à direita)
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: titleSize * scale,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.2,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(right: 16 * scale),
                  child: _EnterButton(scale: scale, onTap: onEnter),
                ),
              ],
            ),
            SizedBox(height: 11 * scale),
            // Descrição
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 277 * scale),
              child: Text(
                description,
                style: TextStyle(
                  color: const Color(0xFFD5C4F3),
                  fontSize: bodySize * scale,
                  fontWeight: FontWeight.w500,
                  height: 1.67,
                  letterSpacing: 0.12,
                ),
              ),
            ),
            SizedBox(height: 5 * scale),
            // "Última mensagem:"
            Text(
              'Última mensagem:',
              style: TextStyle(
                color: const Color(0xFFA5A3A7),
                fontSize: bodySize * scale,
                fontWeight: FontWeight.w400,
                height: 1.83,
              ),
            ),
            SizedBox(height: 5 * scale),
            // User + texto
            Expanded(
              child: SizedBox(
                width: double.infinity,
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '$lastMessageUser: ',
                        style: TextStyle(
                          color: const Color(0xFFA259FF),
                          fontSize: bodySize * scale,
                          fontWeight: FontWeight.w400,
                          height: 1.83,
                        ),
                      ),
                      TextSpan(
                        text: lastMessageText,
                        style: TextStyle(
                          color: const Color(0xFFFEF7FF),
                          fontSize: bodySize * scale,
                          fontWeight: FontWeight.w400,
                          height: 1.83,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EnterButton extends StatelessWidget {
  final double scale;
  final VoidCallback onTap;
  const _EnterButton({required this.scale, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final h = 28.0 * scale;
    return InkWell(
      borderRadius: BorderRadius.circular(12 * scale),
      onTap: onTap,
      child: Container(
        height: h,
        padding: EdgeInsets.symmetric(horizontal: 14 * scale),
        decoration: ShapeDecoration(
          gradient: const LinearGradient(
            begin: Alignment(0.00, 0.58),
            end: Alignment(1.00, 0.58),
            colors: [Color(0xFF9240FE), Color(0xFF8523F7)],
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12 * scale),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          'Entrar',
          style: TextStyle(
            color: const Color(0xFFFEF7FF),
            fontSize: 12 * scale,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}