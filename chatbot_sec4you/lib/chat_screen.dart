import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/theme/app_colors.dart';


class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, this.initialMessage});

  final String? initialMessage;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, String>> messages = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialMessage != null && widget.initialMessage!.isNotEmpty) {
      sendMessage(widget.initialMessage!);
    }
  }

  // Função para extrair o tom e limpar a mensagem
  Map<String, String> extractToneAndText(String aiText) {
    final toneRegExp = RegExp(r'\[TOM:\s*(.*?)\]', caseSensitive: false);
    final match = toneRegExp.firstMatch(aiText);
    String tone = 'neutral';
    String cleanText = aiText;
    if (match != null) {
      tone = match.group(1)?.toLowerCase() ?? 'neutral';
      cleanText = aiText.replaceFirst(toneRegExp, '').trim();
    }
    return {
      'tone': tone,
      'text': cleanText,
    };
  }

  // Função para escolher o avatar do bot
  String getBotAvatar(String tone) {
    switch (tone) {
      case 'feliz':
        return 'assets/Luiz-Feliz.png';
      case 'triste':
        return 'assets/Luiz-Triste.png';
      case 'bravo':
        return 'assets/Luiz-Bravo.png';
      case 'explicando':
        return 'assets/Luiz-Curioso.png';
      case 'neutro':
      default:
        return 'assets/Luiz-Feliz.png';
    }
  }

  // Função para montar o histórico de mensagens para a API
  List<Map<String, dynamic>> buildHistory(String newText) {
    // Prompt fixo para o assistente
    const String systemPrompt = """
    Você é Luiz, assistente virtual da Sec4You, especializado apenas em temas de **segurança da informação**. Responda **em português brasileiro**.

    📌 **Instruções gerais:**
    - Seja objetivo e amigável, mas direto.
    - Não inicie toda mensagem com saudações como "Olá", "Oi", "Tudo bem?". Apenas a interação inicial.
    - Responda usando frases curtas e simples.
    - Não escreva mais do que o necessário para ser claro.

    🎭 **Tom emocional:**
    - Analise a mensagem do usuário e indique o tom no formato [TOM: feliz, bravo, triste, explicando, neutro] antes da resposta.

    🚫 **Assuntos fora do contexto:**
    - Se o tema não for relacionado à **segurança da informação**, responda apenas:
      "Desculpe, não posso te ajudar com isso. Sobre o que de segurança você gostaria de saber?"
    - Se o tema for algo sensível ou perigoso, fora de segurança da informação responda apenas:
      "Desculpe, mas esse não é o tipo de assunto que você deve discutir aqui."
    """;

    List<Map<String, dynamic>> history = [
      {
        "role": "user",
        "parts": [
          {"text": systemPrompt}
        ]
      }
    ];

    for (var msg in messages.takeLast(6)) {
      history.add({
        "role": msg["sender"] == "user" ? "user" : "model",
        "parts": [
          {"text": msg["text"] ?? ""}
        ]
      });
    }

    // Adiciona a mensagem atual do usuário
    history.add({
      "role": "user",
      "parts": [
        {"text": newText}
      ]
    });
    return history;
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty || isLoading) return;

    setState(() {
      messages.add({"sender": "user", "text": text});
      isLoading = true;
    });

    final String apiKey = dotenv.env['API_KEY'] ?? '';
    final response = await http.post(
      Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$apiKey'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        "contents": buildHistory(text),
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final aiText = data['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? 'Sem resposta.';
      final result = extractToneAndText(aiText);
      setState(() {
        messages.add({
          "sender": "ai",
          "text": result['text'] ?? '',
          "tone": result['tone'] ?? 'neutral',
        });
      });
    } else {
      setState(() {
        messages.add({
          "sender": "ai",
          "text": "Erro ao se comunicar com o assistente. 😢",
          "tone": "neutro",
        });
      });
    }

    setState(() {
      isLoading = false;
      _controller.clear();
    });

    await Future.delayed(const Duration(milliseconds: 300));
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
    );
  }

Widget buildMessage(Map<String, String> msg) {
  // IA à esquerda, usuário à direita
  final isBot = (msg['sender'] ?? '') != 'user';
  final tone = (msg['tone'] ?? 'neutro');


  // largura máx. responsiva (~78% da tela)
  final maxBubbleWidth = MediaQuery.of(context).size.width * 0.78;


  final Widget avatar = CircleAvatar(
    radius: 20,
    backgroundColor: isBot ? Colors.transparent : const Color(0xFF678EE6),
    backgroundImage: isBot ? AssetImage(getBotAvatar(tone)) : null,
    child: isBot ? null : const Icon(Icons.person, color: Colors.white),
  );


  final Widget bubble = ConstrainedBox(
    constraints: BoxConstraints(maxWidth: maxBubbleWidth),
      child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: isBot
        ? BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment(0.08, 0.68),
              end: Alignment(0.59, 0.69),
              colors: [Color(0xFF6638B6), Color(0xFF634A9E)],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF6C52BB), width: 1),
          )
        : BoxDecoration(
            color: const Color(0xAD3251A3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF678EE6), width: 1),
          ),
    child: Text(
      msg['text'] ?? '',
      style: TextStyle(
        color: isBot ? const Color(0xFFAE85E5) : const Color(0xFF9AB5EF),
        fontSize: 12,
        fontFamily: 'Poppins',
        fontWeight: FontWeight.w600,
        height: 1.83,
      ),
    ),
      )
  );

  return Row(
    mainAxisAlignment: isBot ? MainAxisAlignment.start : MainAxisAlignment.end,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: isBot
        ? [avatar, const SizedBox(width: 12), bubble]
        : [bubble, const SizedBox(width: 12), avatar],
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        centerTitle: false,
        titleSpacing: 16, // 16px da borda esquerda
        iconTheme: const IconThemeData(color: AppColors.white),
        title: const Text(
          '<Chat Bot./>',
          style: TextStyle(
            color: AppColors.primaryPurple,
            fontSize: 22,
            fontFamily: 'JetBrainsMono',
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                controller: _scrollController,
                itemCount: messages.length,
                itemBuilder: (context, index) => buildMessage(messages[index]),
                separatorBuilder: (_, __) => const SizedBox(height: 40), // 40px entre bolhas
              ),
            ),
Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
    color: Colors.transparent,
    child: Row(
      children: [
        // Input pill (left)
        Expanded(
          child: Container(
            height: 43,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: ShapeDecoration(
              color: const Color(0xB2515767),
              shape: RoundedRectangleBorder(
                side: const BorderSide(width: 1, color: Color(0xFF7884C4)),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: TextField(
              controller: _controller,
              enabled: !isLoading,
              textAlignVertical: TextAlignVertical.bottom,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                height: 1.83,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: isLoading ? "Aguarde a resposta..." : "Digite aqui...",
                hintStyle: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  height: 1.83,
                ),
                isDense: true,
                contentPadding: const EdgeInsets.only(left: 4, right: 4, bottom: 10, top: 0),
              ),
              onSubmitted: (_) => sendMessage(_controller.text),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Send button (right)
        GestureDetector(
          onTap: isLoading ? null : () => sendMessage(_controller.text),
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
              boxShadow: const [
                BoxShadow(
                  color: Color(0x3F000000),
                  blurRadius: 4,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.send, color: Colors.white, size: 20),
          ),
        ),
      ],
    ),
  ),
          ],
        ),
      ),
    );
  }
}

// Extensão para pegar as últimas N mensagens
extension TakeLastExtension<E> on List<E> {
  Iterable<E> takeLast(int n) => skip(length - n < 0 ? 0 : length - n);
}

class _BubbleTailPainter extends CustomPainter {
  final Color color;
  final bool isLeft;
  const _BubbleTailPainter({required this.color, required this.isLeft});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path();
    if (isLeft) {
      // pequeno triângulo apontando para a esquerda
      path.moveTo(0, size.height);
      path.lineTo(size.width, size.height);
      path.lineTo(0, 0);
    } else {
      // pequeno triângulo apontando para a direita
      path.moveTo(size.width, size.height);
      path.lineTo(0, size.height);
      path.lineTo(size.width, 0);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}