import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:nexus_app/Screens/login_page.dart';
import 'package:nexus_app/service/xp_service.dart';
import 'package:nexus_app/service/user_service.dart';
import 'package:nexus_app/Screens/Subscreens/Profile/AlterarEmailPage.dart';
import 'package:nexus_app/Screens/Subscreens/Profile/AlterarIdiomaPage.dart';
import 'package:nexus_app/Screens/Subscreens/Profile/AlterarNotificacoesPage.dart';
import 'package:nexus_app/Screens/Subscreens/Profile/AlterarPrivacidadePage.dart';
import 'package:nexus_app/Screens/Subscreens/Profile/AlterarSenhaPage.dart';
import 'package:nexus_app/Screens/Subscreens/Profile/AlterarTemaPage.dart';
import 'package:nexus_app/Screens/Subscreens/Profile/alterar_Profile_Page.dart';
import 'package:nexus_app/Screens/Subscreens/Profile/avatar_selection_screen.dart';


const kAccent = Color(0xFFA259FF);
const kAccentLight = Color(0xFFAE85E5);
const kAccentDark = Color(0xFF8447D6);
const kBgGradient = [Color(0xFF1B202E), Color(0xFF252C3A)];
const kCard = Color(0xFF202634);
const kCardBorder = Color(0xFF6C7691);
const kTextSecondary = Color(0xFF7D8498);
const kText = Colors.white;

class ProfilePage extends StatefulWidget {
  final String? userId;
  const ProfilePage({Key? key, this.userId}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with TickerProviderStateMixin {
  late final TabController _tabs;
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  
  late final String _profileUid;
  late final bool _isOwnProfile;

  StreamSubscription? _userDocSub;
  Map<String, dynamic> _userData = {};

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);

    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    _isOwnProfile = widget.userId == null || widget.userId == currentUid;
    _profileUid = widget.userId ?? currentUid!;

    _userDocSub = FirebaseFirestore.instance
        .collection('users')
        .doc(_profileUid)
        .snapshots()
        .listen((doc) {
      if (doc.exists && mounted) {
        setState(() => _userData = doc.data()!);
      }
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    _userDocSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_userData.isEmpty) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(gradient: LinearGradient(colors: kBgGradient)),
          child: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final String displayName = '${_userData['nome'] ?? ''} ${_userData['sobrenome'] ?? ''}'.trim();
    final String username = _userData['username'] ?? '';
    final String? photoUrl = _userData['photoUrl'];
    final String aboutMe = _userData['aboutMe'] ?? 'Sem descrição disponível.';

    return Scaffold(
      key: _scaffoldKey,
      endDrawer: _isOwnProfile ? const _ProfileDrawer() : null,
      body: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(colors: kBgGradient, begin: Alignment.topCenter, end: Alignment.bottomCenter)),
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(context),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  children: [
                    const SizedBox(height: 20),
                    _buildAvatar(photoUrl),
                    const SizedBox(height: 16),
                    _buildUserInfo(displayName, username),
                    const SizedBox(height: 24),
                    _buildLevelAndRole(),
                    const SizedBox(height: 16),
                    _buildXpBar(),
                    const SizedBox(height: 32),
                    _SegmentedTabs(controller: _tabs),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 400,
                      child: Container(
                        decoration: BoxDecoration(
                          color: kCard,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: kCardBorder, width: 0.5),
                        ),
                        padding: const EdgeInsets.fromLTRB(16, 22, 16, 16),
                        child: TabBarView(
                          controller: _tabs,
                          children: [
                            _AboutMeTab(aboutMe: aboutMe),
                            _StatsTab(userId: _profileUid),
                            _PostsTab(userId: _profileUid),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _CircleButton(icon: Icons.arrow_back, onTap: () => Navigator.of(context).pop()),
          Text(
            _isOwnProfile ? 'Meu Perfil' : 'Perfil',
            style: const TextStyle(color: kAccentLight, fontSize: 20, fontFamily: 'Poppins', fontWeight: FontWeight.w500),
          ),
          if (_isOwnProfile)
            _CircleButton(icon: Icons.settings, onTap: () => _scaffoldKey.currentState?.openEndDrawer())
          else
            const SizedBox(width: 44),
        ],
      ),
    );
  }

  Widget _buildAvatar(String? photoUrl) {
    return Center(
      child: Stack(
        children: [
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: kAccentDark, width: 3),
              color: kCard,
            ),
            clipBehavior: Clip.antiAlias,
            child: (photoUrl != null && photoUrl.isNotEmpty)
                ? (photoUrl.startsWith('assets/')
                    ? Image.asset(
                        photoUrl,
                        fit: BoxFit.cover,
                        alignment: Alignment.topCenter,
                      )
                    : Image.network(
                        photoUrl,
                        fit: BoxFit.cover,
                        alignment: Alignment.topCenter,
                        errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 50, color: kTextSecondary),
                      ))
                : const Icon(Icons.person, size: 50, color: kTextSecondary),
          ),
          if (_isOwnProfile)
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AvatarSelectionScreen(
                      currentPhotoUrl: photoUrl,
                    ),
                  ),
                ),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: kAccent,
                    shape: BoxShape.circle,
                    border: Border.all(color: kBgGradient[0], width: 2),
                  ),
                  child: const Icon(Icons.edit, color: Colors.white, size: 18),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUserInfo(String displayName, String username) {
    return Column(
      children: [
        if (displayName.isNotEmpty)
          Text(displayName, textAlign: TextAlign.center, style: const TextStyle(color: kAccentLight, fontSize: 20, fontFamily: 'Poppins', fontWeight: FontWeight.w500)),
        if (username.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text('@$username', textAlign: TextAlign.center, style: const TextStyle(color: kTextSecondary, fontSize: 12, fontFamily: 'Poppins', fontWeight: FontWeight.w500)),
        ],
      ],
    );
  }

  Widget _buildLevelAndRole() {
    return StreamBuilder<Map<String, dynamic>?>(
      stream: XpService().listenToXp(_profileUid),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox(height: 23);
        final data = snapshot.data!;
        final level = data['level'] as int? ?? 1;
        final classTag = data['classTag'] as String? ?? 'Iniciante';
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _InfoPill(text: '$level', isLevel: true),
            const SizedBox(width: 8),
            _InfoPill(text: classTag),
          ],
        );
      },
    );
  }

  Widget _buildXpBar() {
    return StreamBuilder<Map<String, dynamic>?>(
      stream: XpService().listenToXp(_profileUid),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox(height: 32);
        final data = snapshot.data!;
        final int xp = data['xp'] as int? ?? 0;
        final int xpNeeded = data['xpNeeded'] as int? ?? 1;
        final double progress = xpNeeded > 0 ? (xp / xpNeeded).clamp(0.0, 1.0) : 0.0;
        return Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                backgroundColor: const Color(0xAF545252),
                valueColor: const AlwaysStoppedAnimation(kAccentDark),
              ),
            ),
            const SizedBox(height: 8),
            Text('XP: $xp/$xpNeeded', style: const TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'Poppins')),
          ],
        );
      },
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.icon, this.onTap});
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.08),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(width: 44, height: 44, child: Icon(icon, color: kAccentLight, size: 22)),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.text, this.isLevel = false});
  final String text;
  final bool isLevel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isLevel ? 0 : 12, vertical: 4),
      width: isLevel ? 23 : null,
      height: 23,
      decoration: BoxDecoration(
        color: const Color(0xB2422672),
        borderRadius: BorderRadius.circular(isLevel ? 16 : 8),
        border: Border.all(color: kAccentLight),
      ),
      child: Center(
        child: Text(text, style: const TextStyle(color: Color(0xFFBD9EE7), fontSize: 12, fontFamily: 'Poppins')),
      ),
    );
  }
}

class _SegmentedTabs extends StatelessWidget {
  const _SegmentedTabs({required this.controller});
  final TabController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kCardBorder, width: 0.5),
      ),
      child: TabBar(
        controller: controller,
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: kAccent,
        unselectedLabelColor: Colors.white,
        labelStyle: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w400, fontSize: 12),
        indicator: BoxDecoration(
          color: kAccent.withOpacity(0.20),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: kAccent, width: 1.0),
        ),
        tabs: const [Tab(text: 'Sobre mim'), Tab(text: 'Estatísticas'), Tab(text: 'Posts')],
      ),
    );
  }
}

class _AboutMeTab extends StatelessWidget {
  final String aboutMe;
  const _AboutMeTab({required this.aboutMe});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Text(aboutMe, style: const TextStyle(fontWeight: FontWeight.w400, color: kText, fontSize: 15)),
    );
  }
}

class _StatsTab extends StatelessWidget {
  final String userId;
  const _StatsTab({required this.userId});
  
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, int>>(
      future: _fetchStats(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final stats = snapshot.data ?? {};
        final items = [
          ('Posts', stats['posts'] ?? 0),
          ('Likes recebidos', stats['likesReceived'] ?? 0),
          ('Likes dados', stats['likesGiven'] ?? 0),
        ];

        return GridView.builder(
          itemCount: items.length,
          padding: EdgeInsets.zero,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, childAspectRatio: 1.2),
          itemBuilder: (_, i) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(items[i].$2.toString(), style: const TextStyle(color: kText, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(items[i].$1, style: const TextStyle(color: kTextSecondary, fontSize: 12), textAlign: TextAlign.center),
              ],
            );
          },
        );
      },
    );
  }

  Future<Map<String, int>> _fetchStats() async {
    final postsSnap = await FirebaseFirestore.instance.collection('posts').where('authorId', isEqualTo: userId).count().get();
    final likesReceivedSnap = await FirebaseFirestore.instance.collection('posts').where('authorId', isEqualTo: userId).get();
    int likesReceived = likesReceivedSnap.docs.fold(0, (sum, doc) => sum + (doc.data()['likes'] as int? ?? 0));
    final likesGivenSnap = await FirebaseFirestore.instance.collection('posts').where('likedBy', arrayContains: userId).count().get();
    return {
      'posts': postsSnap.count ?? 0, 
      'likesReceived': likesReceived,
      'likesGiven': likesGivenSnap.count ?? 0,
    };
  }
}

class _PostsTab extends StatelessWidget {
  final String userId;
  const _PostsTab({required this.userId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .where('authorId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (!snap.hasData || snap.data!.docs.isEmpty) return const Center(child: Text('Nenhum post encontrado.', style: TextStyle(color: kTextSecondary)));
        
        final docs = snap.data!.docs;
        return ListView.builder(
          padding: const EdgeInsets.only(top: 4),
          itemCount: docs.length,
          itemBuilder: (_, i) {
            final data = docs[i].data();
            final text = (data['text'] as String?)?.trim() ?? '';
            final likes = (data['likes'] as int?) ?? 0;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF1F1F1F),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF3A3A3A)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(text, style: const TextStyle(color: kText, fontSize: 15, height: 1.35)),
                  const SizedBox(height: 10),
                  Row(children: [
                    const Icon(Icons.favorite, size: 16, color: kAccent),
                    const SizedBox(width: 6),
                    Text('$likes', style: const TextStyle(color: Colors.white70)),
                  ]),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _ProfileDrawer extends StatelessWidget {
  const _ProfileDrawer();

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF1A1A1A),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            const ListTile(
              title: Text('Perfil', style: TextStyle(fontWeight: FontWeight.w700, color: kText)),
              subtitle: Text('Configurações da sua conta', style: TextStyle(color: Colors.white70)),
              leading: CircleAvatar(radius: 18, backgroundColor: kAccent, child: Icon(Icons.person, color: Colors.white, size: 18)),
            ),
            const Divider(),
            _tile(Icons.account_circle, 'Alterar Perfil', () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AlterarProfilePage()))),
            _tile(Icons.alternate_email, 'Alterar e-mail', () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AlterarEmailPage()))),
            _tile(Icons.lock, 'Alterar senha', () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AlterarSenhaPage()))),
            _tile(Icons.privacy_tip, 'Privacidade', () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AlterarPrivacidadePage()))),
            _tile(Icons.notifications, 'Notificações', () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AlterarNotificacoesPage()))),
            _tile(Icons.palette, 'Preferências de tema', () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AlterarTemaPage()))),
            _tile(Icons.language, 'Idioma', () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AlterarIdiomaPage()))),
            const Divider(),
            _tile(Icons.logout, 'Sair', () => _showLogoutDialog(context), danger: true),
          ],
        ),
      ),
    );
  }

  Future<void> _showLogoutDialog(BuildContext context) async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Tem certeza que deseja sair?'),
          actions: <Widget>[
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Não', style: TextStyle(color: Colors.grey))),
            TextButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (context) => const LoginPage()), (route) => false);
              },
              child: const Text('Sim', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  ListTile _tile(IconData icon, String label, VoidCallback onTap, {bool danger = false}) {
    return ListTile(
      leading: Icon(icon, color: danger ? Colors.redAccent : kAccent),
      title: Text(label, style: TextStyle(color: Colors.white, fontWeight: danger ? FontWeight.w700 : FontWeight.w400)),
      trailing: const Icon(Icons.chevron_right, color: Colors.white70),
      onTap: onTap,
    );
  }
}