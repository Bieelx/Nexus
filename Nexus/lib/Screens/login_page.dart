import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nexus_app/service/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Three-in-one Login flow:
/// - Welcome (animated)
/// - Login
/// - Sign up (adds Nome/Sobrenome)
///
/// No new packages required. All animations use Flutter widgets.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

enum _Screen { welcome, login, signup }

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  // Controllers
  final _loginFormKey = GlobalKey<FormState>();
  final _signupFormKey = GlobalKey<FormState>();

  final _emailLoginCtrl = TextEditingController();
  final _passLoginCtrl = TextEditingController();

  final _emailSignCtrl = TextEditingController();
  final _passSignCtrl = TextEditingController();
  final _nomeCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _sobrenomeCtrl = TextEditingController();

  bool _loading = false;
  bool _obscureLogin = true;
  bool _obscureSign = true;

  _Screen _screen = _Screen.welcome;

  late final AnimationController _introCtrl =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
        ..forward();
  late final AnimationController _pulseCtrl =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))
        ..repeat(reverse: false);

  @override
  void dispose() {
    _introCtrl.dispose();
    _pulseCtrl.dispose();

    _emailLoginCtrl.dispose();
    _passLoginCtrl.dispose();

    _emailSignCtrl.dispose();
    _passSignCtrl.dispose();
    _nomeCtrl.dispose();
    _usernameCtrl.dispose();
    _sobrenomeCtrl.dispose();
    super.dispose();
  }

  Future<void> _doLogin() async {
    if (!_loginFormKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final auth = context.read<AuthService>();
      await auth.login(_emailLoginCtrl.text.trim(), _passLoginCtrl.text.trim());
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String msg;
      switch (e.code) {
        case 'user-not-found':
          msg = 'Usuário não encontrado. Verifique o e-mail digitado.';
          break;
        case 'wrong-password':
          msg = 'Senha incorreta. Tente novamente.';
          break;
        case 'invalid-email':
          msg = 'O e-mail informado é inválido.';
          break;
        default:
          msg = 'Não foi possível entrar. Tente novamente mais tarde.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao entrar. Tente novamente.')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _doSignup() async {
    if (!_signupFormKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final auth = context.read<AuthService>();
      await auth.registrar(
        _emailSignCtrl.text.trim(),
        _passSignCtrl.text.trim(),
        _nomeCtrl.text.trim(),
        _usernameCtrl.text.trim(),
        _sobrenomeCtrl.text.trim(),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String msg;
      switch (e.code) {
        case 'email-already-in-use':
          msg = 'Este e-mail já está em uso. Tente outro e-mail.';
          break;
        case 'username-already-in-use':
          msg = 'Este username já está em uso. Tente outro.';
          break;
        case 'weak-password':
          msg = 'A senha é muito fraca. Use pelo menos 6 caracteres.';
          break;
        case 'invalid-email':
          msg = 'O e-mail informado é inválido.';
          break;
        case 'operation-not-allowed':
          msg = 'Cadastro desabilitado. Contate o suporte.';
          break;
        default:
          msg = 'Não foi possível registrar. Tente novamente mais tarde.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao registrar. Tente novamente.')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // --------------------------- BUILD ----------------------------

  @override
  Widget build(BuildContext context) {
    // Background gradient consistent with app style
    final bg = const LinearGradient(
      begin: Alignment(0.54, 0.51),
      end: Alignment(-0.04, 0.95),
      colors: [Color(0xFF1B202E), Color(0xFF252C3A)],
    );

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: bg),
        child: SafeArea(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 450),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: _screen == _Screen.welcome
                ? _buildWelcome(context)
                : _screen == _Screen.login
                    ? _buildLogin(context)
                    : _buildSignup(context),
          ),
        ),
      ),
    );
  }

  // --------------------------- WELCOME ----------------------------

  Widget _buildWelcome(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Stack(
      key: const ValueKey('welcome'),
      children: [
        // Background floating dots
        ...List.generate(14, (i) {
          final delay = i * 0.12;
          final left = (i * 67) % size.width;
          final top = (i * 53) % size.height;
          return AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (_, __) {
              final t = (_pulseCtrl.value + delay).clamp(0, 1);
              final y = -20 - 80 * (t % 1);
              final opacity = (t % 1) < 0.5 ? (t % 1) * 2 : (1 - (t % 1)) * 2;
              return Positioned(
                left: left.toDouble(),
                top: top + y,
                child: Opacity(
                  opacity: 0.25 * opacity,
                  child: Container(
                    width: 3,
                    height: 3,
                    decoration: const BoxDecoration(
                      color: Color(0xFFAE85E5),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              );
            },
          );
        }),

        // Content
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Main icon with floating satellites
                SizedBox(
                  height: 150,
                  width: 150,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      ScaleTransition(
                        scale: CurvedAnimation(parent: _introCtrl, curve: Curves.elasticOut),
                        child: Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF9240FE), Color(0xFF8523F7)],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x55000000),
                                blurRadius: 18,
                                offset: Offset(0, 8),
                              )
                            ],
                          ),
                          child: const Icon(Icons.shield_outlined, color: Colors.white, size: 44),
                        ),
                      ),
                      // satellites
                      _floatingIcon(const Icon(Icons.lock_outline, color: Colors.white, size: 18),
                          dx: -28, dy: -40, delay: 0.0),
                      _floatingIcon(const Icon(Icons.bolt, color: Colors.white, size: 18),
                          dx: 44, dy: -22, delay: 0.4),
                      _floatingIcon(const Icon(Icons.security, color: Colors.white, size: 18),
                          dx: -34, dy: 38, delay: 0.8),
                      // pulse ring
                      AnimatedBuilder(
                        animation: _pulseCtrl,
                        builder: (_, __) {
                          final v = 1 + (_pulseCtrl.value * 0.3);
                          final op = 0.3 * (1 - _pulseCtrl.value);
                          return Transform.scale(
                            scale: v,
                            child: Opacity(
                              opacity: op,
                              child: Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: const Color(0x66CFAAFF), width: 2),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                // Title + subtitle
                FadeTransition(
                  opacity: CurvedAnimation(parent: _introCtrl, curve: const Interval(0.3, 1)),
                  child: Column(
                    children: const [
                      Text(
                        'Nexus',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Sua plataforma de segurança digital',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFFD5C4F3),
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Proteja-se contra ameaças cibernéticas',
                        style: TextStyle(color: Color(0xFFAE85E5), fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Buttons
                _PrimaryButton(
                  label: 'Fazer login',
                  onTap: () => setState(() => _screen = _Screen.login),
                ),
                const SizedBox(height: 12),
                _OutlineButton(
                  label: 'Criar conta',
                  onTap: () => setState(() => _screen = _Screen.signup),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Ao continuar, você concorda com nossos Termos de Uso e Política de Privacidade',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF717182), fontSize: 11),
                )
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _floatingIcon(Widget icon, {required double dx, required double dy, required double delay}) {
    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (_, __) {
        final t = ((_pulseCtrl.value + delay) % 1.0);
        final rot = (t * 20 - 10);
        return Transform.translate(
          offset: Offset(dx, dy),
          child: Transform.rotate(
            angle: rot * 3.1415 / 180,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF4650A0), Color(0xFF634A9E)]),
                borderRadius: BorderRadius.circular(8),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))],
              ),
              child: Center(child: icon),
            ),
          ),
        );
      },
    );
  }

  // --------------------------- LOGIN ----------------------------

  Widget _buildLogin(BuildContext context) {
    return _AuthScaffold(
      key: const ValueKey('login'),
      title: 'Bem-vindo de volta!',
      subtitle: 'Entre na sua conta para continuar',
      onBack: () => setState(() => _screen = _Screen.welcome),
      child: Form(
        key: _loginFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Email', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            TextFormField(
              controller: _emailLoginCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: _dec('SeuEmail@mail.com', icon: Icons.mail_outline),
              style: const TextStyle(color: Colors.white),
              validator: (v) => (v == null || !v.contains('@')) ? 'Informe um e-mail válido' : null,
            ),
            const SizedBox(height: 12),
            const Text('Senha', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            TextFormField(
              controller: _passLoginCtrl,
              obscureText: _obscureLogin,
              decoration: _dec('SuaSenha', icon: Icons.lock_outline, suffix: IconButton(
                icon: Icon(_obscureLogin ? Icons.visibility : Icons.visibility_off, color: Colors.white70),
                onPressed: () => setState(() => _obscureLogin = !_obscureLogin),
              )),
              style: const TextStyle(color: Colors.white),
              validator: (v) => (v == null || v.length < 6) ? 'Mínimo de 6 caracteres' : null,
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Recuperação de senha em breve'))),
                child: const Text('Esqueceu a senha?', style: TextStyle(color: Color(0xFFAE85E5), fontSize: 11)),
              ),
            ),
            const SizedBox(height: 16),
            _PrimaryButton(label: 'Entrar', loading: _loading, onTap: _loading ? null : _doLogin),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Não tem conta? ', style: TextStyle(color: Colors.white70)),
                GestureDetector(
                  onTap: () => setState(() => _screen = _Screen.signup),
                  child: const Text('Criar conta', style: TextStyle(color: Color(0xFFAE85E5), fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------- SIGNUP ----------------------------

  Widget _buildSignup(BuildContext context) {
    return _AuthScaffold(
      key: const ValueKey('signup'),
      title: 'Criar sua conta',
      subtitle: 'Preencha os campos para começar',
      onBack: () => setState(() => _screen = _Screen.welcome),
      child: Form(
        key: _signupFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Nome', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            TextFormField(
              controller: _nomeCtrl,
              decoration: _dec('Seu nome', icon: Icons.person_outline),
              style: const TextStyle(color: Colors.white),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe o nome' : null,
            ),
            const SizedBox(height: 12),
            const Text('Sobrenome', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            TextFormField(
              controller: _sobrenomeCtrl,
              decoration: _dec('Seu sobrenome', icon: Icons.person_2_outlined),
              style: const TextStyle(color: Colors.white),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe o sobrenome' : null,
            ),
            const SizedBox(height: 12),
            const Text('Username', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            TextFormField(
              controller: _usernameCtrl,
              decoration: _dec('Seu username', icon: Icons.alternate_email),
              style: const TextStyle(color: Colors.white),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe o username' : null,
            ),
            const SizedBox(height: 12),
            const Text('Email', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            TextFormField(
              controller: _emailSignCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: _dec('SeuEmail@mail.com', icon: Icons.mail_outline),
              style: const TextStyle(color: Colors.white),
              validator: (v) => (v == null || !v.contains('@')) ? 'Informe um e-mail válido' : null,
            ),
            const SizedBox(height: 12),
            const Text('Senha', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            TextFormField(
              controller: _passSignCtrl,
              obscureText: _obscureSign,
              decoration: _dec('Crie uma senha', icon: Icons.lock_outline, suffix: IconButton(
                icon: Icon(_obscureSign ? Icons.visibility : Icons.visibility_off, color: Colors.white70),
                onPressed: () => setState(() => _obscureSign = !_obscureSign),
              )),
              style: const TextStyle(color: Colors.white),
              validator: (v) => (v == null || v.length < 6) ? 'Mínimo de 6 caracteres' : null,
            ),
            const SizedBox(height: 16),
            _PrimaryButton(label: 'Registrar', loading: _loading, onTap: _loading ? null : _doSignup),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Já tem conta? ', style: TextStyle(color: Colors.white70)),
                GestureDetector(
                  onTap: () => setState(() => _screen = _Screen.login),
                  child: const Text('Entrar', style: TextStyle(color: Color(0xFFAE85E5), fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------- HELPERS ----------------------------

  InputDecoration _dec(String label, {IconData? icon, Widget? suffix}) {
    return InputDecoration(
      hintText: label,
      hintStyle: const TextStyle(
        color: Colors.white54,
        fontWeight: FontWeight.normal,
        fontSize: 16,
      ),
      prefixIcon: icon == null ? null : Icon(icon, color: Colors.white70),
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xFF2A2F3C),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF6C7691)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF6C7691)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFA259FF), width: 1.6),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      // To have white input text, apply style: TextStyle(color: Colors.white) directly to the TextFormField where used.
    );
  }
}

// Simple auth scaffold with back + header
class _AuthScaffold extends StatelessWidget {
  const _AuthScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    required this.onBack,
    this.showGoogle = true,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final VoidCallback onBack;
  final bool showGoogle;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Back button floating on top-left
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFFAE85E5)),
              ),
            ),
            const SizedBox(height: 4),
            // Centered icon + title/subtitle like the mock
            Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                _HeaderIcon(),
                SizedBox(height: 14),
              ],
            ),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFFD5C4F3), fontSize: 12),
            ),
            const SizedBox(height: 18),
            // Form content scrollable
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 12),
                child: child,
              ),
            ),
            if (showGoogle) ...[
              const SizedBox(height: 16),
              const _OrDivider(),
              const SizedBox(height: 16),
              const _GoogleButton(),
            ],
          ],
        ),
      ),
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  const _HeaderIcon();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF9240FE), Color(0xFF8523F7)]),
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Color(0x33000000), blurRadius: 12, offset: Offset(0, 6)),
        ],
      ),
      child: const Icon(Icons.lock_outline, color: Colors.white, size: 32),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();
  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(child: Divider(color: Color(0xFF6C7691))),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.0),
          child: Text('ou', style: TextStyle(color: Colors.white70)),
        ),
        Expanded(child: Divider(color: Color(0xFF6C7691))),
      ],
    );
  }
}

class _GoogleButton extends StatelessWidget {
  const _GoogleButton();
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login com Google em breve')),
      ),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF6C53BB), width: 2),
        ),
        child: const Center(
          child: Text(
            'Continuar com o Google',
            style: TextStyle(color: Color(0xFFC2A1ED), fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, this.onTap, this.loading = false});

  final String label;
  final VoidCallback? onTap;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 52,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF9240FE), Color(0xFF8523F7)]),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(color: Color(0x55000000), blurRadius: 10, offset: Offset(0, 6)),
          ],
        ),
        child: Center(
          child: loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Text(
                  label,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
        ),
      ),
    );
  }
}

class _OutlineButton extends StatelessWidget {
  const _OutlineButton({required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF6C53BB), width: 2),
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(color: Color(0xFFC2A1ED), fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}