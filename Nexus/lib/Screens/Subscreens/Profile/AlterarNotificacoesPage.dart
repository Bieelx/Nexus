import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

const kAccent = Color(0xFFA259FF); // Cor de destaque
const kBg = Color(0xFF121212); // Fundo escuro
const kText = Color(0xFFFAF9F6); // Texto branco
const kTextFieldBg = Color(0xFF333333); // Fundo dos campos de texto
const kTextFieldBorder = Color(0xFF555555); // Cor da borda dos campos de texto

class AlterarNotificacoesPage extends StatefulWidget {
  const AlterarNotificacoesPage({super.key});

  @override
  _AlterarNotificacoesPageState createState() =>
      _AlterarNotificacoesPageState();
}

class _AlterarNotificacoesPageState extends State<AlterarNotificacoesPage> {
  bool _isMessagesEnabled = true;
  bool _isProfileUpdatesEnabled = true;
  bool _isAlertsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadNotificationSettings();
  }

  // Função para carregar as configurações de notificações do usuário
  Future<void> _loadNotificationSettings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    if (userDoc.exists) {
      setState(() {
        _isMessagesEnabled = userDoc['isMessagesEnabled'] ?? true;
        _isProfileUpdatesEnabled = userDoc['isProfileUpdatesEnabled'] ?? true;
        _isAlertsEnabled = userDoc['isAlertsEnabled'] ?? true;
      });
    }
  }

  // Função para salvar as configurações de notificações
  Future<void> _saveNotificationSettings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'isMessagesEnabled': _isMessagesEnabled,
        'isProfileUpdatesEnabled': _isProfileUpdatesEnabled,
        'isAlertsEnabled': _isAlertsEnabled,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Configurações de notificações atualizadas!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao atualizar configurações de notificações: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Notificações',
          style: TextStyle(color: kText),
        ),
        backgroundColor: kAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // Título
            const Text(
              'Configurações de Notificações',
              style: TextStyle(
                color: kText,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // Notificação de Mensagens
            SwitchListTile(
              title: const Text(
                'Notificar sobre novas mensagens',
                style: TextStyle(color: kText),
              ),
              value: _isMessagesEnabled,
              onChanged: (bool value) {
                setState(() {
                  _isMessagesEnabled = value;
                });
              },
              activeColor: kAccent,
              activeTrackColor: kAccent.withOpacity(0.6),
              inactiveThumbColor: Colors.grey,
              inactiveTrackColor: Colors.grey.withOpacity(0.4),
            ),

            // Notificação de Atualizações de Perfil
            SwitchListTile(
              title: const Text(
                'Notificar sobre atualizações no perfil',
                style: TextStyle(color: kText),
              ),
              value: _isProfileUpdatesEnabled,
              onChanged: (bool value) {
                setState(() {
                  _isProfileUpdatesEnabled = value;
                });
              },
              activeColor: kAccent,
              activeTrackColor: kAccent.withOpacity(0.6),
              inactiveThumbColor: Colors.grey,
              inactiveTrackColor: Colors.grey.withOpacity(0.4),
            ),

            // Notificação de Alertas
            SwitchListTile(
              title: const Text(
                'Notificar sobre alertas importantes',
                style: TextStyle(color: kText),
              ),
              value: _isAlertsEnabled,
              onChanged: (bool value) {
                setState(() {
                  _isAlertsEnabled = value;
                });
              },
              activeColor: kAccent,
              activeTrackColor: kAccent.withOpacity(0.6),
              inactiveThumbColor: Colors.grey,
              inactiveTrackColor: Colors.grey.withOpacity(0.4),
            ),

            const SizedBox(height: 24),

            // Botão para salvar as alterações
            ElevatedButton(
              onPressed: _saveNotificationSettings,
              child: const Text('Salvar Alterações'),
              style: ElevatedButton.styleFrom(
                foregroundColor: kText,
                backgroundColor: kAccent,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
