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
        height: 325, // aumentei para caber o resultado!
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        decoration: BoxDecoration(
          color: const Color(0xFF393939),
          borderRadius: BorderRadius.circular(29),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título
            const Padding(
              padding: EdgeInsets.only(left: 10, bottom: 14),
              child: Text(
                'Digite o Dado a ser verificado',
                style: TextStyle(
                  color: Color(0xFFA259FF),
                  fontSize: 16,
                  fontFamily: 'JetBrains Mono',
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            // Input
            Container(
              width: 337,
              height: 46,
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF242526),
                borderRadius: BorderRadius.circular(22),
              ),
              child: TextField(
                controller: controller,
                style: const TextStyle(
                  color: Color(0xFFA259FF),
                  fontSize: 15,
                  fontFamily: 'JetBrains Mono',
                  fontWeight: FontWeight.w400,
                ),
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(horizontal: 21, vertical: 13),
                  border: InputBorder.none,
                  hintText: 'Digite Aqui...',
                  hintStyle: TextStyle(
                    color: Color(0xFFA259FF),
                    fontSize: 15,
                    fontFamily: 'JetBrains Mono',
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
            // Dropdown
            Container(
              width: 337,
              height: 46,
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF242526),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x3F000000),
                    blurRadius: 4,
                    offset: Offset(0, 4),
                    spreadRadius: 0,
                  )
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 21),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedType,
                  icon: const Icon(Icons.arrow_drop_down, color: Color(0xFFA259FF)),
                  dropdownColor: const Color(0xFF242526),
                  isExpanded: true,
                  style: const TextStyle(
                    color: Color(0xFFA259FF),
                    fontSize: 18,
                    fontFamily: 'JetBrains Mono',
                    fontWeight: FontWeight.w700,
                  ),
                  items: ['Email', 'Senha', 'Telefone', 'Site'].map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                  onChanged: onDropdownChanged,
                ),
              ),
            ),
            // Botão
            Center(
              child: SizedBox(
                width: 264,
                height: 46,
                child: ElevatedButton.icon(
                  onPressed: isLoading ? null : onVerify,
                  icon: const Icon(Icons.search, color: Colors.white),
                  label: const Text(
                    'Verificar',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontFamily: 'JetBrains Mono',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFA259FF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                    elevation: 4,
                    shadowColor: const Color(0x3F000000),
                  ),
                ),
              ),
            ),
            // Resultado
            if (resultMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Center(
                  child: Text(
                    resultMessage,
                    style: const TextStyle(
                      color: Color(0xFFFAF9F6),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}