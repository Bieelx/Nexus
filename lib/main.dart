import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'service/auth_service.dart';
import 'Screens/login_page.dart';
import 'Screens/home_screen.dart';
import 'Screens/chat_screen.dart'; // ChatScreenRestoredMessages está aqui
import 'Screens/course_selection.dart';
import 'Screens/leak_check_screen_enhanced.dart';
import 'Screens/boards_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'core/firebase_options.dart';
import 'widgets/navbar.dart';
import 'widgets/gradient_background.dart';
import 'Screens/Subscreens/lesson_screen.dart';
import '/service/gemini_key_service.dart';

Future<void> main() async {
  // Garante que o Flutter e os plugins estejam prontos
  WidgetsFlutterBinding.ensureInitialized();

  // Carrega variáveis de ambiente
  await dotenv.load();

  // Inicialização segura do Firebase
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print("✅ Firebase inicializado com sucesso.");
    } else {
      Firebase.app();
      print("⚠️ Firebase já estava inicializado, reutilizando instância existente.");
    }
  } catch (e) {
    // Em alguns casos (hot restart no Android), o Firebase já está ativo
    print("⚠️ Firebase já inicializado ou erro ignorável: $e");
  }

  // Habilita persistência offline do Firestore
  FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: true);
  await GeminiKeyService.instance.init();
  // Inicializa o app
  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthService(),
      child: const Sec4YouApp(),
    ),
  );
}

class Sec4YouApp extends StatelessWidget {
  const Sec4YouApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sec4You',
      theme: ThemeData(
        fontFamily: 'Poppins',
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.transparent,
        appBarTheme: const AppBarTheme(
          iconTheme: IconThemeData(color: Color(0xFFFAF9F6)),
          titleTextStyle: TextStyle(
            color: Color(0xFFFAF9F6),
            fontWeight: FontWeight.bold,
            fontSize: 20,
            fontFamily: 'Poppins',
          ),
        ),
      ),
      builder: (context, child) {
        return GradientBackground(
          child: child ?? const SizedBox.shrink(),
        );
      },
      // ###################### CORREÇÃO AQUI ######################
      onGenerateRoute: (settings) {
        if (settings.name == '/pdf-viewer' || settings.name == '/lesson') {
          return MaterialPageRoute(
            fullscreenDialog: true,
            // 1. O builder agora chama a função estática
            //    que já sabe como lidar com os argumentos.
            builder: LessonScreen.fromRouteArgs,
            
            // 2. Você DEVE passar os 'settings' aqui.
            //    É assim que 'LessonScreen.fromRouteArgs'
            //    consegue ler os argumentos da rota.
            settings: settings,
          );
        }
        return null; // Deixa outras rotas serem tratadas normalmente
      },
      // ###########################################################
      home: const AuthCheck(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// GlobalKey para acessar o MainNavigation de qualquer lugar
final GlobalKey<_MainNavigationState> mainNavigationKey = GlobalKey<_MainNavigationState>();

class AuthCheck extends StatelessWidget {
  const AuthCheck({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, auth, child) {
        if (auth.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return auth.usuario != null ? MainNavigation(key: mainNavigationKey) : LoginPage();
      },
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;
  String _autoMessage = '';
  int _chatKey = 0; // Para forçar rebuild do chat

  // A lista de telas é definida uma vez para melhor performance
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      HomeScreen(),
      CourseSelectionScreen(onBackToHome: () => _onTabTapped(0)),
      LeakCheckerScreenEnhanced(changeTab: _openChatWithAutoMessage),
      const BoardsScreen(),
      ChatScreen(key: ValueKey(_chatKey), initialMessage: _autoMessage),
    ];
  }

  // Método público para restaurar conversa (chamado via GlobalKey)
  void restoreConversation(List<ChatMessage> messages) {
    setState(() {
      _chatKey++; // Incrementa para forçar rebuild
      _selectedIndex = 4; // Muda para tab do chat
      _screens[4] = ChatScreen(
        key: ValueKey(_chatKey),
        initialMessage: _autoMessage,
        restoredMessages: messages,
      );
    });
    debugPrint('🔄 Restaurando conversa com ${messages.length} mensagens');
  }

  void _onTabTapped(int index) {
    if (index == _selectedIndex) return;
    setState(() {
      if (index != 4) _autoMessage = '';
      _selectedIndex = index;
    });
  }

  void _openChatWithAutoMessage(int _, String autoMsg) {
    setState(() {
      _autoMessage = autoMsg;
      _selectedIndex = 4; // Índice da tela de Chat
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      bottomNavigationBar: CustomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onTabTapped,
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
    );
  }
}