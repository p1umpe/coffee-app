// Simple Coffee Design Tokens (из docs/04-DESIGN.md)
import 'package:flutter/material.dart';

class SCColors {
  static const cream = Color(0xFFFAF6F0);
  static const espresso = Color(0xFF2B211C);
  static const secondary = Color(0xFF6F5B4D);
  static const caramel = Color(0xFFC67C3B);
  static const fox = Color(0xFFE86A2C);
  static const matcha = Color(0xFF7A9B6D);
  static const line = Color(0xFFEDE6DC);
  static const card = Colors.white;
}

/// DINE_IN = в кружке (базовая цена + печать), TAKEAWAY = с собой (дешевле, без печатей)
enum Fulfillment { dineIn, takeaway }

extension FulfillmentX on Fulfillment {
  String get api => this == Fulfillment.dineIn ? 'DINE_IN' : 'TAKEAWAY';
  String get label => this == Fulfillment.dineIn ? 'В кружке 🍵' : 'С собой 🥤';
  String get hint => this == Fulfillment.dineIn
      ? '+ печать за каждый кофе'
      : 'дешевле, но без печатей';
}

String rub(int kopeks) => '${(kopeks / 100).toStringAsFixed(kopeks % 100 == 0 ? 0 : 2)} ₽';

ThemeData scTheme() {
  final scheme = ColorScheme.fromSeed(seedColor: SCColors.caramel).copyWith(
    surface: SCColors.cream,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: SCColors.cream,
    appBarTheme: const AppBarTheme(
      backgroundColor: SCColors.cream,
      foregroundColor: SCColors.espresso,
      elevation: 0,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: SCColors.caramel,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    cardTheme: CardThemeData(
      color: SCColors.card,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: SCColors.line),
      ),
    ),
    chipTheme: const ChipThemeData(
      shape: StadiumBorder(side: BorderSide(color: SCColors.line)),
    ),
  );
}
