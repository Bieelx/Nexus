import 'package:chatbot_sec4you/Screens/course_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../core/theme/app_colors.dart';

class CourseScreen extends StatefulWidget {
  final CourseContent content;

  const CourseScreen({super.key, required this.content});

  @override
  State<CourseScreen> createState() => _CourseScreenState();
}

class _CourseScreenState extends State<CourseScreen> {
  late YoutubePlayerController _controller;

@override
void initState() {
  super.initState();
  print('Initializing with Video ID: ${widget.content.videoId}'); 
  _controller = YoutubePlayerController(
    initialVideoId: widget.content.videoId,
    flags: const YoutubePlayerFlags(
      autoPlay: false,
      mute: false,
    ),
  );

  _controller.addListener(() {
    print('Player State: ${_controller.value.playerState}');
    print('Error Code: ${_controller.value.errorCode}');
  });
}

  @override
  void deactivate() {
    _controller.pause();
    super.deactivate();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return YoutubePlayerBuilder(
      player: YoutubePlayer(
        controller: _controller,
        showVideoProgressIndicator: true,
        progressIndicatorColor: AppColors.primaryPurple,
      ),
      builder: (context, player) {
        return Scaffold(
          backgroundColor: const Color(0xFF19191D),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: player,
                ),
                const SizedBox(height: 16),
                Text(
                  '${widget.content.courseTitle} > ${widget.content.moduleTitle}',
                  style: const TextStyle(
                    color: Color(0xFFD5C4F3),
                    fontSize: 14,
                    fontFamily: 'JetBrainsMono',
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Atividade 5:',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 16,
                    fontFamily: 'JetBrainsMono',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.content.activityTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.content.description,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 16,
                    height: 1.5,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 16),
                RichText(
                  text: TextSpan(
                    text: 'Ficou com alguma ',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontFamily: 'JetBrainsMono',
                    ),
                    children: [
                      TextSpan(
                        text: 'dúvida?',
                        style: const TextStyle(
                          color: Color(0xFFD5C4F3),
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        // TODO: abrir chat com Luiz
                      },
                      child: RichText(
                        text: const TextSpan(
                          text: '> Fale com o ',
                          style: TextStyle(
                            color: Color(0xFFD5C4F3),
                            fontSize: 16,
                            fontFamily: 'JetBrainsMono',
                          ),
                          children: [
                            TextSpan(
                              text: 'Luiz',
                              style: TextStyle(
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () {
                        // TODO: abrir fórum
                      },
                      child: RichText(
                        text: const TextSpan(
                          text: '> Converse no ',
                          style: TextStyle(
                            color: Color(0xFFD5C4F3),
                            fontSize: 16,
                            fontFamily: 'JetBrainsMono',
                          ),
                          children: [
                            TextSpan(
                              text: 'fórum',
                              style: TextStyle(
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF27272D),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.shield, color: Color(0xFFD5C4F3)),
                      SizedBox(width: 12),
                      Text(
                        'Firewall',
                        style: TextStyle(
                          color: Color(0xFFD5C4F3),
                          fontFamily: 'JetBrainsMono',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),
              ],
            ),
          ),
          bottomNavigationBar: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            backgroundColor: const Color(0xFF131313),
            unselectedItemColor: Colors.white.withOpacity(0.6),
            selectedItemColor: const Color(0xFF9240FE),
            currentIndex: 1,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.book_outlined),
                label: 'Cursos',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.forum_outlined),
                label: 'Fórum',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                label: 'Perfil',
              ),
            ],
          ),
        );
      },
    );
  }
}
