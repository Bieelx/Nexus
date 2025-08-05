import 'package:flutter/material.dart';

class AppStyles {
  static const EdgeInsets horizontalPadding = EdgeInsets.symmetric(horizontal: 20.0);

  static BoxDecoration navBarDecoration(Color color) => BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(30.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black,
            spreadRadius: 1,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      );
}
