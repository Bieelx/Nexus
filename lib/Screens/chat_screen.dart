import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/theme/app_colors.dart';
import '../service/voice_service.dart';
import '../main.dart'; // Para acessar mainNavigationKey

// Classe estática para passar mensagens restauradas (não usado mais, mas mantido para compatibilidade)
class ChatScreenRestoredMessages {
  static List<ChatMessage>? messages;
}

class ChatMessage {
  final String sender;
  final String text;
  final String? tone;
  final DateTime timestamp;
  ChatMessage({
    required this.sender,
    required this.text,
    this.tone,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'sender': sender,
      'text': text,
      'tone': tone,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      sender: map['sender'] ?? 'user',
      text: map['text'] ?? '',
      tone: map['tone'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] ?? 0),
    );
  }
}

class ChatService {
  final String _apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';

  // Método para analisar golpe com imagem
  Future<Map<String, String>> analyzeScam({
    required String channel,
    required String sender,
    required bool hasUrgency,
    required String request,
    required bool hasLinks,
    String? description,
    File? image,
    Uint8List? imageBytes, // Para web
  }) async {
    if (_apiKey.isEmpty) return {'error': 'Chave da Gemini ausente.'};

    String prompt = """
Analise esta possível tentativa de golpe com base nas informações:

📱 Canal: $channel
👤 Remetente: $sender
⚡ Urgência: ${hasUrgency ? 'Sim' : 'Não'}
💰 Solicitação: $request
🔗 Links suspeitos: ${hasLinks ? 'Sim' : 'Não'}
${description != null && description.isNotEmpty ? '📝 Descrição: $description' : ''}

Por favor, forneça uma análise estruturada seguindo EXATAMENTE este formato:

[TOM: explicando]

🚨 ANÁLISE DE GOLPE

📊 Nível de Risco: [BAIXO/MÉDIO/ALTO/CRÍTICO] ([0-100]%)

🎭 Tipo identificado: [Nome do tipo de golpe]

📋 Análise Detalhada:
[Sua análise aqui, explicando os sinais identificados]

✅ O que fazer:
• [Primeira recomendação]
• [Segunda recomendação]
• [Terceira recomendação]

Seja OBJETIVA, CLARA e use PORTUGUÊS BRASILEIRO.
""";

    try {
      Map<String, dynamic> requestBody;

      // Verifica se tem imagem (mobile ou web)
      final bool hasImage = image != null || imageBytes != null;

      if (hasImage) {
        // Análise com imagem
        final Uint8List bytes;
        if (imageBytes != null) {
          bytes = imageBytes;
        } else {
          bytes = await image!.readAsBytes();
        }
        final base64Image = base64Encode(bytes);

        requestBody = {
          "system_instruction": {
            "parts": [{"text": _systemPrompt}]
          },
          "contents": [
            {
              "parts": [
                {"text": prompt},
                {
                  "inline_data": {
                    "mime_type": "image/jpeg",
                    "data": base64Image
                  }
                }
              ]
            }
          ],
          "generationConfig": {"temperature": 0.3}
        };
      } else {
        // Análise sem imagem
        requestBody = {
          "system_instruction": {
            "parts": [{"text": _systemPrompt}]
          },
          "contents": [
            {
              "parts": [{"text": prompt}]
            }
          ],
          "generationConfig": {"temperature": 0.3}
        };
      }

      final response = await http.post(
        Uri.parse(
            'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final aiText = data['candidates']?[0]?['content']?['parts']?[0]['text'] ?? 'Sem resposta.';
        return _extractToneAndText(aiText);
      } else {
        return {'error': 'Erro na API: ${response.body}'};
      }
    } catch (e) {
      return {'error': 'Erro de conexão: $e'};
    }
  }

  static const String _systemPrompt =
      """Seu nome é **Lua**, assistente virtual da **Nexus**, que atua como guia em todo o ecossistema do aplicativo.  

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

  Future<Map<String, String>> getResponse(
      List<ChatMessage> messageHistory, String newText) async {
    if (_apiKey.isEmpty) return {'error': 'Chave da Gemini ausente.'};
    final history = _buildHistory(messageHistory, newText);
    try {
      final response = await http.post(
        Uri.parse(
            'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          "system_instruction": {
            "parts": [
              {"text": _systemPrompt}
            ]
          },
          "contents": history,
          "generationConfig": {"temperature": 0.4}
        }),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final aiText = data['candidates']?[0]?['content']?['parts']?[0]
                ?['text'] ??
            'Sem resposta.';
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

  List<Map<String, dynamic>> _buildHistory(
      List<ChatMessage> messages, String newText) {
    final lastMessages = messages.skip(max(0, messages.length - 6));
    final List<Map<String, dynamic>> history = [];
    for (var msg in lastMessages) {
      history.add({
        "role": msg.sender == "user" ? "user" : "model",
        "parts": [
          {"text": msg.text}
        ]
      });
    }
    history.add({
      "role": "user",
      "parts": [
        {"text": newText}
      ]
    });
    return history;
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, this.initialMessage, this.restoredMessages});
  final String? initialMessage;
  final List<ChatMessage>? restoredMessages;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

// MUDANÇA: Adicionado o `SingleTickerProviderStateMixin` para controlar a animação
class _ChatScreenState extends State<ChatScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatService _chatService = ChatService();
  final VoiceService _voiceService = VoiceService();

  List<ChatMessage> messages = [];
  bool isLoading = false;
  bool _hasUnsavedChanges = false;

  // NOVAS VARIÁVEIS PARA A ANIMAÇÃO E O OVERLAY
  late AnimationController _animationController;
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // Adiciona observer de lifecycle
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    // Restaura mensagens se fornecidas via parâmetro
    if (widget.restoredMessages != null && widget.restoredMessages!.isNotEmpty) {
      messages = List.from(widget.restoredMessages!);
      _hasUnsavedChanges = true;
      debugPrint('✅ ${messages.length} mensagens restauradas no chat!');
    }

    if (widget.initialMessage != null && widget.initialMessage!.isNotEmpty) {
      sendMessage(widget.initialMessage!);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Salva quando o app vai para background ou perde foco
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      if (_hasUnsavedChanges && messages.isNotEmpty) {
        _saveConversation();
        setState(() => _hasUnsavedChanges = false);
      }
    }
  }

  @override
  void deactivate() {
    // Salva quando a tela é removida da árvore de widgets
    if (_hasUnsavedChanges && messages.isNotEmpty) {
      _saveConversation();
      setState(() => _hasUnsavedChanges = false);
    }
    super.deactivate();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // Remove observer
    // Salva a conversa automaticamente ao sair
    if (_hasUnsavedChanges && messages.isNotEmpty) {
      _saveConversation();
    }
    _controller.dispose();
    _scrollController.dispose();
    _voiceService.dispose();
    _animationController.dispose();
    _removeOverlay();
    super.dispose();
  }

  Future<void> _saveConversation() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || messages.isEmpty) return;

    try {
      // Gera título baseado na primeira mensagem do usuário
      String title = 'Conversa com Lua';
      final firstUserMessage = messages.firstWhere(
        (msg) => msg.sender == 'user',
        orElse: () => ChatMessage(sender: 'user', text: 'Nova conversa'),
      );

      if (firstUserMessage.text.length > 50) {
        title = '${firstUserMessage.text.substring(0, 47)}...';
      } else {
        title = firstUserMessage.text;
      }

      // Verifica se tem análise de golpe
      final hasScamAnalysis = messages.any((msg) =>
        msg.text.contains('ANÁLISE DE GOLPE') ||
        msg.text.contains('Nível de Risco')
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('chatConversations')
          .add({
        'title': title,
        'createdAt': FieldValue.serverTimestamp(),
        'lastUpdate': FieldValue.serverTimestamp(),
        'hasScamAnalysis': hasScamAnalysis,
        'messages': messages.map((msg) => msg.toMap()).toList(),
      });

      // Limpa as mensagens após salvar
      if (mounted) {
        setState(() {
          messages.clear();
          _hasUnsavedChanges = false;
        });
      }

      debugPrint('✅ Conversa salva com sucesso!');
    } catch (e) {
      debugPrint('❌ Erro ao salvar conversa: $e');
    }
  }

  // MUDANÇA: Lógica de animação e conversa de demonstração
  Future<void> _startDemoConversation() async {
    if (isLoading) return;

    // 1. Cria e insere o overlay na tela
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);

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
      builder: (context) => IgnorePointer(
        // Permite cliques através da animação
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.5), // Começa de baixo
            end: Offset.zero,
          ).animate(CurvedAnimation(
              parent: _animationController, curve: Curves.easeOut)),
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
      _hasUnsavedChanges = true; // Marca que tem mudanças não salvas
      _scrollToBottom();
    });
    _controller.clear();

    final result = await _chatService.getResponse(messages, text);
    ChatMessage responseMessage;
    if (result.containsKey('error')) {
      responseMessage =
          ChatMessage(sender: "ai", text: result['error']!, tone: "triste");
    } else {
      responseMessage = ChatMessage(
          sender: "ai", text: result['text']!, tone: result['tone']);
      if (shouldSpeak) {
        await _voiceService.speak(result['text'] ?? '');
      }
    }

    if (mounted) {
      setState(() {
        messages.add(responseMessage);
        isLoading = false;
        _hasUnsavedChanges = true; // Marca que tem mudanças não salvas
        _scrollToBottom();
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(_scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  String getBotAvatar(String? tone) => 'assets/Lua/Lua.png';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
          preferredSize: const Size.fromHeight(112),
          child: _buildAppBar(context)),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: messages.isEmpty
                  ? _buildEmptyState()
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      controller: _scrollController,
                      itemCount: messages.length,
                      itemBuilder: (context, index) =>
                          _buildMessage(messages[index]),
                      separatorBuilder: (_, __) => const SizedBox(height: 40),
                    ),
            ),
            if (messages.isNotEmpty) _buildSaveButton(),
            _buildTextInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    final topPad =
        (67.0 - MediaQuery.of(context).padding.top).clamp(0.0, 200.0);
    return Padding(
      padding: EdgeInsets.only(top: topPad, left: 16, right: 16),
      child: SizedBox(
        height: 68,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const CircleAvatar(
                radius: 20, backgroundImage: AssetImage('assets/Lua/Lua.png')),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text('Converse com a',
                      style: TextStyle(
                          color: AppColors.white,
                          fontSize: 16,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                          height: 1.2)),
                  SizedBox(height: 2),
                  Text('<Lua/>',
                      style: TextStyle(
                          color: AppColors.primaryPurple,
                          fontSize: 16,
                          fontFamily: 'JetBrainsMono',
                          fontWeight: FontWeight.w600,
                          height: 1.2)),
                ],
              ),
            ),
            Container(
              width: 43,
              height: 43,
              decoration: BoxDecoration(
                  color: const Color(0xFF6638B6),
                  borderRadius: BorderRadius.circular(12)),
              child: IconButton(
                icon: const Icon(Icons.history, color: Colors.white),
                onPressed: () => _openHistoryScreen(),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 43,
              height: 43,
              decoration: BoxDecoration(
                  color: const Color(0xFF6638B6),
                  borderRadius: BorderRadius.circular(12)),
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
    final avatar = CircleAvatar(
        radius: 20,
        backgroundColor: isBot ? Colors.transparent : const Color(0xFF678EE6),
        backgroundImage: isBot ? AssetImage(getBotAvatar(msg.tone)) : null,
        child: isBot ? null : const Icon(Icons.person, color: Colors.white));
    final bubble = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      constraints: BoxConstraints(maxWidth: maxBubbleWidth),
      decoration: BoxDecoration(
        gradient: isBot
            ? const LinearGradient(
                colors: [Color(0xFF6638B6), Color(0xFF634A9E)])
            : null,
        color: isBot ? null : const Color(0xAD3251A3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isBot ? const Color(0xFF6C52BB) : const Color(0xFF678EE6)),
      ),
      child: Text(msg.text,
          style: TextStyle(
              color: isBot ? const Color(0xFFAE85E5) : const Color(0xFF9AB5EF),
              fontSize: 12,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600)),
    );
    return Row(
        mainAxisAlignment:
            isBot ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: isBot
            ? [avatar, const SizedBox(width: 12), Expanded(child: bubble)]
            : [Expanded(child: bubble), const SizedBox(width: 12), avatar]);
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const SizedBox(height: 32),
          // Card especial de verificação de golpes
          _buildFraudCheckCard(),
          const SizedBox(height: 24),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Perguntas sugeridas:',
              style: TextStyle(
                color: Color(0xFFAE85E5),
                fontSize: 16,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Cards de sugestões
          _buildSuggestionCard(
            icon: Icons.security,
            title: 'Como criar senha forte?',
            prompt: 'Como criar uma senha forte e segura?',
          ),
          const SizedBox(height: 12),
          _buildSuggestionCard(
            icon: Icons.email,
            title: 'Como saber se fui vazado?',
            prompt: 'Como posso verificar se meus dados foram vazados?',
          ),
          const SizedBox(height: 12),
          _buildSuggestionCard(
            icon: Icons.smartphone,
            title: 'Dicas de segurança no celular',
            prompt: 'Quais são as melhores práticas de segurança para smartphone?',
          ),
          const SizedBox(height: 12),
          _buildSuggestionCard(
            icon: Icons.wifi,
            title: 'Wi-Fi público é seguro?',
            prompt: 'É seguro usar Wi-Fi público? Como me proteger?',
          ),
        ],
      ),
    );
  }

  void _openHistoryScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ChatHistoryScreen(),
      ),
    );
  }

  void _openScamAnalysisSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ScamAnalysisSheet(
        onSubmit: (result) async {
          // Envia os dados coletados para a IA
          setState(() => isLoading = true);

          final aiResult = await _chatService.analyzeScam(
            channel: result['channel'],
            sender: result['sender'],
            hasUrgency: result['hasUrgency'],
            request: result['request'],
            hasLinks: result['hasLinks'],
            description: result['description'],
            image: result['image'],
            imageBytes: result['imageBytes'], // Para web
          );

          if (mounted) {
            ChatMessage responseMessage;
            if (aiResult.containsKey('error')) {
              responseMessage = ChatMessage(
                sender: "ai",
                text: aiResult['error']!,
                tone: "triste",
              );
            } else {
              responseMessage = ChatMessage(
                sender: "ai",
                text: aiResult['text']!,
                tone: aiResult['tone'],
              );
            }

            setState(() {
              messages.add(responseMessage);
              isLoading = false;
              _scrollToBottom();
            });
          }
        },
      ),
    );
  }

  Widget _buildFraudCheckCard() {
    return InkWell(
      onTap: isLoading ? null : _openScamAnalysisSheet,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFD17374), Color(0xFFFF6B35)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFF8B60), width: 2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF6B35).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Verificar Golpe/Fraude',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Recebeu algo suspeito? Vou te ajudar!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionCard({
    required IconData icon,
    required String title,
    required String prompt,
  }) {
    return InkWell(
      onTap: isLoading ? null : () => sendMessage(prompt),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0x7F515767),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xB27884C4)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryPurple.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: const Color(0xFFAE85E5),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Color(0xFFC6C5C3),
                  fontSize: 14,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Color(0xFF7884C4),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF9644FF), Color(0xFF6638B6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryPurple.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            await _saveConversation();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: const [
                      Icon(Icons.check_circle, color: Colors.white),
                      SizedBox(width: 12),
                      Text(
                        'Conversa salva no histórico!',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: const Color(0xFF43D660),
                  duration: const Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.save_rounded, color: Colors.white, size: 22),
                SizedBox(width: 12),
                Text(
                  'Salvar Conversa',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextInput() {
    return Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Row(children: [
          Expanded(
              child: Container(
                  height: 43,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: ShapeDecoration(
                      color: const Color(0xB2515767),
                      shape: RoundedRectangleBorder(
                          side: const BorderSide(color: Color(0xFF7884C4)),
                          borderRadius: BorderRadius.circular(16))),
                  child: TextField(
                      controller: _controller,
                      enabled: !isLoading,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                      decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: isLoading ? "Aguarde..." : "Digite aqui...",
                          hintStyle: const TextStyle(color: Colors.white70)),
                      onSubmitted: (text) =>
                          sendMessage(text, shouldSpeak: false)))),
          const SizedBox(width: 8),
          GestureDetector(
              onTap: isLoading
                  ? null
                  : () => sendMessage(_controller.text, shouldSpeak: false),
              child: Container(
                  width: 43,
                  height: 43,
                  decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [
                        Color(0xB2AE85E5),
                        Color(0xFF8447D6),
                        Color(0xFF572698)
                      ]),
                      borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.send, color: Colors.white, size: 20)))
        ]));
  }
}

// ============================================================================
// BOTTOM SHEET DE ANÁLISE DE GOLPE
// ============================================================================

class ScamAnalysisSheet extends StatefulWidget {
  final Function(Map<String, dynamic>) onSubmit;

  const ScamAnalysisSheet({Key? key, required this.onSubmit}) : super(key: key);

  @override
  State<ScamAnalysisSheet> createState() => _ScamAnalysisSheetState();
}

class _ScamAnalysisSheetState extends State<ScamAnalysisSheet> {
  String _channel = '';
  String _sender = '';
  bool _hasUrgency = false;
  String _request = '';
  bool _hasLinks = false;
  String _description = '';
  File? _image;
  Uint8List? _imageBytes; // Para web
  final _descriptionController = TextEditingController();
  final _imagePicker = ImagePicker();

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      if (kIsWeb) {
        // Para web, lê os bytes
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _imageBytes = bytes;
          _image = null;
        });
      } else {
        // Para mobile/desktop
        setState(() {
          _image = File(pickedFile.path);
          _imageBytes = null;
        });
      }
    }
  }

  void _submit() {
    if (_channel.isEmpty || _sender.isEmpty || _request.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, preencha todos os campos obrigatórios'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    widget.onSubmit({
      'channel': _channel,
      'sender': _sender,
      'hasUrgency': _hasUrgency,
      'request': _request,
      'hasLinks': _hasLinks,
      'description': _descriptionController.text,
      'image': _image,
      'imageBytes': _imageBytes, // Para web
    });

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1B202E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Título
              const Text(
                '🚨 Análise de Golpe',
                style: TextStyle(
                  color: Color(0xFFD0B7F2),
                  fontSize: 24,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Responda as perguntas para uma análise precisa',
                style: TextStyle(
                  color: Color(0xFFAE85E5),
                  fontSize: 14,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 24),

              // 1. Canal
              _buildLabel('📱 Por onde recebeu?'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildChip('WhatsApp', _channel == 'WhatsApp', () => setState(() => _channel = 'WhatsApp')),
                  _buildChip('SMS', _channel == 'SMS', () => setState(() => _channel = 'SMS')),
                  _buildChip('Email', _channel == 'Email', () => setState(() => _channel = 'Email')),
                  _buildChip('Ligação', _channel == 'Ligação', () => setState(() => _channel = 'Ligação')),
                  _buildChip('Rede Social', _channel == 'Rede Social', () => setState(() => _channel = 'Rede Social')),
                ],
              ),
              const SizedBox(height: 20),

              // 2. Remetente
              _buildLabel('👤 Quem enviou?'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildChip('Desconhecido', _sender == 'Desconhecido', () => setState(() => _sender = 'Desconhecido')),
                  _buildChip('Empresa', _sender == 'Empresa', () => setState(() => _sender = 'Empresa')),
                  _buildChip('Contato', _sender == 'Contato', () => setState(() => _sender = 'Contato')),
                  _buildChip('Anônimo', _sender == 'Anônimo', () => setState(() => _sender = 'Anônimo')),
                ],
              ),
              const SizedBox(height: 20),

              // 3. Urgência
              _buildLabel('⚡ Pediu ação imediata?'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildChip('Sim', _hasUrgency == true, () => setState(() => _hasUrgency = true)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildChip('Não', _hasUrgency == false, () => setState(() => _hasUrgency = false)),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 4. Solicitação
              _buildLabel('💰 O que pediram?'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildChip('Dados pessoais', _request == 'Dados pessoais', () => setState(() => _request = 'Dados pessoais')),
                  _buildChip('Dinheiro/PIX', _request == 'Dinheiro/PIX', () => setState(() => _request = 'Dinheiro/PIX')),
                  _buildChip('Clicar em link', _request == 'Clicar em link', () => setState(() => _request = 'Clicar em link')),
                  _buildChip('Instalar algo', _request == 'Instalar algo', () => setState(() => _request = 'Instalar algo')),
                  _buildChip('Confirmação', _request == 'Confirmação', () => setState(() => _request = 'Confirmação')),
                ],
              ),
              const SizedBox(height: 20),

              // 5. Links
              _buildLabel('🔗 Tem links suspeitos?'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildChip('Sim', _hasLinks == true, () => setState(() => _hasLinks = true)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildChip('Não', _hasLinks == false, () => setState(() => _hasLinks = false)),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 6. Upload de imagem
              _buildLabel('📸 Adicionar print (opcional)'),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickImage,
                child: Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: const Color(0x7F515767),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xB27884C4)),
                  ),
                  child: (_image == null && _imageBytes == null)
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.add_photo_alternate, color: Color(0xFFAE85E5), size: 48),
                            SizedBox(height: 8),
                            Text(
                              'Toque para adicionar imagem',
                              style: TextStyle(color: Color(0xFFAE85E5), fontSize: 14, fontFamily: 'Poppins'),
                            ),
                          ],
                        )
                      : Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: kIsWeb && _imageBytes != null
                                  ? Image.memory(_imageBytes!, width: double.infinity, height: 120, fit: BoxFit.cover)
                                  : _image != null
                                      ? Image.file(_image!, width: double.infinity, height: 120, fit: BoxFit.cover)
                                      : const SizedBox(),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: GestureDetector(
                                onTap: () => setState(() {
                                  _image = null;
                                  _imageBytes = null;
                                }),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close, color: Colors.white, size: 20),
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 20),

              // 7. Descrição
              _buildLabel('📝 Descrição adicional (opcional)'),
              const SizedBox(height: 8),
              TextField(
                controller: _descriptionController,
                maxLines: 4,
                maxLength: 500,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Cole a mensagem ou descreva o que aconteceu...',
                  hintStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: const Color(0x7F515767),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xB27884C4)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xB27884C4)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primaryPurple, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Botão de analisar
              ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B35),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Analisar Mensagem',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFFAE85E5),
        fontSize: 16,
        fontFamily: 'Poppins',
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildChip(String label, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryPurple : const Color(0x7F515767),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primaryPurple : const Color(0xB27884C4),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFFAE85E5),
            fontSize: 14,
            fontFamily: 'Poppins',
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// TELA DE HISTÓRICO DE CONVERSAS
// ============================================================================

class ChatHistoryScreen extends StatelessWidget {
  const ChatHistoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Histórico'),
          backgroundColor: const Color(0xFF1B202E),
        ),
        body: const Center(
          child: Text('Você precisa estar logado', style: TextStyle(color: Colors.white)),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico de Conversas'),
        backgroundColor: const Color(0xFF1B202E),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('chatConversations')
            .orderBy('lastUpdate', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.history, size: 80, color: Color(0xFF7884C4)),
                  SizedBox(height: 16),
                  Text(
                    'Nenhuma conversa salva ainda',
                    style: TextStyle(
                      color: Color(0xFFAE85E5),
                      fontSize: 18,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final title = data['title'] ?? 'Conversa sem título';
              final hasScamAnalysis = data['hasScamAnalysis'] ?? false;
              final timestamp = data['lastUpdate'] as Timestamp?;

              return Card(
                color: const Color(0xFF2B3242),
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Color(0xFF6C52BB)),
                ),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: hasScamAnalysis
                          ? const Color(0xFFFF6B35).withOpacity(0.2)
                          : AppColors.primaryPurple.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      hasScamAnalysis ? Icons.warning_amber_rounded : Icons.chat,
                      color: hasScamAnalysis ? const Color(0xFFFF6B35) : AppColors.primaryPurple,
                      size: 24,
                    ),
                  ),
                  title: Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    timestamp != null ? _formatDate(timestamp.toDate()) : '',
                    style: const TextStyle(
                      color: Color(0xFF7884C4),
                      fontSize: 12,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  trailing: PopupMenuButton(
                    icon: const Icon(Icons.more_vert, color: Colors.white),
                    color: const Color(0xFF2B3242),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red, size: 20),
                            SizedBox(width: 8),
                            Text('Deletar', style: TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      if (value == 'delete') {
                        doc.reference.delete();
                      }
                    },
                  ),
                  onTap: () {
                    // Abre tela de visualização da conversa
                    final messages = (data['messages'] as List?)
                        ?.map((m) => ChatMessage.fromMap(m as Map<String, dynamic>))
                        .toList() ?? [];

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ConversationViewScreen(
                          title: title,
                          messages: messages,
                          hasScamAnalysis: hasScamAnalysis,
                          conversationId: doc.id,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Hoje às ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'Ontem';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} dias atrás';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

// ============================================================================
// TELA DE VISUALIZAÇÃO DE CONVERSA
// ============================================================================

class ConversationViewScreen extends StatelessWidget {
  final String title;
  final List<ChatMessage> messages;
  final bool hasScamAnalysis;
  final String conversationId;

  const ConversationViewScreen({
    Key? key,
    required this.title,
    required this.messages,
    required this.hasScamAnalysis,
    required this.conversationId,
  }) : super(key: key);

  String _getBotAvatar(String? tone) => 'assets/Lua/Lua.png';

  Widget _buildMessage(BuildContext context, ChatMessage msg) {
    final isBot = msg.sender != 'user';
    final maxBubbleWidth = MediaQuery.of(context).size.width * 0.78;

    final avatar = CircleAvatar(
      radius: 20,
      backgroundColor: isBot ? Colors.transparent : const Color(0xFF678EE6),
      backgroundImage: isBot ? AssetImage(_getBotAvatar(msg.tone)) : null,
      child: isBot ? null : const Icon(Icons.person, color: Colors.white),
    );

    final bubble = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      constraints: BoxConstraints(maxWidth: maxBubbleWidth),
      decoration: BoxDecoration(
        gradient: isBot
            ? const LinearGradient(
                colors: [Color(0xFF6638B6), Color(0xFF634A9E)])
            : null,
        color: isBot ? null : const Color(0xAD3251A3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isBot ? const Color(0xFF6C52BB) : const Color(0xFF678EE6)),
      ),
      child: Text(
        msg.text,
        style: TextStyle(
          color: isBot ? const Color(0xFFAE85E5) : const Color(0xFF9AB5EF),
          fontSize: 12,
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w600,
        ),
      ),
    );

    return Row(
      mainAxisAlignment: isBot ? MainAxisAlignment.start : MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: isBot
          ? [avatar, const SizedBox(width: 12), Expanded(child: bubble)]
          : [Expanded(child: bubble), const SizedBox(width: 12), avatar],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Conversa Salva',
              style: const TextStyle(
                fontSize: 14,
                fontFamily: 'Poppins',
                color: Color(0xFFAE85E5),
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1B202E),
        actions: [
          PopupMenuButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            color: const Color(0xFF2B3242),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'share',
                child: Row(
                  children: [
                    Icon(Icons.share, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text('Compartilhar', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red, size: 20),
                    SizedBox(width: 8),
                    Text('Deletar', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ],
            onSelected: (value) async {
              if (value == 'delete') {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: const Color(0xFF2B3242),
                    title: const Text('Deletar conversa?', style: TextStyle(color: Colors.white)),
                    content: const Text(
                      'Esta ação não pode ser desfeita.',
                      style: TextStyle(color: Color(0xFFAE85E5)),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancelar'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                        child: const Text('Deletar'),
                      ),
                    ],
                  ),
                );

                if (confirm == true && context.mounted) {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user != null) {
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid)
                        .collection('chatConversations')
                        .doc(conversationId)
                        .delete();

                    if (context.mounted) {
                      Navigator.pop(context); // Volta pro histórico
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Conversa deletada'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }
              } else if (value == 'share') {
                // Exporta como texto
                String export = 'Conversa com Lua - $title\n\n';
                for (var msg in messages) {
                  export += '${msg.sender == 'user' ? 'Você' : 'Lua'}: ${msg.text}\n\n';
                }

                // Aqui você pode implementar share nativo ou copiar para clipboard
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Função de compartilhar em desenvolvimento'),
                    backgroundColor: AppColors.primaryPurple,
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Badge de análise de golpe (se aplicável)
          if (hasScamAnalysis)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFD17374), Color(0xFFFF6B35)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: const [
                  Icon(Icons.warning_amber_rounded, color: Colors.white, size: 24),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Esta conversa contém uma análise de golpe',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Mensagens
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: messages.length,
              itemBuilder: (context, index) => _buildMessage(context, messages[index]),
              separatorBuilder: (_, __) => const SizedBox(height: 40),
            ),
          ),
        ],
      ),
      // Botão flutuante de continuar conversa
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Fecha todas as telas e volta pra MainNavigation
          Navigator.popUntil(context, (route) => route.isFirst);

          // Usa o GlobalKey para restaurar mensagens no MainNavigation
          Future.delayed(const Duration(milliseconds: 100), () {
            if (mainNavigationKey.currentState != null) {
              mainNavigationKey.currentState!.restoreConversation(messages);
              debugPrint('✅ Conversa restaurada via GlobalKey');
            } else {
              debugPrint('❌ Erro: mainNavigationKey.currentState é null');
            }
          });
        },
        backgroundColor: AppColors.primaryPurple,
        icon: const Icon(Icons.play_arrow, color: Colors.white),
        label: const Text(
          'Continuar Conversa',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
