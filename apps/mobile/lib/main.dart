import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'core/session.dart';
import 'screens/auth_screen.dart';
import 'screens/shops_screen.dart';
import 'screens/menu_screen.dart';
import 'screens/cart_screen.dart';
import 'screens/loyalty_screen.dart';

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
  int tab = 0;

  @override
  Widget build(BuildContext context) {
    final session = context.watch<Session>();
    final pages = [
      const MenuScreen(),
      const ShopsScreen(),
      const CartScreen(),
      const LoyaltyScreen(),
    ];
    return MaterialApp(
      title: 'Simple Coffee',
      theme: scTheme(),
      home: !session.loggedIn
          ? const AuthScreen()
          : Scaffold(
              body: IndexedStack(index: tab, children: pages),
              bottomNavigationBar: NavigationBar(
                selectedIndex: tab,
                onDestinationSelected: (i) => setState(() => tab = i),
                destinations: [
                  const NavigationDestination(icon: Icon(Icons.coffee_outlined), selectedIcon: Icon(Icons.coffee), label: 'Меню'),
                  NavigationDestination(icon: const Icon(Icons.store_outlined), selectedIcon: const Icon(Icons.store), label: 'Кофейни'),
                  NavigationDestination(
                    icon: Badge(label: Text('${session.cartCount}'), isLabelVisible: session.cartCount > 0, child: const Icon(Icons.receipt_long_outlined)),
                    label: 'Заказ',
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.card_giftcard_outlined),
                    selectedIcon: const Icon(Icons.card_giftcard),
                    label: 'Печати · ${session.stamps}/6',
                  ),
                ],
              ),
            ),
    );
  }
}
