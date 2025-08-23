import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'service/auth_service.dart';

import 'Screens/login_page.dart';
import 'Screens/home_screen.dart';
import 'Screens/chat_screen.dart';
import 'Screens/leak_check_screen.dart';
import 'Screens/boards_screen.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';

import 'navbar.dart'; 
import 'widgets/gradient_background.dart';

class AuthCheck extends StatelessWidget {
  const AuthCheck({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);

    if (auth.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return auth.usuario != null ? const MainNavigation() : const LoginPage();
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
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
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          selectedItemColor: Color(0xFF7F2AB1),
          unselectedItemColor: Color(0xFFFAF9F6),
          type: BottomNavigationBarType.fixed,
        ),
      ),

      // ⬇️ aqui embrulhamos TODAS as rotas com o gradiente
      builder: (context, child) {
        return GradientBackground(
          child: child ?? const SizedBox.shrink(),
        );
      },

      home: const AuthCheck(),
      debugShowCheckedModeBanner: false,
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

  void _onTabTapped(int index) async {
      setState(() {
        _selectedIndex = index;
        _autoMessage = '';
      });
  }

  void _changeTab(int index, String autoMsg) {
    setState(() {
      _selectedIndex = index;
      _autoMessage = autoMsg;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(),
      ChatScreen(initialMessage: _autoMessage),
      LeakCheckerScreen(changeTab: _changeTab),
      BoardsScreen(),
      ChatScreen(initialMessage: _autoMessage),
    ];

    return Scaffold(
      // permite que o conteúdo "passe por trás" da navbar flutuante
      extendBody: true,
      body: Stack(
        children: [
          // Conteúdo principal com padding inferior para não ficar escondido
          Positioned.fill(
            child: Padding(
              // ajuste fino se precisar (altura da nav ~56 + respiro)
              padding: const EdgeInsets.only(bottom: 80),
              child: screens[_selectedIndex],
            ),
          ),
          // Navbar flutuando como overlay
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: CustomNavBar(
              currentIndex: _selectedIndex,
              onTap: _onTabTapped,
            ),
          ),
        ],
      ),
    );
  }
}