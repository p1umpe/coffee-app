// Токены из docs/design/simple-coffee-design-spec.md, раздел 2.
// Без google_fonts (пакет не ставится офлайн): serif = Georgia, sans = системный.
import 'package:flutter/material.dart';

class SCColors {
  static const cream = Color(0xFFF7F0E6); // фон экранов
  static const milk = Color(0xFFFFFBF5); // карточки, чипы, таб-бар
  static const espresso = Color(0xFF2B1D14); // текст, тёмная карта, активные элементы
  static const caramel = Color(0xFFC8843B); // аватар, начало градиента
  static const fox = Color(0xFFE2622B); // главный акцент
  static const line = Color(0xFFE8DBCB); // границы 1px
  static const muted = Color(0xFF8A7766); // вторичный текст
  static const placeholder = Color(0xFFEBD9C1); // фон под фото
  static const foxTint = Color(0xFFFFF1EA); // фон выбранного размера
  static const okText = Color(0xFF5F7A4F);
  static const okBg = Color(0xFFE6EFDC);
  static const mapBg = Color(0xFFE6D8C4);
  static const mapGrid = Color(0xFFD9C8B0);
  // Алиасы для старого кода:
  static const secondary = muted;
  static const card = milk;
  static const matcha = okText;
}

class SCRadii {
  static const double loyaltyCard = 22;
  static const double banner = 20;
  static const double productCard = 20;
  static const double shopCard = 18;
  static const double map = 24;
  static const double hero = 26;
  static const double thumb = 16;
  static const double chip = 14;
  static const double cta = 20;
  static const double seg = 16;
  static const double segInner = 12;
}

/// Заголовки с засечками (по спеке Playfair Display; без пакета — Georgia).
TextStyle serif(double size, {FontWeight w = FontWeight.w700, Color c = SCColors.espresso}) =>
    TextStyle(fontFamily: 'Georgia', fontSize: size, fontWeight: w, color: c, height: 1.15);

/// Основной текст (по спеке Manrope; без пакета — системный).
TextStyle sans(double size, {FontWeight w = FontWeight.w400, Color c = SCColors.espresso}) =>
    TextStyle(fontSize: size, fontWeight: w, color: c);

ThemeData scTheme() {
  final base = ThemeData(useMaterial3: true, scaffoldBackgroundColor: SCColors.cream);
  return base.copyWith(
    colorScheme: ColorScheme.fromSeed(seedColor: SCColors.fox).copyWith(surface: SCColors.cream),
    scaffoldBackgroundColor: SCColors.cream,
    appBarTheme: const AppBarTheme(
      backgroundColor: SCColors.cream, foregroundColor: SCColors.espresso,
      elevation: 0, scrolledUnderElevation: 0,
    ),
    cardTheme: CardThemeData(
      color: SCColors.milk, elevation: 0, margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(SCRadii.productCard),
        side: const BorderSide(color: SCColors.line),
      ),
    ),
  );
}

/// DINE_IN = в кружке (базовая цена + печать), TAKEAWAY = с собой (дешевле, без печатей).
enum Fulfillment { dineIn, takeaway }

extension FulfillmentX on Fulfillment {
  String get api => this == Fulfillment.dineIn ? 'DINE_IN' : 'TAKEAWAY';
}

String rub(int kopeks) =>
    '${(kopeks / 100).toStringAsFixed(kopeks % 100 == 0 ? 0 : 2)} ₽';

String greetingByHour(DateTime t) {
  final h = t.hour;
  if (h >= 5 && h < 12) return 'Доброе утро';
  if (h >= 12 && h < 18) return 'Добрый день';
  return 'Добрый вечер';
}
