import 'package:flutter_test/flutter_test.dart';
import 'package:simple_coffee_app/core/categories.dart';
import 'package:simple_coffee_app/core/session.dart';

Map<String, dynamic> _item(String title, String slug, String catTitle) => {
      'id': 'id-$title',
      'title': title,
      'description': null,
      'category': {'slug': slug, 'title': catTitle},
      'dineInPrice': 1000,
      'takeawayPrice': 1000,
      'givesStamp': true,
      'tags': <String>[],
    };

void main() {
  group('category slug resolution', () {
    test('maps known backend titles to slugs', () {
      expect(categorySlugFromTitle('Кофе и напитки'), 'coffee');
      expect(categorySlugFromTitle('Кофе'), 'coffee');
      expect(categorySlugFromTitle('Выпечка'), 'bakery');
      expect(categorySlugFromTitle('Десерты'), 'dessert');
      expect(categorySlugFromTitle('Завтраки'), 'breakfast');
      expect(categorySlugFromTitle('Наша кухня'), 'kitchen');
      expect(categorySlugFromTitle('Чай'), 'tea');
    });

    test('falls back to slugified title for unknown categories', () {
      expect(categorySlugFromTitle('Сезонное меню'), 'сезонное-меню');
      expect(categorySlugFromTitle(''), '');
    });

    test('title lookup returns the seed title for a slug', () {
      expect(categoryTitleForSlug('coffee'), 'Кофе и напитки');
      expect(categoryTitleForSlug('unknown'), 'unknown');
    });
  });

  group('MenuItem category parsing', () {
    test('reads slug and title from the API shape', () {
      final item = MenuItem.fromJson(_item('Латте', 'coffee', 'Кофе и напитки'));
      expect(item.categorySlug, 'coffee');
      expect(item.categoryTitle, 'Кофе и напитки');
    });

    test('accepts a plain string category and resolves it to a slug', () {
      final item = MenuItem.fromJson({
        ..._item('Латте', 'coffee', 'Кофе и напитки'),
        'category': 'Кофе и напитки',
      });
      expect(item.categorySlug, 'coffee');
      expect(item.categoryTitle, 'Кофе и напитки');
    });

    test('tolerates a null category', () {
      final item = MenuItem.fromJson({..._item('Латте', 'coffee', ''), 'category': null});
      expect(item.categorySlug, '');
      expect(item.categoryTitle, '');
    });
  });

  group('Session.filteredMenu', () {
    test('filters by slug, not by title', () {
      final s = Session();
      s.setMenu([
        MenuItem.fromJson(_item('Капучино', 'coffee', 'Кофе и напитки')),
        MenuItem.fromJson(_item('Круассан', 'bakery', 'Выпечка')),
      ]);

      s.setCategory('coffee');
      expect(s.filteredMenu.length, 1);
      expect(s.filteredMenu.single.title, 'Капучино');
    });

    test('the legacy title "Кофе" no longer matches the backend title', () {
      final s = Session();
      s.setMenu([MenuItem.fromJson(_item('Капучино', 'coffee', 'Кофе и напитки'))]);

      // Название из таба на главной раньше ломало фильтр.
      s.setCategory('Кофе');
      expect(s.filteredMenu, isEmpty);
    });

    test('empty category shows the whole menu', () {
      final s = Session();
      s.setMenu([
        MenuItem.fromJson(_item('Капучино', 'coffee', 'Кофе и напитки')),
        MenuItem.fromJson(_item('Круассан', 'bakery', 'Выпечка')),
      ]);

      s.setCategory('');
      expect(s.filteredMenu.length, 2);
    });

    test('exposes slugs in categories and titles in categoryTitles', () {
      final s = Session();
      s.setMenu([
        MenuItem.fromJson(_item('Круассан', 'bakery', 'Выпечка')),
        MenuItem.fromJson(_item('Капучино', 'coffee', 'Кофе и напитки')),
      ]);

      expect(s.categories, containsAll(<String>['coffee', 'bakery']));
      expect(s.categoryTitles['coffee'], 'Кофе и напитки');
      expect(s.categoryTitles['bakery'], 'Выпечка');
    });

    test('resets the active category when it disappears from the menu', () {
      final s = Session();
      s.setMenu([MenuItem.fromJson(_item('Капучино', 'coffee', 'Кофе и напитки'))]);
      s.setCategory('coffee');

      s.setMenu([MenuItem.fromJson(_item('Круассан', 'bakery', 'Выпечка'))]);
      expect(s.activeCategory, '');
      expect(s.filteredMenu.length, 1);
    });

    test('mock items use slugs and are filterable', () {
      final s = Session();
      s.setMenu(MenuItem.mock());

      s.setCategory('coffee');
      expect(s.filteredMenu.length, 3);
      expect(s.filteredMenu.every((m) => m.categorySlug == 'coffee'), isTrue);

      s.setCategory('bakery');
      expect(s.filteredMenu.length, 1);
      expect(s.filteredMenu.single.title, 'Круассан');
    });
  });

  group('sortCategorySlugs', () {
    test('orders known slugs and pushes unknown ones to the end', () {
      final sorted = sortCategorySlugs(<String>['bakery', 'coffee', 'zzz', 'tea']);
      expect(sorted.first, 'coffee');
      expect(sorted.last, 'zzz');
      expect(sorted.indexOf('coffee'), lessThan(sorted.indexOf('bakery')));
    });

    test('removes duplicates', () {
      expect(sortCategorySlugs(<String>['coffee', 'coffee', 'tea']), <String>['coffee', 'tea']);
    });
  });
}
