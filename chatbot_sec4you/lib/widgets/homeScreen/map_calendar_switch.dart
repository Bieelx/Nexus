import 'package:flutter/material.dart';

class MapCalendarSwitch extends StatelessWidget {
  final bool isMapSelected;
  final Function(bool) onChanged;

  const MapCalendarSwitch({
    super.key,
    required this.isMapSelected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Cores do design
    const bgColor = Color(0xB2393939);
    const selectedColor = Color(0xFF242526);
    const labelColor = Color(0xFFD9D9D9);
    const selectedLabel = Color(0xFFA259FF);

    return Container(
      width: 145,
      height: 45.16,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          // Rotina/Calendário
          Expanded(
            child: GestureDetector(
              onTap: () => onChanged(false),
              child: Container(
                decoration: BoxDecoration(
                  color: isMapSelected ? Colors.transparent : selectedColor,
                  borderRadius: BorderRadius.circular(24),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Calendário',
                  style: TextStyle(
                    color: isMapSelected ? labelColor : selectedLabel,
                    fontSize: 13,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
          // Mapa
          Expanded(
            child: GestureDetector(
              onTap: () => onChanged(true),
              child: Container(
                decoration: BoxDecoration(
                  color: isMapSelected ? selectedColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(24),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Mapa',
                  style: TextStyle(
                    color: isMapSelected ? selectedLabel : labelColor,
                    fontSize: 13,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}