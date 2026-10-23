// Категории меню: стабильный slug + человекочитаемый заголовок.
//
// Заголовки бэка нельзя использовать как ключ фильтра: в сиде категория
// кофе называется «Кофе и напитки», а на главной экрана плитка — «Кофе».
// Ключом всегда служит slug (`coffee`), он же приходит из `GET /v1/menu`.

/// Порядок категорий в меню (как в сиде, но «Кофе» первым).
/// Категории вне списка уходят в конец, сохраняя порядок из меню.
const List<String> kCategoryOrder = <String>[
  'coffee',
  'tea',
  'dessert',
  'bakery',
  'kitchen',
  'breakfast',
  'novinki',
];

/// Резервные заголовки для слогов, которых нет в [kCategorySlugs].
/// Нужен на случай, если бэк отдаст категорию без slug.
const Map<String, String> kCategoryTitles = <String, String>{
  'novinki': 'Новинки',
  'coffee': 'Кофе и напитки',
  'tea': 'Чай',
  'dessert': 'Десерты',
  'bakery': 'Выпечка',
  'kitchen': 'Наша кухня',
  'breakfast': 'Завтраки',
};

/// Известные заголовки бэка -> slug.
/// Нужен для обратной совместимости и для моков, где slug нет.
const Map<String, String> kCategorySlugByTitle = <String, String>{
  'кофе': 'coffee',
  'кофе и напитки': 'coffee',
  'напитки': 'coffee',
  'чай': 'tea',
  'чаи': 'tea',
  'десерты': 'dessert',
  'выпечка': 'bakery',
  'наша кухня': 'kitchen',
  'кухня': 'kitchen',
  'завтраки': 'breakfast',
  'новинки': 'novinki',
};

/// Приводит заголовок к slug: Trim + lowerCase + замена пробелов на дефис.
String slugifyTitle(String title) {
  final t = title.trim().toLowerCase();
  if (t.isEmpty) return '';
  return t.replaceAll(RegExp(r'[\s_]+'), '-');
}

/// Определяет slug категории по заголовку.
/// Сначала пробуем таблицу известных заголовков, затем — slugify.
String categorySlugFromTitle(String title) {
  final key = title.trim().toLowerCase();
  if (key.isEmpty) return '';
  return kCategorySlugByTitle[key] ?? slugifyTitle(key);
}

/// Человекочитаемый заголовок для slug (для чипов категорий).
String categoryTitleForSlug(String slug) {
  if (slug.isEmpty) return '';
  return kCategoryTitles[slug] ?? slug;
}

/// Сортирует слаги категорий по [kCategoryOrder]; неизвестные — в конец,
/// в исходном взаимном порядке.
List<String> sortCategorySlugs(List<String> slugs) {
  final known = <String>[];
  final unknown = <String>[];
  for (final s in slugs) {
    if (kCategoryOrder.contains(s)) {
      if (!known.contains(s)) known.add(s);
    } else if (!unknown.contains(s)) {
      unknown.add(s);
    }
  }
  known.sort((a, b) => kCategoryOrder.indexOf(a).compareTo(kCategoryOrder.indexOf(b)));
  return [...known, ...unknown];
}
