import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nexus_app/core/theme/app_colors.dart'; // Supondo que você tenha suas cores aqui

// Modelo de dados para o ranking
class RankingEntry {
  final String userId;
  final String userName;
  final String userInitials;
  final int totalPoints;
  final int correctAnswers;
  final String timeFormatted;
  final int timeTakenSeconds; // Para desempate

  RankingEntry({
    required this.userId,
    required this.userName,
    required this.userInitials,
    required this.totalPoints,
    required this.correctAnswers,
    required this.timeFormatted,
    required this.timeTakenSeconds,
  });

  factory RankingEntry.fromDoc(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return RankingEntry(
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Usuário',
      userInitials: data['userInitials'] ?? '??',
      totalPoints: data['totalPoints'] ?? 0,
      correctAnswers: data['correctAnswers'] ?? 0,
      timeFormatted: data['timeFormatted'] ?? '00:00',
      timeTakenSeconds: data['timeTakenSeconds'] ?? 99999,
    );
  }
}

// A Tela de Ranking
class RankingScreen extends StatefulWidget {
  const RankingScreen({super.key});

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  late Future<List<RankingEntry>> _rankingFuture;
  RankingEntry? _currentUserEntry;
  String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  int _currentUserPosition = -1;

  @override
  void initState() {
    super.initState();
    _rankingFuture = _fetchRanking();
  }

  Future<List<RankingEntry>> _fetchRanking() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('quizRanking')
        .orderBy('totalPoints', descending: true)
        .orderBy('timeTakenSeconds', descending: false) // Desempate pelo tempo (menor primeiro)
        .get();

    final entries = snapshot.docs.map((doc) => RankingEntry.fromDoc(doc)).toList();

    // Encontra a posição e os dados do usuário atual
    for (int i = 0; i < entries.length; i++) {
      if (entries[i].userId == _currentUserId) {
        setState(() {
          _currentUserEntry = entries[i];
          _currentUserPosition = i + 1; // Posição (1-indexado)
        });
        break;
      }
    }
    return entries;
  }

  @override
  Widget build(BuildContext context) {
    // Usa o mesmo gradiente do seu Container
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment(0.54, 0.51),
          end: Alignment(-0.04, 0.95),
          colors: [Color(0xFF1B202E), Color(0xFF252C3A)],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text(
            'Ranking',
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        body: FutureBuilder<List<RankingEntry>>(
          future: _rankingFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: Text('Ninguém participou ainda.', style: TextStyle(color: Colors.white)),
              );
            }
            if (snapshot.hasError) {
              return Center(
                child: Text('Erro ao carregar o ranking: ${snapshot.error}', style: const TextStyle(color: Colors.red)),
              );
            }

            final rankingList = snapshot.data!;
            final top3 = rankingList.take(3).toList();
            final others = rankingList.length > 3 ? rankingList.sublist(3) : <RankingEntry>[];

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // 1. Card "Seu Desempenho"
                  if (_currentUserEntry != null)
                    _MyPerformanceCard(
                      entry: _currentUserEntry!,
                      position: _currentUserPosition,
                    ),
                  
                  // ###################### CORREÇÃO AQUI ######################
                  //   Aumentado o espaço para "descer" o pódio
                  // ###########################################################
                  const SizedBox(height: 48), // Era 32
                  
                  // 2. Pódio (Top 3)
                  _PodiumWidget(top3: top3),
                  
                  const SizedBox(height: 32),

                  // 3. Título "Outros Participantes"
                  _DividerTitle(),
                  
                  const SizedBox(height: 16),

                  // 4. Lista do Restante (do 4º em diante)
                  ListView.builder(
                    itemCount: others.length,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (context, index) {
                      final entry = others[index];
                      final position = index + 4; // Começa do 4º lugar
                      return _RankingListItem(
                        entry: entry,
                        position: position,
                        isCurrentUser: entry.userId == _currentUserId,
                      );
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// =======================================================
// Widgets da Tela de Ranking (recriados do seu design)
// =======================================================

// 1. Card "Seu Desempenho"
class _MyPerformanceCard extends StatelessWidget {
  final RankingEntry entry;
  final int position;

  const _MyPerformanceCard({required this.entry, required this.position});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: ShapeDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF8247D3), Color(0xFF664AA3)],
        ),
        shape: RoundedRectangleBorder(
          side: const BorderSide(width: 1, color: Color(0xB2AA78C4)),
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _UserAvatar(initials: entry.userInitials, size: 63, color: const Color(0xFF936DCE)),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Seu desempenho',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontFamily: 'Poppins', fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _InfoChip(text: '$positionº Lugar'),
                      const SizedBox(width: 8),
                      _InfoChip(text: '${entry.totalPoints} pts'),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _StatBox(value: '${entry.totalPoints}', label: 'Pontos', icon: Icons.star_border),
              _StatBox(value: '${entry.correctAnswers}/10', label: 'Acertos', icon: Icons.check_circle_outline),
              _StatBox(value: entry.timeFormatted, label: 'Tempo', icon: Icons.timer_outlined),
            ],
          ),
        ],
      ),
    );
  }
}

// 2. Pódio (Top 3)
class _PodiumWidget extends StatelessWidget {
  final List<RankingEntry> top3;
  const _PodiumWidget({required this.top3});

  @override
  Widget build(BuildContext context) {
    // Garante que temos 3 entradas, mesmo que nulas, para o layout
    final podium = List<RankingEntry?>.from(top3)..addAll(List.filled(3 - top3.length, null));
    
    final entry1 = podium[0]; // 1º Lugar
    final entry2 = podium[1]; // 2º Lugar
    final entry3 = podium[2]; // 3º Lugar

    // ###################### CORREÇÃO AQUI ######################
    //   Aumentada a altura para a coroa do 1º lugar caber
    // ###########################################################
    return SizedBox(
      height: 300, // Era 250
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Pódio de 2º Lugar (Esquerda)
          if (entry2 != null)
            Positioned(
              left: 0,
              bottom: 0,
              child: _PodiumColumn(
                entry: entry2,
                height: 110,
                color: const Color(0xFF7A7583),
                borderColor: const Color(0xFFC0C0C0), // Prata
                crownColor: const Color(0xFFC0C0C0),
              ),
            ),
          
          // Pódio de 3º Lugar (Direita)
          if (entry3 != null)
            Positioned(
              right: 0,
              bottom: 0,
              child: _PodiumColumn(
                entry: entry3,
                height: 74,
                color: const Color(0xFF7F553E),
                borderColor: const Color(0xFFCD7F32), // Bronze
                crownColor: const Color(0xFFCD7F32),
              ),
            ),
            
          // Pódio de 1º Lugar (Centro)
          if (entry1 != null)
            Positioned(
              bottom: 0,
              child: _PodiumColumn(
                entry: entry1,
                height: 146,
                color: const Color(0xFF967F25),
                borderColor: const Color(0xFFFFE020), // Ouro
                isFirstPlace: true,
                crownColor: const Color(0xFFFFE020),
              ),
            ),
        ],
      ),
    );
  }
}

// Coluna individual do Pódio
class _PodiumColumn extends StatelessWidget {
  final RankingEntry entry;
  final double height;
  final Color color;
  final Color borderColor;
  final Color crownColor;
  final bool isFirstPlace;

  const _PodiumColumn({
    required this.entry,
    required this.height,
    required this.color,
    required this.borderColor,
    required this.crownColor,
    this.isFirstPlace = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 110,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Coroa
          if(isFirstPlace)
            const Icon(Icons.emoji_events, color: Color(0xFFFFE020), size: 30)
          else
            Icon(Icons.emoji_events_outlined, color: crownColor, size: 24),
            
          const SizedBox(height: 8),
          
          // Avatar
          _UserAvatar(
            initials: entry.userInitials,
            size: isFirstPlace ? 63 : 58,
            color: const Color(0xFF2D2440),
            borderColor: borderColor,
            shadowColor: isFirstPlace ? const Color(0xFFFFD700) : null,
          ),
          const SizedBox(height: 8),

          // Nome e Pontos
          Text(
            entry.userName,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'Poppins', fontWeight: FontWeight.w900),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            '${entry.totalPoints}pts',
            style: const TextStyle(color: Color(0xFFFFA500), fontSize: 10, fontFamily: 'Poppins', fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),

          // Base do pódio
          Container(
            height: height,
            width: 106,
            decoration: ShapeDecoration(
              color: color,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// 3. Divisor "Outros Participantes"
class _DividerTitle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const dividerColor = Color(0xFF9CA3AF);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        Expanded(child: Divider(color: dividerColor, thickness: 1)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'Outros Participantes',
            style: TextStyle(color: dividerColor, fontSize: 12, fontFamily: 'Poppins', fontWeight: FontWeight.w700),
          ),
        ),
        Expanded(child: Divider(color: dividerColor, thickness: 1)),
      ],
    );
  }
}

// 4. Item da Lista de Ranking (4º em diante)
class _RankingListItem extends StatelessWidget {
  final RankingEntry entry;
  final int position;
  final bool isCurrentUser;

  const _RankingListItem({
    required this.entry,
    required this.position,
    this.isCurrentUser = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: ShapeDecoration(
        color: isCurrentUser ? const Color(0x7F462976) : const Color(0x7F515767),
        shape: RoundedRectangleBorder(
          side: BorderSide(
            width: 1,
            color: isCurrentUser ? const Color(0xFF7F45CD) : const Color(0xB27884C4),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Row(
        children: [
          // Posição
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: ShapeDecoration(
              color: const Color(0xFF7C48C9),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              '$position',
              style: const TextStyle(color: Colors.white, fontSize: 22, fontFamily: 'Poppins', fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 8),
          
          // Avatar
          _UserAvatar(initials: entry.userInitials, size: 42),
          
          const SizedBox(width: 12),
          
          // Nome e Acertos
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      entry.userName,
                      style: const TextStyle(color: Color(0xFFC6C5C3), fontSize: 16, fontFamily: 'Poppins', fontWeight: FontWeight.w700),
                    ),
                    if (isCurrentUser) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: ShapeDecoration(
                          color: const Color(0xFF8447D6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        child: const Text(
                          'VOCÊ',
                          style: TextStyle(color: Colors.white, fontSize: 10, fontFamily: 'Poppins', fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  '√ ${entry.correctAnswers}/10',
                  style: const TextStyle(color: Color(0xFF43D660), fontSize: 12, fontFamily: 'Poppins', fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Pontos e Tempo
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${entry.totalPoints}pts',
                style: const TextStyle(color: Color(0xFFFFA500), fontSize: 10, fontFamily: 'Poppins', fontWeight: FontWeight.w900),
              ),
              Text(
                entry.timeFormatted,
                style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 10, fontFamily: 'Poppins', fontWeight: FontWeight.w900),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// =======================================================
// Widgets de Suporte (Reutilizáveis)
// =======================================================

class _UserAvatar extends StatelessWidget {
  final String initials;
  final double size;
  final Color color;
  final Color borderColor;
  final Color? shadowColor;

  const _UserAvatar({
    required this.initials,
    this.size = 42,
    this.color = const Color(0xFF2D2440),
    this.borderColor = const Color(0xFF7C48C9),
    this.shadowColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: ShapeDecoration(
        color: color,
        shape: RoundedRectangleBorder(
          side: BorderSide(width: 3, color: borderColor),
          borderRadius: BorderRadius.circular(size > 60 ? 16 : 8),
        ),
        shadows: shadowColor != null 
          ? [BoxShadow(color: shadowColor!, blurRadius: 25)] 
          : [],
      ),
      child: Text(
        initials,
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.4, // Tamanho da fonte proporcional
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String text;
  const _InfoChip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: ShapeDecoration(
        color: const Color(0xFF936DCE),
        shape: RoundedRectangleBorder(
          side: const BorderSide(width: 1, color: Color(0xFF8447D6)),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 14, fontFamily: 'Poppins', fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;

  const _StatBox({required this.value, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 109, // Largura fixa do design
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: ShapeDecoration(
        color: const Color(0xFF936DCE),
        shape: RoundedRectangleBorder(
          side: const BorderSide(width: 1, color: Color(0x4C8447D6)),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(color: Colors.white, fontSize: 16, fontFamily: 'Poppins', fontWeight: FontWeight.w700),
              ),
              Text(
                label,
                style: const TextStyle(color: Color(0xFFCBC0E1), fontSize: 10, fontFamily: 'Poppins'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}