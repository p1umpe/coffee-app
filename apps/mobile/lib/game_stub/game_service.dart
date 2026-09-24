// Задел под игру v2.0 «Лис бежит за зёрнами» (Flame).
// Сейчас — только контракт, без реализации.
// В будущем: FlameGame FoxRun + спрайты лиса, зёрна = валюта на сироп/печать.
abstract class GameService {
  Future<int> getBeansBalance();
  Future<void> grantBeans(int amount);
  Future<bool> spendBeans(int amount);
}
class GameStub implements GameService {
  int _beans = 0;
  @override
  Future<int> getBeansBalance() async => _beans;
  @override
  Future<void> grantBeans(int amount) async { _beans += amount; }
  @override
  Future<bool> spendBeans(int amount) async {
    if (_beans < amount) return false;
    _beans -= amount;
    return true;
  }
}
