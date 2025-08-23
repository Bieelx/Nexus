import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../core/theme/app_colors.dart';


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
        return 'assets/Lua/Lua.png';
      case 'triste':
        return 'assets/Luiz-Triste.png';
      case 'bravo':
        return 'assets/Luiz-Bravo.png';
      case 'explicando':
        return 'assets/Luiz-Curioso.png';
      case 'neutro':
      default:
        return 'assets/Lua/Lua.png';
    }
  }

  // Monta o histórico de mensagens (sem prompt de sistema; ele vai no system_instruction)
  List<Map<String, dynamic>> buildHistory(String newText) {
    // últimas N mensagens
    final last = messages.takeLast(6);
    final List<Map<String, dynamic>> history = [];

    for (var msg in last) {
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

    final String apiKey = dotenv.env['GEMINI_API_KEY'] ?? dotenv.env['API_KEY'] ?? '';
    if (apiKey.isEmpty) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chave da Gemini ausente. Configure GEMINI_API_KEY no .env.')),
        );
      }
      return;
    }

    const String systemPrompt = """
      Seu nome é **Lua**, assistente virtual da **Nexus**, que atua como guia em todo o ecossistema do aplicativo.  

      🔹 **Escopo de atuação:**  
      1. **Segurança da informação** – explique conceitos, dê dicas de boas práticas, oriente sobre riscos digitais.  
      2. **Vazamentos de dados** – oriente sobre verificações, riscos e medidas a serem tomadas.  
      3. **Comunidade Nexus (fórum e grupos)** – ajude os usuários a interagir, responda dúvidas simples, incentive boas práticas de convivência.  
      4. **Notícias de cibersegurança** – quando solicitado, busque notícias atuais por meio da API integrada (se disponível).  

      📌 **Instruções gerais:**  
      - Seja **objetiva, amigável e direta**.  
      - Não inicie todas as mensagens com saudações como "Olá" ou "Oi". Use isso **apenas na primeira interação**.  
      - Responda em **português brasileiro**.  
      - Use **frases curtas e simples**.  
      - Não escreva mais do que o necessário para ficar clara.  

      🎭 **Tom emocional:**  
      - Sempre inicie a resposta com o tom detectado no formato:  
        `[TOM: feliz]`, `[TOM: bravo]`, `[TOM: triste]`, `[TOM: explicando]`, `[TOM: neutro]`.  
      - O tom deve refletir a emoção principal da mensagem do usuário.  

      🚫 **Assuntos fora do contexto:**  
      - Se o tema não for relacionado à **segurança, comunidade, vazamentos ou notícias da área**, responda apenas:  
        "Desculpe, não posso te ajudar com isso. Quer saber algo sobre segurança, comunidade ou notícias da Nexus?"  
      - Se o tema for **sensível, ilegal ou perigoso**, responda apenas:  
        "Desculpe, mas esse não é o tipo de assunto que você deve discutir aqui."  

      ✨ **Exemplos de comportamento esperado:**  

      Usuário: *“Como saber se meu e-mail foi vazado?”*  
      Lua: `[TOM: explicando] Você pode usar a verificação da Nexus. Digite seu e-mail na aba de vazamentos e veja se ele aparece em bases comprometidas.`  

      Usuário: *“Quais as últimas notícias sobre ataques de ransomware?”*  
      Lua: `[TOM: explicando] Encontrei estas notícias recentes sobre ransomware: ...` (puxa da API).  

      Usuário: *“Qual sua comida favorita?”*  
      Lua: `[TOM: neutro] Desculpe, não posso te ajudar com isso. Quer saber algo sobre segurança, comunidade ou notícias da Nexus?`  
    """;

    final response = await http.post(
      Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$apiKey'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        "system_instruction": {
          "parts": [
            {"text": systemPrompt}
          ]
        },
        "contents": buildHistory(text),
        "generationConfig": {
          "temperature": 0.4
        }
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
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(112), // altura máxima aproximada (ajustada dinamicamente abaixo)
        child: Builder(
          builder: (context) {
            final media = MediaQuery.of(context);
            final statusBar = media.padding.top; // altura do status bar (varia por device)
            const desiredTop = 67.0;             // distância alvo a partir do topo da tela
            const leftPad = 16.0;                // distância alvo da borda esquerda

            final topPad = (desiredTop - statusBar).clamp(0.0, 200.0); // garante não-negativo

            return Container(
              color: Colors.transparent,
              padding: EdgeInsets.only(top: topPad, left: leftPad, right: 16),
              // altura exata = offset superior + altura do conteúdo (aprox. 68)
              child: SizedBox(
                height: 68,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.transparent,
                      backgroundImage: AssetImage('assets/Lua/Lua.png'),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text(
                          'Converse com a',
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: 18,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                            height: 1.1,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          '<Lua/>',
                          style: TextStyle(
                            color: AppColors.primaryPurple,
                            fontSize: 18,
                            fontFamily: 'JetBrainsMono',
                            fontWeight: FontWeight.w600,
                            height: 1.1,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
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
            child: Align(
  alignment: Alignment.centerLeft,
  child: ConstrainedBox(
    constraints: const BoxConstraints(minHeight: 0),
    child: TextField(
      controller: _controller,
      enabled: !isLoading,
      textInputAction: TextInputAction.send,
      minLines: 1,
      maxLines: 1,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontFamily: 'Poppins',
        fontWeight: FontWeight.w600,
        height: 1.3,
      ),
      decoration: InputDecoration(
        border: InputBorder.none,
        isCollapsed: true,
        isDense: true,
        contentPadding: EdgeInsets.zero,
        hintText: isLoading ? "Aguarde a resposta..." : "Digite aqui...",
        hintStyle: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w600,
          height: 1.3,
        ),
      ),
      onSubmitted: (_) => sendMessage(_controller.text),
    ),
  ),
)
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