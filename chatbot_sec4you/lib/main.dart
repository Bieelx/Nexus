import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'service/auth_service.dart';
import 'login_page.dart';
import 'home_screen.dart';
import 'chat_screen.dart';
import 'leak_check_screen.dart';
import 'boards_screen.dart';
import 'users_map_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

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
  await Firebase.initializeApp();
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
        useMaterial3: false,
        scaffoldBackgroundColor: const Color(0xFF0D0D0D),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1A1A1A),
          iconTheme: IconThemeData(color: Color(0xFFFAF9F6)),
          titleTextStyle: TextStyle(
            color: Color(0xFFFAF9F6),
            fontWeight: FontWeight.bold,
            fontSize: 20,
            fontFamily: 'JetBrainsMono',
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF1A1A1A),
          selectedItemColor: Color(0xFF7F2AB1),
          unselectedItemColor: Color(0xFFFAF9F6),
          type: BottomNavigationBarType.fixed,
        ),
        fontFamily: 'JetBrainsMono',
      ),
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
    if (index == 5) {
      // Se for a aba de logout
      await Provider.of<AuthService>(context, listen: false).logout();
    } else {
      setState(() {
        _selectedIndex = index;
        _autoMessage = '';
      });
    }
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
      UsersMapScreen(),
      Container(), // Aba vazia para logout
    ];

    return Scaffold(
      body: screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onTabTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.house),
            label: 'Início',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.security),
            label: 'Vazamentos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.forum),
            label: 'Fórum',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Mapa',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.logout),
            label: 'Sair',
          ),
        ],
      ),
    );
  }
}