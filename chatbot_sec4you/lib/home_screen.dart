import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'security_alerts_screen_real.dart';
import 'widgets/mini_map_widget.dart';
import 'service/user_location_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}



class _HomeScreenState extends State<HomeScreen> {
  String? firstName;

  @override
  void initState() {
    super.initState();
    _loadFirstNameFromFirestore();
    _updateUserLocation();
  }
  
  Future<void> _updateUserLocation() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await UserLocationService.updateUserLocation(user.uid);
    }
  }

  Future<void> _loadFirstNameFromFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .get();
      if (doc.exists && doc.data()?['nome'] != null) {
        setState(() {
          firstName = doc.data()!['nome'];
        });
      } else {
        setState(() {
          firstName = 'Usuário';
        });
      }
    } else {
      setState(() {
        firstName = 'Usuário';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF9F45FF);
    const bg = Color(0xFF0D0D0D);
    const darkCard = Color(0xFF1A1A1A);

    return Scaffold(
      backgroundColor: bg,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: firstName == null
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      const Icon(Icons.play_arrow, color: purple),
                      const SizedBox(width: 8),
                      Text(
                        'Bem-vindo de volta, $firstName.',
                        style: const TextStyle(color: purple, fontSize: 18),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // CARD DO CURSO
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: darkCard,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text(
                                    'Continuar curso?',
                                    style: TextStyle(
                                      color: purple,
                                      fontSize: 18,
                                      fontFamily: 'JetBrainsMono',
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Fire Wall\nMódulo 1 - atividade 5',
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.local_fire_department,
                              color: purple,
                              size: 48,
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            const Icon(Icons.play_arrow, color: purple),
                            const SizedBox(width: 12),
                            Expanded(
                              child: SizedBox(
                                height: 10,
                                child: LinearProgressIndicator(
                                  value: 0.5,
                                  backgroundColor: const Color.fromARGB(255,231,230,230,),
                                  valueColor: AlwaysStoppedAnimation<Color>(purple),
                                  borderRadius: const BorderRadius.all(Radius.circular(10)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // CARDS DE NOTIFICAÇÕES E ALERTAS
                  Row(
                    children: [
                      Expanded(
                        child: CardInfo(
                          title: 'Você tem',
                          value: '9+',
                          subtitle: 'Notificações',
                          color: purple,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CardInfo(
                          title: 'Você tem',
                          value: '1',
                          subtitle: 'Alerta de segurança',
                          color: purple,
                          onTap: () {
                            print('🔥 CARD CLICADO! Iniciando navegação...'); 
                            try {
                              print('Tentando navegar para SecurityAlertsScreenReal...');
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (BuildContext context) {
                                    print('Construindo SecurityAlertsScreenReal...');
                                    return SecurityAlertsScreenReal();
                                  },
                                ),
                              ).then((value) {
                                print('Navegação completada, valor retornado: $value');
                              });
                            } catch (e, stackTrace) {
                              print('❌ ERRO na navegação: $e');
                              print('StackTrace: $stackTrace');
                              
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Erro ao abrir alertas: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  MiniMapWidget(),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        print('✅ BOTÃO DE TESTE FUNCIONANDO!');
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => SecurityAlertsScreenReal(),
                          ),
                        );
                      },
                      icon: Icon(Icons.security),
                      label: Text('🔧 TESTE: Abrir Alertas de Segurança'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: purple,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
      ),
    );
  }
}

// COMPONENTE REUTILIZÁVEL PARA OS CARDS DE INFO - VERSÃO FUNCIONAL PERMANENTE
class CardInfo extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;

  const CardInfo({
    super.key,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    print('🏗️ Construindo CardInfo - subtitle: $subtitle, onTap: ${onTap != null}');
    
    // Se tem onTap, retorna um botão clicável
    if (onTap != null) {
      print('✅ Criando card CLICÁVEL para: $subtitle');
      return SizedBox(
        height: 120,
        child: ElevatedButton(
          onPressed: () {
            print('🚀 CARD CLICÁVEL ACIONADO: $subtitle');
            onTap!();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1A1A1A),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: color.withOpacity(0.8), width: 3),
            ),
            padding: EdgeInsets.all(12),
            elevation: 8,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(title, style: const TextStyle(color: Colors.white)),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(subtitle, style: const TextStyle(color: Colors.white70)),
                  const SizedBox(width: 4),
                  Icon(Icons.touch_app, color: color, size: 18),
                ],
              ),
            ],
          ),
        ),
      );
    } else {
      // Card normal sem clique
      print('📦 Criando card NORMAL para: $subtitle');
      return Container(
        height: 120,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(title, style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(subtitle, style: const TextStyle(color: Colors.white70)),
          ],
        ),
      );
    }
  }
}
