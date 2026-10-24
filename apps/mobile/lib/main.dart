import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/app_tokens.dart';
import 'core/session.dart';
import 'screens/auth_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/home_screen.dart';
import 'screens/menu_screen.dart';
import 'screens/shops_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/product_screen.dart';
import 'screens/cart_screen.dart';
import 'widgets/common.dart';

void main() {
  runApp(ChangeNotifierProvider(
    create: (_) => Session(),
    child: const SimpleCoffeeApp(),
  ));
}

class SimpleCoffeeApp extends StatefulWidget {
  const SimpleCoffeeApp({super.key});
  @override
  State<SimpleCoffeeApp> createState() => _SimpleCoffeeAppState();
}

class _SimpleCoffeeAppState extends State<SimpleCoffeeApp> {
  final GlobalKey<NavigatorState> _navKey = GlobalKey<NavigatorState>(); // NEW
  int tab = 0;
  bool onboardingDone = false;

  void openProduct(MenuItem item) {
    _navKey.currentState?.push(
      MaterialPageRoute(
          builder: (_) => ProductScreen(
              item: item,
              // Из карточки: в корзину; «назад» из корзины ведёт в меню
              onAddedToCart: () {
                _navKey.currentState?.pop(); // закрыть карточку
                goCart();                    // открыть корзину поверх меню
              })),
    );
  }

  void goMenu() => setState(() => tab = 1);
  void goMenuCategory(String category) {
    final s = context.read<Session>();
    if (category.isNotEmpty) s.setCategory(category);
    setState(() => tab = 1);
  }

  // Корзина — обычный маршрут, а не вкладка: есть «назад», таб-бар остаётся под ней
  void goCart() => _navKey.currentState?.push(
        MaterialPageRoute(builder: (_) => const CartScreen()),
      );
  void goProfile() => setState(() => tab = 3);

  @override
  Widget build(BuildContext context) {
    final session = context.watch<Session>();
    return MaterialApp(
      navigatorKey: _navKey,
      title: 'Simple Coffee',
      theme: scTheme(),
      home: !session.loggedIn
          ? (onboardingDone
              ? const AuthScreen()
              : OnboardingScreen(
                  onDone: () =>
                      setState(() => onboardingDone = true)))
          : Scaffold(
              body: IndexedStack(
                index: tab,
                children: [
                  HomeScreen(
                      onOpenMenu: goMenu,
                      onOpenProduct: openProduct,
                      onOpenCategory: goMenuCategory,
                      onOpenProfile: goProfile),
                  MenuScreen(
                      onOpenProduct: openProduct,
                      onOpenCart: goCart),
                  const ShopsScreen(),
                  const ProfileScreen(),
                ],
              ),
              bottomNavigationBar: AppTabBar(
                index: tab,
                cartCount: session.cartCount,
                onTap: (i) => setState(() => tab = i),
              ),
            ),
    );
  }
}

