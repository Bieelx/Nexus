import 'package:flutter/material.dart';

class LeakVerificationCard extends StatelessWidget {
  final TextEditingController controller;
  final String selectedType;
  final void Function(String?) onDropdownChanged;
  final bool isLoading;
  final VoidCallback onVerify;
  final String resultMessage;

  const LeakVerificationCard({
    super.key,
    required this.controller,
    required this.selectedType,
    required this.onDropdownChanged,
    required this.isLoading,
    required this.onVerify,
    required this.resultMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 380,
        // Dynamic height: shrink when there's no result message
        constraints: const BoxConstraints(minHeight: 220),
        decoration: BoxDecoration(
          color: const Color(0x7F515767),
          borderRadius: BorderRadius.circular(29),
          border: Border.all(color: const Color(0xB27884C4)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              const Text(
                'Digite o dado a ser verificado',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),

              // Dropdown area
              Container(
                height: 46,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xB27884C4)),
                  color: Colors.transparent,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 21),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedType,
                    icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                    dropdownColor: const Color(0x7F515767),
                    isExpanded: true,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                    ),
                    items: ['Email', 'Senha', 'Telefone', 'Site'].map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(type),
                      );
                    }).toList(),
                    onChanged: onDropdownChanged,
                    hint: const Text(
                      'Email',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Input field
              Container(
                height: 46,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xB27884C4)),
                  color: Colors.transparent,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 21),
                child: TextField(
                  controller: controller,
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Digite aqui seu email...',
                    hintStyle: TextStyle(
                      color: Colors.white70,
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              // Result message (renders only when not empty)
              if (resultMessage.isNotEmpty) ...[
                const SizedBox(height: 14),
                Center(
                  child: Text(
                    resultMessage,
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // Verify button
              SizedBox(
                height: 46,
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isLoading ? null : onVerify,
                  icon: const Icon(Icons.search, color: Colors.white),
                  label: const Text(
                    'Verificar',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Poppins',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C52BB),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                      side: const BorderSide(color: Color(0xFFAE85E5)),
                    ),
                    elevation: 4,
                    shadowColor: const Color(0x3F000000),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}