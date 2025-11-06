import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../core/theme/app_colors.dart';
import '../service/voice_service.dart';

class ChatMessage {
  final String sender;
  final String text;
  final String? tone;
  ChatMessage({required this.sender, required this.text, this.tone});
}

class ChatService {
  final String _apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
  static const String _systemPrompt = """Seu nome é **Lua**, assistente virtual da **Nexus**, que atua como guia em todo o ecossistema do aplicativo.  

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
      Lua: `[TOM: neutro] Desculpe, não posso te ajudar com isso. Quer saber algo sobre segurança, comunidade ou notícias da Nexus?`  """; // (Seu prompt completo aqui)

  Future<Map<String, String>> getResponse(List<ChatMessage> messageHistory, String newText) async {
    if (_apiKey.isEmpty) return {'error': 'Chave da Gemini ausente.'};
    final history = _buildHistory(messageHistory, newText);
    try {
      final response = await http.post(
        Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({"system_instruction": {"parts": [{"text": _systemPrompt}]}, "contents": history, "generationConfig": {"temperature": 0.4}}),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final aiText = data['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? 'Sem resposta.';
        return _extractToneAndText(aiText);
      } else {
        return {'error': 'Erro na API: ${response.body}'};
      }
    } catch (e) {
      return {'error': 'Erro de conexão: $e'};
    }
  }

  Map<String, String> _extractToneAndText(String aiText) {
    final toneRegExp = RegExp(r'\[TOM:\s*(.*?)\]', caseSensitive: false);
    final match = toneRegExp.firstMatch(aiText);
    String tone = 'neutral';
    String cleanText = aiText;
    if (match != null) {
      tone = match.group(1)?.toLowerCase() ?? 'neutral';
      cleanText = aiText.replaceFirst(toneRegExp, '').trim();
    }
    return {'tone': tone, 'text': cleanText};
  }

  List<Map<String, dynamic>> _buildHistory(List<ChatMessage> messages, String newText) {
    final lastMessages = messages.skip(max(0, messages.length - 6));
    final List<Map<String, dynamic>> history = [];
    for (var msg in lastMessages) {
      history.add({"role": msg.sender == "user" ? "user" : "model", "parts": [{"text": msg.text}]});
    }
    history.add({"role": "user", "parts": [{"text": newText}]});
    return history;
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, this.initialMessage});
  final String? initialMessage;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

// MUDANÇA: Adicionado o `SingleTickerProviderStateMixin` para controlar a animação
class _ChatScreenState extends State<ChatScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatService _chatService = ChatService();
  final VoiceService _voiceService = VoiceService();
  
  List<ChatMessage> messages = [];
  bool isLoading = false;

  // NOVAS VARIÁVEIS PARA A ANIMAÇÃO E O OVERLAY
  late AnimationController _animationController;
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    if (widget.initialMessage != null && widget.initialMessage!.isNotEmpty) {
      sendMessage(widget.initialMessage!);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _voiceService.dispose();
    _animationController.dispose();
    // Garante que o overlay seja removido se a tela for destruída
    _removeOverlay();
    super.dispose();
  }

  // MUDANÇA: Lógica de animação e conversa de demonstração
  Future<void> _startDemoConversation() async {
    if (isLoading) return;

    // 1. Cria e insere o overlay na tela
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context)?.insert(_overlayEntry!);
    
    // 2. Inicia a animação de "subida" do gradiente
    _animationController.forward();

    const String userMessage = "Oi, tudo bem? Quem é você?";
    await sendMessage(userMessage, shouldSpeak: true);

    // 3. Aguarda um tempo (simulando a fala) e depois remove a animação
    Future.delayed(const Duration(seconds: 4), () {
      _animationController.reverse().then((_) {
        _removeOverlay();
      });
    });
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  // NOVO: Widget que constrói a animação do gradiente
  OverlayEntry _createOverlayEntry() {
    return OverlayEntry(
      builder: (context) => IgnorePointer( // Permite cliques através da animação
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.5), // Começa de baixo
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut)),
          child: FadeTransition(
            opacity: _animationController,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    AppColors.primaryPurple.withOpacity(0.6),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 1.0],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> sendMessage(String text, {bool shouldSpeak = false}) async {
    if (text.trim().isEmpty || isLoading) return;
    setState(() {
      messages.add(ChatMessage(sender: "user", text: text));
      isLoading = true;
      _scrollToBottom();
    });
    _controller.clear();

    final result = await _chatService.getResponse(messages, text);
    ChatMessage responseMessage;
    if (result.containsKey('error')) {
      responseMessage = ChatMessage(sender: "ai", text: result['error']!, tone: "triste");
    } else {
      responseMessage = ChatMessage(sender: "ai", text: result['text']!, tone: result['tone']);
      if (shouldSpeak) {
        await _voiceService.speak(result['text'] ?? '');
      }
    }
    
    if (mounted) {
      setState(() {
        messages.add(responseMessage);
        isLoading = false;
        _scrollToBottom();
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  String getBotAvatar(String? tone) => 'assets/Lua/Lua.png';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(preferredSize: const Size.fromHeight(112), child: _buildAppBar(context)),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                controller: _scrollController,
                itemCount: messages.length,
                itemBuilder: (context, index) => _buildMessage(messages[index]),
                separatorBuilder: (_, __) => const SizedBox(height: 40),
              ),
            ),
            _buildTextInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    final topPad = (67.0 - MediaQuery.of(context).padding.top).clamp(0.0, 200.0);
    return Padding(
      padding: EdgeInsets.only(top: topPad, left: 16, right: 16),
      child: SizedBox(height: 68,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const CircleAvatar(radius: 20, backgroundImage: AssetImage('assets/Lua/Lua.png')),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text('Converse com a', style: TextStyle(color: AppColors.white, fontSize: 16, fontFamily: 'Poppins', fontWeight: FontWeight.w600, height: 1.2)),
                  SizedBox(height: 2),
                  Text('<Lua/>', style: TextStyle(color: AppColors.primaryPurple, fontSize: 16, fontFamily: 'JetBrainsMono', fontWeight: FontWeight.w600, height: 1.2)),
                ],
              ),
            ),
            Container(
              width: 43, height: 43,
              decoration: BoxDecoration(color: const Color(0xFF6638B6), borderRadius: BorderRadius.circular(12)),
              child: IconButton(
                icon: const Icon(Icons.phone, color: Colors.white), 
                onPressed: isLoading ? null : _startDemoConversation,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMessage(ChatMessage msg) {
    final isBot = msg.sender != 'user';
    final maxBubbleWidth = MediaQuery.of(context).size.width * 0.78;
    final avatar = CircleAvatar(radius: 20, backgroundColor: isBot ? Colors.transparent : const Color(0xFF678EE6), backgroundImage: isBot ? AssetImage(getBotAvatar(msg.tone)) : null, child: isBot ? null : const Icon(Icons.person, color: Colors.white));
    final bubble = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      constraints: BoxConstraints(maxWidth: maxBubbleWidth),
      decoration: BoxDecoration(
        gradient: isBot ? const LinearGradient(colors: [Color(0xFF6638B6), Color(0xFF634A9E)]) : null,
        color: isBot ? null : const Color(0xAD3251A3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isBot ? const Color(0xFF6C52BB) : const Color(0xFF678EE6)),
      ),
      child: Text(msg.text, style: TextStyle(color: isBot ? const Color(0xFFAE85E5) : const Color(0xFF9AB5EF), fontSize: 12, fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
    );
    return Row(mainAxisAlignment: isBot ? MainAxisAlignment.start : MainAxisAlignment.end, crossAxisAlignment: CrossAxisAlignment.start, children: isBot ? [avatar, const SizedBox(width: 12), Expanded(child: bubble)] : [Expanded(child: bubble), const SizedBox(width: 12), avatar]);
  }

  Widget _buildTextInput() {
    return Container(padding: const EdgeInsets.fromLTRB(16, 8, 16, 12), child: Row(children: [Expanded(child: Container(height: 43, padding: const EdgeInsets.symmetric(horizontal: 12), decoration: ShapeDecoration(color: const Color(0xB2515767), shape: RoundedRectangleBorder(side: const BorderSide(color: Color(0xFF7884C4)), borderRadius: BorderRadius.circular(16))), child: TextField(controller: _controller, enabled: !isLoading, style: const TextStyle(color: Colors.white, fontSize: 12), decoration: InputDecoration(border: InputBorder.none, hintText: isLoading ? "Aguarde..." : "Digite aqui...", hintStyle: const TextStyle(color: Colors.white70)), onSubmitted: (text) => sendMessage(text, shouldSpeak: false)))), const SizedBox(width: 8), GestureDetector(onTap: isLoading ? null : () => sendMessage(_controller.text, shouldSpeak: false), child: Container(width: 43, height: 43, decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xB2AE85E5), Color(0xFF8447D6), Color(0xFF572698)]), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.send, color: Colors.white, size: 20)))]));
  }
}