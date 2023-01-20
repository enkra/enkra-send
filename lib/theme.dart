import 'package:flutter/material.dart';

class EnkraTheme {
  Color background;
  Color onBackground;
  Color primary;
  Color onPrimary;
  Color secondary;
  Color miscColor;
  Color danger;

  EnkraTheme({
    required this.background,
    required this.onBackground,
    required this.primary,
    required this.onPrimary,
    required this.secondary,
    required this.miscColor,
    required this.danger,
  });
}

var enkraTheme = EnkraTheme(
  background: const Color(0xfffefefe),
  onBackground: const Color(0xff023020),
  primary: const Color(0xff22C55E),
  onPrimary: Colors.white,
  secondary: const Color(0xffF0FDF4),
  miscColor: const Color(0xffF59E0B),
  danger: const Color(0xffff8181),
);
