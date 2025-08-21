import 'package:chatbot_sec4you/Screens/Subscreens/AlterarEmailPage.dart';
import 'package:chatbot_sec4you/Screens/Subscreens/AlterarIdiomaPage.dart';
import 'package:chatbot_sec4you/Screens/Subscreens/AlterarNotificacoesPage.dart';
import 'package:chatbot_sec4you/Screens/Subscreens/AlterarPrivacidadePage.dart';
import 'package:chatbot_sec4you/Screens/Subscreens/AlterarSenhaPage.dart';
import 'package:chatbot_sec4you/Screens/Subscreens/AlterarTemaPage.dart';
import 'package:chatbot_sec4you/Screens/Subscreens/alterar_Profile_Page.dart';
import 'package:chatbot_sec4you/Screens/login_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';
import 'dart:io' show File;

/// ======= CORES / CONFIG =======
const kAccent = Color(0xFFA259FF); // #A259FF (roxo pedido)
const kBg = Color(0xFF121212);
const kCard = Color(0xFF2A2A2A);
const kText = Color(0xFFFAF9F6);
const String kAvatarAsset = 'assets/foto_perfil.png';

/// Página pública usada no Navigator do app.
/// Envelopa a implementação interna `ProfileScreen`.
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProfileScreen();
  }
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  late final TabController _tabs;
  late final AnimationController _glowCtrl;
  late final Animation<double> _glow;
  final _scaffoldKey =
      GlobalKey<ScaffoldState>(); // <- para abrir o menu lateral

  StreamSubscription<User?>? _authSub;
  String _displayName = 'Usuário';

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _userDocSub;
  String _roleTag = 'Estagiário';
  String? _photoUrl;
  bool _isUploadingPhoto = false;

  // ===== Upload de foto de perfil =====
  UploadTask? _currentUploadTask;
  StreamSubscription<TaskSnapshot>? _uploadSub;
  double _uploadProgress = 0;

  String _nameFromUser(User? u) {
    if (u == null) return 'Usuário';
    final dn = u.displayName?.trim();
    if (dn != null && dn.isNotEmpty) return dn;
    final email = u.email;
    if (email != null && email.contains('@')) {
      final nick = email.split('@').first;
      if (nick.isNotEmpty) {
        return nick[0].toUpperCase() + nick.substring(1);
      }
    }
    return 'Usuário';
  }

  Future<void> _updateDisplayName(String newDisplayName) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Atualiza o displayName no FirebaseAuth
    await user.updateDisplayName(newDisplayName);

    // Agora, atualiza o displayName no Firestore
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'displayName': newDisplayName,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // Após a atualização, forçamos uma reconstrução da tela para mostrar o novo nome
    setState(() {
      _displayName = newDisplayName;
    });
  }

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _glow = CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut);

    // Nome do usuário logado (Firebase Auth)
    _displayName = _nameFromUser(FirebaseAuth.instance.currentUser);

    _authSub = FirebaseAuth.instance.userChanges().listen((u) {
      final newName = _nameFromUser(u);
      if (newName != _displayName) {
        setState(() => _displayName = newName);
      }
    });

    // Escuta o doc do usuário em Firestore para tag/foto
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      _userDocSub = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .snapshots()
          .listen((snap) {
            final data = snap.data();
            if (data != null) {
              final newTag = (data['tag'] as String?)?.trim();
              final newPhoto = (data['photoUrl'] as String?)?.trim();
              final newDisplayName = (data['displayName'] as String?)?.trim();

              bool changed = false;
              if (newTag != null && newTag.isNotEmpty && newTag != _roleTag) {
                _roleTag = newTag;
                changed = true;
              }
              if (newPhoto != _photoUrl) {
                _photoUrl = newPhoto;
                changed = true;
              }
              if (newDisplayName != null && newDisplayName != _displayName) {
                _displayName = newDisplayName;
                changed = true;
              }
              if (changed) setState(() {});
            }
          });
    }
  }

  @override
  void dispose() {
    _tabs.dispose();
    _glowCtrl.dispose();
    _authSub?.cancel();
    _userDocSub?.cancel();
    super.dispose();
  }

  Future<void> _pickAndUploadProfilePhoto(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Você precisa estar logado.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
    );
    if (picked == null) return;

    setState(() => _isUploadingPhoto = true);
    try {
      final String path =
          'users/${user.uid}/profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = FirebaseStorage.instance.ref(path);

      // Lê os bytes e inicia upload com metadados
      final Uint8List bytes = await picked.readAsBytes();
      final SettableMetadata meta = SettableMetadata(contentType: 'image/jpeg');
      _currentUploadTask = ref.putData(bytes, meta);

      // Escuta progresso
      _uploadSub = _currentUploadTask!.snapshotEvents.listen((
        TaskSnapshot snap,
      ) {
        if (snap.totalBytes > 0) {
          final p = snap.bytesTransferred / snap.totalBytes;
          if (mounted) setState(() => _uploadProgress = p.clamp(0, 1));
        }
      });

      // Timeout defensivo para evitar travar indefinidamente
      final TaskSnapshot snap = await _currentUploadTask!.timeout(
        const Duration(seconds: 60),
      );
      final String downloadUrl = await snap.ref.getDownloadURL();

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'photoUrl': downloadUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      setState(() {
        _photoUrl = downloadUrl;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Foto de perfil atualizada!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      // Cancela upload se ainda estiver em andamento
      try {
        await _currentUploadTask?.cancel();
      } catch (_) {}
      if (!mounted) return;
      final String msg =
          (e is TimeoutException)
              ? 'Tempo esgotado ao enviar a foto. Verifique sua conexão e tente novamente.'
              : 'Falha ao enviar foto: $e';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
      );
    } finally {
      await _uploadSub?.cancel();
      _uploadSub = null;
      _currentUploadTask = null;
      if (mounted)
        setState(() {
          _isUploadingPhoto = false;
          _uploadProgress = 0;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final pad = w < 480 ? 12.0 : 16.0;
        final cardRadius = w < 480 ? 18.0 : 22.0;

        // tamanhos usados no avatar e nas pílulas
        final pillW = w < 480 ? 86.0 : 110.0;
        final pillH = w < 480 ? 32.0 : 38.0;
        final avatarSize = w < 480 ? 160.0 : 190.0; // AVATAR MAIOR
        final overlap =
            avatarSize / 3; // quanto o avatar “sai” para fora do card

        final h = MediaQuery.of(context).size.height;
        final topOffset =
            h * (82 / 892); // coloca o cabeçalho a ~82px (tela 412x892)

        return Scaffold(
          key: _scaffoldKey,

          // ===== MENU LATERAL (endDrawer) =====
          endDrawer: _ProfileDrawer(
            onItemTap: (route) {
              Navigator.pop(context); // fecha o menu
              // TODO: navegue para telas reais conforme implementar
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Abrir: $route'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),

          body: SafeArea(
            child: Column(
              children: [
                // ===== Cabeçalho alinhado a 82px do topo (responsivo) =====
                Padding(
                  padding: EdgeInsets.fromLTRB(pad, topOffset, pad, 0),
                  child: Row(
                    children: [
                      // Botão Voltar
                      Material(
                        color: const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () {
                            final nav = Navigator.of(context);
                            if (nav.canPop()) {
                              nav.pop();
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Não há tela anterior para voltar.',
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                          child: const SizedBox(
                            width: 44,
                            height: 44,
                            child: Icon(
                              Icons.arrow_back,
                              color: kAccent,
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                      // Título centralizado
                      Expanded(
                        child: Center(
                          child: Text(
                            'Meu perfil',
                            style: TextStyle(
                              color: kAccent,
                              fontWeight: FontWeight.w400,
                              fontSize: w < 480 ? 22 : 24,
                              letterSpacing: .2,
                            ),
                          ),
                        ),
                      ),
                      // Botão Configurações
                      _GearButton(
                        onTap: () => _scaffoldKey.currentState?.openEndDrawer(),
                      ),
                    ],
                  ),
                ),

                // ===== AVATAR FORA DO CARD + PÍLULAS + BOTÃO EDITAR FOTO =====
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: pad),
                  child: SizedBox(
                    // aumenta a altura do stack para comportar avatar + (19px) + textos + abas
                    height: avatarSize + 170,
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.topCenter,
                      children: [
                        // Avatar maior + brilho respirando (somente a luz anima; tamanho fixo)
                        Positioned(
                          top: 0,
                          child: Stack(
                            clipBehavior: Clip.none,
                            alignment: Alignment.center,
                            children: [
                              IgnorePointer(
                                child: AnimatedBuilder(
                                  animation: _glow,
                                  builder: (context, _) {
                                    final t = _glow.value; // 0..1
                                    return Container(
                                      width: avatarSize + 26,
                                      height: avatarSize + 26,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(28),
                                        boxShadow: [
                                          BoxShadow(
                                            color: kAccent.withOpacity(
                                              0.16 + 0.10 * t,
                                            ),
                                            blurRadius: 26 + 18 * t,
                                            spreadRadius: 6 + 6 * t,
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                              Container(
                                width: avatarSize,
                                height: avatarSize,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2A2A2A),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(color: kAccent, width: 3),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child:
                                    (_photoUrl != null && _photoUrl!.isNotEmpty)
                                        ? Image.network(
                                          _photoUrl!,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (_, __, ___) => const Center(
                                                child: Icon(
                                                  Icons.person,
                                                  size: 64,
                                                  color: Colors.white70,
                                                ),
                                              ),
                                        )
                                        : Image.asset(
                                          kAvatarAsset,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (_, __, ___) => const Center(
                                                child: Icon(
                                                  Icons.person,
                                                  size: 64,
                                                  color: Colors.white70,
                                                ),
                                              ),
                                        ),
                              ),
                              Positioned(
                                right: -6,
                                bottom: -6,
                                child: Material(
                                  color: kAccent,
                                  shape: const CircleBorder(),
                                  elevation: 4,
                                  child: InkWell(
                                    customBorder: const CircleBorder(),
                                    onTap:
                                        () =>
                                            _pickAndUploadProfilePhoto(context),
                                    child: const SizedBox(
                                      width: 36,
                                      height: 36,
                                      child: Icon(
                                        Icons.edit,
                                        size: 18,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              if (_isUploadingPhoto)
                                Positioned.fill(
                                  child: Container(
                                    color: Colors.black26,
                                    alignment: Alignment.center,
                                    child: SizedBox(
                                      width: 36,
                                      height: 36,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 3,
                                        color: kAccent,
                                        value:
                                            (_uploadProgress > 0 &&
                                                    _uploadProgress < 1)
                                                ? _uploadProgress
                                                : null,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        // === BLOCO DE NOME / ROLE / ABAS: fixado a 19px abaixo do avatar ===
                        Positioned(
                          top: avatarSize + 19,
                          left: 0,
                          right: 0,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                _displayName,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: kAccent,
                                  fontWeight: FontWeight.w800,
                                  fontSize: w < 480 ? 18 : 20,
                                ),
                              ),
                              const SizedBox(height: 6),
                              _RoleTagPill(text: _roleTag),
                              const SizedBox(height: 12),
                              _SegmentedTabs(controller: _tabs),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // (nome/role/abas agora estão dentro do Stack do avatar)

                // CONTEÚDO
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: pad),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF202634),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFF6C7691),
                          width: 0.5,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black38,
                            blurRadius: 12,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.fromLTRB(16, 22, 16, 16),
                      child: DefaultTextStyle.merge(
                        style: const TextStyle(
                          color: Color(0xFFFAF9F6),
                          fontSize: 16,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w400,
                        ),
                        child: TabBarView(
                          controller: _tabs,
                          children: [_AboutMeTab(), _StatsTab(), _LoremTab()],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _GearButton extends StatelessWidget {
  const _GearButton({this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF1A1A1A),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: const SizedBox(
          width: 44, // ligeiramente maior
          height: 44, // ligeiramente maior
          child: Icon(Icons.settings, color: kAccent, size: 22),
        ),
      ),
    );
  }
}

class _RoleTagPill extends StatelessWidget {
  const _RoleTagPill({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 4,
      ), // Ajusta o espaçamento interno ao redor do texto
      decoration: BoxDecoration(
        color: const Color(0xB2422672), // Cor de fundo da tag
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFAE85E5)), // Cor da borda
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFFBD9EE7), // Cor do texto da tag
          fontSize: 12,
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w500,
          height: 1.67,
          letterSpacing: 0.12,
        ),
        overflow:
            TextOverflow
                .ellipsis, // Garante que o texto não ultrapasse os limites
      ),
    );
  }
}

class _DecorPill extends StatelessWidget {
  const _DecorPill({required this.width, required this.height});
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}

/// Abas com selecionado: fundo kAccent 20% + borda kAccent 100% + fonte 400
class _SegmentedTabs extends StatelessWidget {
  const _SegmentedTabs({required this.controller});
  final TabController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF232323),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF3A3A3A)),
      ),
      child: TabBar(
        controller: controller,
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: kAccent,
        unselectedLabelColor: Colors.white70,
        labelStyle: const TextStyle(fontWeight: FontWeight.w400, fontSize: 13),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w400,
          fontSize: 13,
        ),
        indicator: ShapeDecoration(
          color: kAccent.withOpacity(0.20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: kAccent, width: 1.6),
          ),
          shadows: const [
            BoxShadow(
              color: Colors.black45,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        tabs: const [
          Tab(text: 'Sobre mim'),
          Tab(text: 'Estatísticas'),
          Tab(text: 'Lorem ipsum'),
        ],
      ),
    );
  }
}

class _AboutMeTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Suponha que você tenha o ID do usuário (userId) disponível
    String userId = FirebaseAuth.instance.currentUser!.uid;

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Center(child: Text('Informações não encontradas.'));
        }

        String aboutMe =
            snapshot.data!.get('aboutMe') ?? 'Sem descrição disponível.';

        return SingleChildScrollView(
          child: Text(
            aboutMe,
            style: const TextStyle(fontWeight: FontWeight.w400),
          ),
        );
      },
    );
  }
}

class _StatsTab extends StatelessWidget {
  const _StatsTab();

  @override
  Widget build(BuildContext context) {
    final items = <(String, String)>[
      ('Posts', '128'),
      ('Seguidores', '2.4k'),
      ('Seguindo', '312'),
      ('Conquistas', '12'),
      ('Horas de estudo', '87h'),
      ('Nível', 'Estagiário'),
    ];

    return GridView.builder(
      itemCount: items.length,
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.6,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
      ),
      itemBuilder: (_, i) {
        final (label, value) = items[i];
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1F1F1F),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF3A3A3A)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    height: 1.2,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: kText,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LoremTab extends StatelessWidget {
  const _LoremTab();

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      child: Text(
        'Lorem ipsum dolor sit amet, consectetur adipiscing elit. '
        'Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. '
        'Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris.',
        style: TextStyle(fontWeight: FontWeight.w400),
      ),
    );
  }
}

/// ===== Drawer de Perfil (menu lateral) =====
class _ProfileDrawer extends StatelessWidget {
  const _ProfileDrawer({required this.onItemTap});
  final void Function(String route) onItemTap;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF1A1A1A),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            ListTile(
              title: const Text(
                'Perfil',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: const Text(
                'Configurações da sua conta',
                style: TextStyle(color: Colors.white70),
              ),
              leading: const CircleAvatar(
                radius: 18,
                backgroundColor: kAccent,
                child: Icon(Icons.person, color: Colors.white, size: 18),
              ),
            ),
            const Divider(),

            _tile(Icons.account_circle, 'Alterar Perfil', () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AlterarProfilePage(),
                ),
              );
            }),
            _tile(Icons.alternate_email, 'Alterar e-mail', () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AlterarEmailPage(),
                ),
              );
            }),
            _tile(Icons.lock, 'Alterar senha', () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AlterarSenhaPage(),
                ),
              );
            }),
            _tile(Icons.privacy_tip, 'Privacidade', () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AlterarPrivacidadePage(),
                ),
              );
            }),
            _tile(Icons.notifications, 'Notificações', () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AlterarNotificacoesPage(),
                ),
              );
            }),
            _tile(Icons.palette, 'Preferências de tema', () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AlterarTemaPage(),
                ),
              );
            }),
            _tile(Icons.language, 'Idioma', () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AlterarIdiomaPage(),
                ),
              );
            }),

            const Divider(),
            _tile(Icons.logout, 'Sair', () {
              _showLogoutDialog(context); // Exibe o diálogo de confirmação
            }, danger: true),
          ],
        ),
      ),
    );
  }

  // Função para exibir o diálogo de confirmação de logout
  Future<void> _showLogoutDialog(BuildContext context) async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Tem certeza que deseja sair?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Fecha o diálogo
              },
              child: const Text('Não', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () async {
                // Realiza o logout
                await FirebaseAuth.instance.signOut();

                // Fecha o diálogo
                Navigator.of(context).pop();

                // Redireciona para a tela de login ou home
                Navigator.push(
                  context,MaterialPageRoute(
                  builder: (context) => const LoginPage(),
                ) 
                  
                ); // Altere '/login' para a rota de login
              },
              child: const Text('Sim', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  ListTile _tile(
    IconData icon,
    String label,
    VoidCallback onTap, {
    bool danger = false,
  }) {
    return ListTile(
      leading: Icon(icon, color: danger ? Colors.redAccent : kAccent),
      title: Text(
        label,
        style: TextStyle(
          color: Colors.white,
          fontWeight: danger ? FontWeight.w700 : FontWeight.w400,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.white70),
      onTap: onTap,
    );
  }
}
