import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'leak_check_screen.dart';

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
    bool isUser = msg['sender'] == "user";
    String? tone = msg['tone'] ?? 'neutral';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (isUser)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: CircleAvatar(
                backgroundColor: const Color(0xFF1A1A1A),
                child: const Icon(Icons.person, color: Color(0xFFFAF9F6)),
              ),
            ),
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isUser ? const Color(0xFF1A1A1A) : const Color(0xFF232323),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: isUser ? const Radius.circular(0) : const Radius.circular(18),
                  bottomRight: isUser ? const Radius.circular(18) : const Radius.circular(0),
                ),
              ),
              child: Text(
                msg['text'] ?? '',
                style: const TextStyle(color: Color(0xFFFAF9F6), fontSize: 16),
              ),
            ),
          ),
          if (!isUser)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: CircleAvatar(
                backgroundColor: const Color(0xFF232323),
                backgroundImage: AssetImage(getBotAvatar(tone)),
                radius: 20,
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        title: const Text(
          "<Chat Bot./>",
          style: TextStyle(
            color: Color(0xFFFAF9F6),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF1A1A1A),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFFFAF9F6)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                itemCount: messages.length,
                itemBuilder: (context, index) => buildMessage(messages[index]),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(10),
              color: const Color(0xFF0D0D0D),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      enabled: !isLoading,
                      style: const TextStyle(color: Color(0xFFFAF9F6)),
                      decoration: InputDecoration(
                        hintText: isLoading ? "Aguarde a resposta..." : "Digite sua mensagem...",
                        hintStyle: const TextStyle(color: Colors.grey),
                        filled: true,
                        fillColor: const Color(0xFF1A1A1A),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onSubmitted: (_) => sendMessage(_controller.text),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: isLoading ? null : () => sendMessage(_controller.text),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7F2AB1),
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(12),
                    ),
                    child: const Icon(Icons.send, color: Color(0xFFFAF9F6)),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
      bottomNavigationBar: Container(
        color: const Color(0xFF1A1A1A),
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: const Text(
          'Desenvolvido por Gabriel Gramacho, Mikael Palmeira, Gabriel Araujo, Gustavo Teodoro e Kauã Granata • 2025',
          style: TextStyle(
            color: Color(0xFFFAF9F6),
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

// Extensão para pegar as últimas N mensagens
extension TakeLastExtension<E> on List<E> {
  Iterable<E> takeLast(int n) => skip(length - n < 0 ? 0 : length - n);
}