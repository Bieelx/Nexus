import 'package:flutter/material.dart';
import 'package:nexus_app/service/user_service.dart';

const kAccent = Color(0xFFA259FF);
const kAccentLight = Color(0xFFAE85E5);
const kAccentDark = Color(0xFF8447D6);
const kBgGradient = [Color(0xFF1B202E), Color(0xFF252C3A)];
const kCard = Color(0xFF202634);
const kCardBorder = Color(0xFF6C7691);
const kTextSecondary = Color(0xFF7D8498);
const kText = Colors.white;

class AvatarSelectionScreen extends StatefulWidget {
  final String? currentPhotoUrl;

  const AvatarSelectionScreen({Key? key, this.currentPhotoUrl}) : super(key: key);

  @override
  State<AvatarSelectionScreen> createState() => _AvatarSelectionScreenState();
}

class _AvatarSelectionScreenState extends State<AvatarSelectionScreen> {
  final List<String> _avatars = [
    'assets/Lua/icones-perfil/icone1.png',
    'assets/Lua/icones-perfil/icone2.png',
    'assets/Lua/icones-perfil/icone3.png',
    'assets/Lua/icones-perfil/icone4.png',
    'assets/Lua/icones-perfil/icone5.png',
    'assets/Lua/icones-perfil/icone6.png',
  ];

  String? _selectedAvatar;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedAvatar = widget.currentPhotoUrl;
  }

  Future<void> _saveAvatar() async {
    if (_selectedAvatar == null) return;

    setState(() => _isLoading = true);

    try {
      await UserService().updatePhotoUrl(_selectedAvatar!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Avatar atualizado com sucesso!'),
            backgroundColor: kAccent,
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao atualizar avatar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: kBgGradient,
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      const Text(
                        'Prévia',
                        style: TextStyle(
                          color: kAccentLight,
                          fontSize: 16,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildAvatarPreview(),
                      const SizedBox(height: 32),
                      const Text(
                        'Escolha seu Avatar',
                        style: TextStyle(
                          color: kAccentLight,
                          fontSize: 16,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildAvatarGrid(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: _buildSaveButton(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _CircleButton(
            icon: Icons.arrow_back,
            onTap: () => Navigator.of(context).pop(),
          ),
          const Text(
            'Selecionar Avatar',
            style: TextStyle(
              color: kAccentLight,
              fontSize: 18,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 44),
        ],
      ),
    );
  }

  Widget _buildAvatarPreview() {
    return Center(
      child: Container(
        width: 160,
        height: 160,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kAccent, width: 3),
          color: kCard,
        ),
        clipBehavior: Clip.antiAlias,
        child: _selectedAvatar != null
            ? Image.asset(
                _selectedAvatar!,
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
              )
            : const Icon(Icons.person, size: 80, color: kTextSecondary),
      ),
    );
  }

  Widget _buildAvatarGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calcula o tamanho ideal da célula baseado na largura disponível
        final double spacing = 16;
        final double availableWidth = constraints.maxWidth;
        final double cellSize = (availableWidth - (spacing * 2)) / 3;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _avatars.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: spacing,
            crossAxisSpacing: spacing,
            childAspectRatio: 1.0,
          ),
          itemBuilder: (context, index) {
            final avatar = _avatars[index];
            final isSelected = _selectedAvatar == avatar;

            return GestureDetector(
              onTap: () => setState(() => _selectedAvatar = avatar),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? kAccent : kCardBorder,
                    width: isSelected ? 3 : 1.5,
                  ),
                  color: kCard,
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: kAccent.withOpacity(0.4),
                            blurRadius: 10,
                            spreadRadius: 1,
                          )
                        ]
                      : null,
                ),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: SizedBox(
                        width: double.infinity,
                        height: double.infinity,
                        child: Image.asset(
                          avatar,
                          fit: BoxFit.cover,
                          alignment: Alignment.topCenter,
                        ),
                      ),
                    ),
                    if (isSelected)
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: kAccent,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading || _selectedAvatar == null ? null : _saveAvatar,
        style: ElevatedButton.styleFrom(
          backgroundColor: kAccent,
          disabledBackgroundColor: kCardBorder,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Text(
                'Salvar Avatar',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
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
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, color: kAccentLight, size: 22),
        ),
      ),
    );
  }
}
