import 'package:flutter/material.dart';

class GroupCard extends StatelessWidget {
  final String title;
  final String description;
  final String lastMessageUser;
  final String lastMessageText;
  final VoidCallback onEnter;
  final IconData iconData; // Continua recebendo o IconData
  final Color iconBackgroundColor; // NOVO: Cor de fundo do ícone
  final int memberCount;
  final int postCount;

  const GroupCard({
    super.key,
    required this.title,
    required this.description,
    required this.lastMessageUser,
    required this.lastMessageText,
    required this.onEnter,
    required this.iconData,
    required this.iconBackgroundColor, // NOVO
    required this.memberCount,
    required this.postCount,
  });

  @override
  Widget build(BuildContext context) {
    const cardGradient = LinearGradient(
              begin: Alignment(0.08, 0.68),
              end: Alignment(0.59, 0.69),
      colors: [ Color(0x7F515767),  Color(0x7F515767)],
    );

    // Gradiente do botão "Entrar" (mantido o padrão roxo)
    const enterButtonGradient = LinearGradient(
      begin: Alignment(0.50, 0.00),
      end: Alignment(0.50, 1.00),
      colors: [Color(0xFFA259FF), Color(0xFF7C3AED)],
    );

    return Container(
      width: double.infinity,
      decoration: ShapeDecoration(
        gradient: cardGradient,
        shape: RoundedRectangleBorder(
          side: const BorderSide(width: 0.62, color: Color(0x19FFFEFE)),
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ícone (agora com `iconBackgroundColor` dinâmico)
              Container(
                width: 40,
                height: 40,
                decoration: ShapeDecoration(
                  color: iconBackgroundColor, // Usa a cor passada
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Icon(iconData, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w400,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.people_alt_outlined, color: Color(0xFF9CA3AF), size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '$memberCount',
                          style: const TextStyle(
                            color: Color(0xFF9CA3AF),
                            fontSize: 11,
                            fontFamily: 'Inter',
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Icon(Icons.chat_bubble_outline, color: Color(0xFF9CA3AF), size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '$postCount',
                          style: const TextStyle(
                            color: Color(0xFF9CA3AF),
                            fontSize: 11,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              _EnterButton(
                onTap: onEnter,
                gradient: enterButtonGradient, // Mantém o gradiente roxo padrão
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: const TextStyle(
              color: Color(0xFFB4B4B8),
              fontSize: 13,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w400,
              height: 1.62,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          const Divider(color: Color(0x19FFFEFE), thickness: 0.62),
          const SizedBox(height: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Última mensagem:',
                style: TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 11,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: 4),
              RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 13,
                    fontFamily: 'Inter',
                    height: 1.5,
                  ),
                  children: [
                    TextSpan(
                      text: '$lastMessageUser: ',
                      style: const TextStyle(color: Color(0xFFA259FF)),
                    ),
                    TextSpan(
                      text: lastMessageText,
                      style: const TextStyle(color: Color(0xFFD1D5DB)),
                    ),
                  ],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EnterButton extends StatelessWidget {
  final VoidCallback onTap;
  final Gradient gradient;
  const _EnterButton({required this.onTap, required this.gradient});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        width: 96,
        height: 40,
        decoration: ShapeDecoration(
          gradient: gradient,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        alignment: Alignment.center,
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Entrar',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w400,
              ),
            ),
            SizedBox(width: 4),
            Icon(Icons.arrow_forward_ios, color: Colors.white, size: 14),
          ],
        ),
      ),
    );
  }
}