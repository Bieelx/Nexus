import 'package:flutter/material.dart';

void main() => runApp(const Sec4YouApp());

class Sec4YouApp extends StatelessWidget {
  const Sec4YouApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sec4You',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        textTheme: ThemeData.dark().textTheme.apply(
          fontFamily: 'JetBrainsMono',
          bodyColor: const Color(0xFFFAF9F6),
          displayColor: const Color(0xFFFAF9F6),
        ),
      ),
      home: const ProfileScreen(),
    );
  }
}

/// ======= CORES / CONFIG =======
const kAccent = Color(0xFFA259FF); // #A259FF (roxo pedido)
const kBg = Color(0xFF121212);
const kCard = Color(0xFF2A2A2A);
const kText = Color(0xFFFAF9F6);
const kAvatarAsset = 'assets/foto_perfil.png';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _scaffoldKey = GlobalKey<ScaffoldState>(); // <- para abrir o menu lateral

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
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
        final overlap = avatarSize / 3; // quanto o avatar “sai” para fora do card

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

          backgroundColor: kBg,
          body: SafeArea(
            child: Column(
              children: [
                // Top bar
                Padding(
                  padding: EdgeInsets.fromLTRB(pad, pad * .5, pad, 0),
                  child: Row(
                    children: [
                      const Spacer(),
                      _GearButton(
                        onTap: () => _scaffoldKey.currentState?.openEndDrawer(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Meu perfil',
                  style: TextStyle(
                    color: kAccent,
                    fontWeight: FontWeight.w400,
                    fontSize: w < 480 ? 22 : 24,
                    letterSpacing: .2,
                  ),
                ),
                const SizedBox(height: 10),

                // ===== AVATAR FORA DO CARD + PÍLULAS + BOTÃO EDITAR FOTO =====
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: pad),
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.topCenter,
                    children: [
                      // CARD: desce para dar espaço ao avatar sobreposto
                      Container(
                        margin: EdgeInsets.only(top: overlap),
                        decoration: BoxDecoration(
                          color: const Color(0xFF242424),
                          borderRadius: BorderRadius.circular(cardRadius + 6),
                          border: Border.all(color: const Color(0xFF3A3A3A)),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black45,
                              blurRadius: 16,
                              offset: Offset(0, 6),
                            ),
                          ],
                        ),
                        padding: EdgeInsets.fromLTRB(pad, pad + 15, pad, pad),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // espaço reservado dentro do card para o avatar que está por cima
                            SizedBox(height: avatarSize / 2 + 12),

                            // textos
                            Text(
                              'Gustavo Teodoro',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: kAccent,
                                fontWeight: FontWeight.w800,
                                fontSize: w < 480 ? 18 : 20,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Estagiário',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                              ),
                            ),

                            const SizedBox(height: 14),
                            _SegmentedTabs(controller: _tabs),
                          ],
                        ),
                      ),

                      // Pílulas laterais atrás do avatar
                      Positioned(
                        top: overlap - (pillH / 2) + 30,
                        left: 16,
                        child: _DecorPill(width: pillW, height: pillH),
                      ),
                      Positioned(
                        top: overlap - (pillH / 2) + 30,
                        right: 16,
                        child: _DecorPill(width: pillW, height: pillH),
                      ),

                      // Avatar maior sobrepondo o card + botão editar foto
                      Positioned(
                        top: 0,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(28),
                              child: Image.asset(
                                kAvatarAsset,
                                width: avatarSize,
                                height: avatarSize,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.smart_toy,
                                  size: 96,
                                  color: Colors.white70,
                                ),
                              ),
                            ),
                            // botão pequeno para alterar foto (canto inferior direito)
                            Positioned(
                              right: -6,
                              bottom: -6,
                              child: Material(
                                color: kAccent,
                                shape: const CircleBorder(),
                                elevation: 4,
                                child: InkWell(
                                  customBorder: const CircleBorder(),
                                  onTap: () {
                                    // TODO: abrir seletor de imagem / câmera
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content:
                                            Text('Alterar foto de perfil'),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  },
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
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // CONTEÚDO
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: pad),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF2F2F2F),
                        borderRadius: BorderRadius.circular(cardRadius),
                        border: Border.all(color: const Color(0xFF3A3A3A)),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black38,
                            blurRadius: 14,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      padding: EdgeInsets.all(pad),
                      child: TabBarView(
                        controller: _tabs,
                        children: const [
                          _AboutMeTab(),
                          _StatsTab(),
                          _LoremTab(),
                        ],
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
          width: 44,  // ligeiramente maior
          height: 44, // ligeiramente maior
          child: Icon(Icons.settings, color: kAccent, size: 22),
        ),
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
  const _AboutMeTab();

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      child: Text(
        'Mussum Ipsum, cacilds vidis litro abertis.  Per aumento de cachacis, eu reclamis. '
        'Si num tem leite então bota uma pinga aí cumpadi! Suco de cevadiss deixa as pessoas '
        'mais interessantis. A ordem dos tratores não altera o pão duris.',
        style: TextStyle(fontWeight: FontWeight.w400),
      ),
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
              title: const Text('Perfil', style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: const Text('Configurações da sua conta', style: TextStyle(color: Colors.white70)),
              leading: const CircleAvatar(radius: 18, backgroundColor: kAccent, child: Icon(Icons.person, color: Colors.white, size: 18)),
            ),
            const Divider(),

            _tile(Icons.account_circle, 'Alterar perfil', () => onItemTap('alterar_perfil')),
            _tile(Icons.alternate_email, 'Alterar e-mail', () => onItemTap('alterar_email')),
            _tile(Icons.lock, 'Alterar senha', () => onItemTap('alterar_senha')),
            _tile(Icons.privacy_tip, 'Privacidade', () => onItemTap('privacidade')),
            _tile(Icons.notifications, 'Notificações', () => onItemTap('notificacoes')),
            _tile(Icons.palette, 'Preferências de tema', () => onItemTap('tema')),
            _tile(Icons.language, 'Idioma', () => onItemTap('idioma')),

            const Divider(),
            _tile(Icons.logout, 'Sair', () => onItemTap('sair'), danger: true),
          ],
        ),
      ),
    );
  }

  ListTile _tile(IconData icon, String label, VoidCallback onTap, {bool danger = false}) {
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
