import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:crypto/crypto.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import './widgets/leak_widget.dart';

class LeakCheckerScreen extends StatefulWidget {
  final Function(int, String) changeTab;

  const LeakCheckerScreen({super.key, required this.changeTab});

  @override
  State<LeakCheckerScreen> createState() => _LeakCheckerScreenState();
}

class _LeakCheckerScreenState extends State<LeakCheckerScreen> {
  final TextEditingController _dataController = TextEditingController();
  String selectedType = 'Email';
  String resultMessage = '';
  bool isLoading = false;

  Future<void> verifyData() async {
    final data = _dataController.text.trim();

    if (data.isEmpty) {
      showError('Digite algo para verificar.');
      return;
    }

    if (selectedType == 'Email') {
      if (!isValidEmail(data)) {
        showError('Formato de email inválido.');
        return;
      }
      await checkEmailLeak(data);
    } else if (selectedType == 'Senha') {
      if (data.length < 6) {
        showError('Senha muito curta. Pelo menos 6 caracteres.');
        return;
      }
      await checkPasswordLeak(data);
    } else if (selectedType == 'Telefone') {
      if (!isValidPhone(data)) {
        showError('Formato de telefone inválido. Ex: +5511999999999');
        return;
      }
      await checkPhoneLeak(data);
    } else if (selectedType == 'Site') {
      if (!isValidUrl(data)) {
        showError('Formato de site inválido. Ex: https://exemplo.com');
        return;
      }
      await checkMaliciousSite(data);
    }
  }

  bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  bool isValidPhone(String phone) {
    final phoneRegex = RegExp(r'^\+?\d{10,15}$');
    return phoneRegex.hasMatch(phone);
  }

  bool isValidUrl(String url) {
    final urlRegex = RegExp(
      r"^(https?:\/\/)?([\w\-]+\.)+[\w\-]+(\/[\w\-._~:/?#[\]@!$&'()*+,;=]*)?$",
      caseSensitive: false,
    );
    return urlRegex.hasMatch(url);
  }

  void showError(String message) {
    setState(() {
      resultMessage = '❌ $message';
    });
  }

  Future<void> checkPasswordLeak(String password) async {
    setState(() {
      isLoading = true;
      resultMessage = '';
    });

    final sha1Hash = sha1.convert(utf8.encode(password)).toString().toUpperCase();
    final prefix = sha1Hash.substring(0, 5);
    final suffix = sha1Hash.substring(5);

    final url = Uri.parse('https://api.pwnedpasswords.com/range/$prefix');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final hashes = response.body.split('\n');
      bool found = false;

      for (var line in hashes) {
        final parts = line.split(':');
        if (parts[0] == suffix) {
          found = true;
          setState(() {
            resultMessage = '⚠️ Sua senha foi encontrada em vazamentos (${parts[1]} vezes).';
          });
          break;
        }
      }

      if (!found) {
        setState(() {
          resultMessage = '✅ Sua senha NÃO foi encontrada em vazamentos!';
        });
      }
    } else {
      setState(() {
        resultMessage = '❌ Erro ao consultar a senha.';
      });
    }

    setState(() {
      isLoading = false;
    });

    if (resultMessage.contains('⚠️')) {
      showHelpPopup(resultMessage);
    }
  }

  Future<void> checkEmailLeak(String email) async {
    setState(() {
      isLoading = true;
      resultMessage = '';
    });

    // Simulação de vazamento de email
    if (email.endsWith('@test.com') || email.contains('leak')) {
      setState(() {
        resultMessage = '⚠️ O email $email foi encontrado em vazamentos!';
      });
    } else {
      setState(() {
        resultMessage = '✅ O email $email NÃO foi encontrado em vazamentos!';
      });
    }

    setState(() {
      isLoading = false;
    });

    if (resultMessage.contains('⚠️')) {
      showHelpPopup(resultMessage);
    }
  }

  Future<void> checkPhoneLeak(String phone) async {
    setState(() {
      isLoading = true;
      resultMessage = '';
    });
    await Future.delayed(const Duration(seconds: 1));
    if (phone.endsWith('9999')) {
      setState(() {
        resultMessage = '⚠️ O telefone $phone foi encontrado em vazamentos!';
      });
      showHelpPopup(resultMessage);
    } else {
      setState(() {
        resultMessage = '✅ O telefone $phone NÃO foi encontrado em vazamentos!';
      });
    }
    setState(() {
      isLoading = false;
    });
  }

  Future<void> checkMaliciousSite(String url) async {
    setState(() {
      isLoading = true;
      resultMessage = '';
    });

    final apiKey = dotenv.env['GOOGLE_SAFE_BROWSING_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      setState(() {
        resultMessage = '❌ Chave da API do Google não configurada.';
        isLoading = false;
      });
      return;
    }

    final safeBrowsingUrl = Uri.parse(
      'https://safebrowsing.googleapis.com/v4/threatMatches:find?key=$apiKey',
    );

    final body = jsonEncode({
      "client": {
        "clientId": "chatbot-sec4you",
        "clientVersion": "1.0"
      },
      "threatInfo": {
        "threatTypes": [
          "MALWARE",
          "SOCIAL_ENGINEERING",
          "UNWANTED_SOFTWARE",
          "POTENTIALLY_HARMFUL_APPLICATION"
        ],
        "platformTypes": ["ANY_PLATFORM"],
        "threatEntryTypes": ["URL"],
        "threatEntries": [
          {"url": url}
        ]
      }
    });

    try {
      final response = await http.post(
        safeBrowsingUrl,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['matches'] != null) {
          setState(() {
            resultMessage = '⚠️ O site $url é considerado malicioso!';
          });
          showHelpPopup(resultMessage);
        } else {
          setState(() {
            resultMessage = '✅ O site $url NÃO foi identificado como malicioso!';
          });
        }
      } else {
        setState(() {
          resultMessage = '❌ Erro ao consultar o site.';
        });
      }
    } catch (e) {
      setState(() {
        resultMessage = '❌ Erro ao consultar o site.';
      });
    }

    setState(() {
      isLoading = false;
    });
  }

  void showHelpPopup(String message) {
    final scaffold = ScaffoldMessenger.of(context);
    scaffold.showSnackBar(
      SnackBar(
        content: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                selectedType == 'Site'
                  ? 'Esse site parece suspeito! Deseja conversar com o assistente?'
                  : 'Vazamento Detectado! Deseja conversar com o assistente?',
                style: const TextStyle(color: Colors.white),
              ),
            ),
            TextButton(
              onPressed: () {
                scaffold.hideCurrentSnackBar();
                String autoMsg = selectedType == 'Email'
                    ? "Meu email vazou, o que posso fazer?"
                    : selectedType == 'Senha'
                        ? "Minha senha vazou, o que posso fazer?"
                        : selectedType == 'Telefone'
                            ? "Meu telefone vazou, o que posso fazer?"
                            : "Acessei um site suspeito, o que devo fazer?";
                widget.changeTab(1, autoMsg);
              },
              child: const Text('Sim', style: TextStyle(color: Colors.white)),
            ),
            TextButton(
              onPressed: () {
                scaffold.hideCurrentSnackBar();
              },
              child: const Text('Não', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF4b0082),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 30, right: 16, left: 80),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        duration: const Duration(seconds: 8),
      ),
    );
  }

@override
Widget build(BuildContext context) {
  final screenWidth = MediaQuery.of(context).size.width;
  final screenHeight = MediaQuery.of(context).size.height;

  // Proporcional ao design base
  final topSpacing = screenHeight * 0.093;     // 83/892
  final leftPadding = screenWidth * 0.039;     // 16/412

  return Scaffold(
    backgroundColor: const Color(0xFF0D0D0D),
    body: SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: topSpacing),
          Padding(
            padding: EdgeInsets.only(left: leftPadding),
            child: const Text(
              '<Vazamento./>',
              style: TextStyle(
                color: Color(0xFFA259FF),
                fontSize: 22,
                fontFamily: 'JetBrains Mono',
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          // Resto da tela:
          LeakVerificationCard(
            controller: _dataController,
            selectedType: selectedType,
            onDropdownChanged: (val) {
              setState(() {
                selectedType = val!;
                resultMessage = '';
              });
            },
            isLoading: isLoading,
            onVerify: verifyData,
            resultMessage: resultMessage,
          ),
        ],
      ),
    ),
  );
}
}