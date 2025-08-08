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
import 'firebase_options.dart';

import 'navbar.dart'; 
import 'core/theme/app_colors.dart';

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
        useMaterial3: false,
        scaffoldBackgroundColor: AppColors.background,
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
      UsersMapScreen(),

    ];

return Scaffold(
  body: screens[_selectedIndex],
  bottomNavigationBar: CustomNavBar(
    currentIndex: _selectedIndex,
    onTap: _onTabTapped,
  ),
);
  }
}