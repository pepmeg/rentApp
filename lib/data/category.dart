class Category {
  final String name;
  final List<String> subcategories;

  const Category({required this.name, required this.subcategories});
}

final List<Category> categories = [
  Category(
    name: 'Электроника',
    subcategories: [
      'Телефоны',
      'Аудио и видео',
      'Ноутбуки',
      'Настольные компьютеры',
      'Фототехника',
      'Планшеты',
    ],
  ),
  Category(
    name: 'Транспорт',
    subcategories: [
      'Мотоциклы и мототехника',
      'Спортивный транспорт',
      'Грузовики и спецтехника',
      'Водный транспорт',
    ],
  ),
  Category(
    name: 'Инструменты',
    subcategories: [
      'Электроинструменты',
      'Ручные инструменты',
      'Измерительные инструменты',
      'Газовое и сварочное оборудование',
    ],
  ),
  Category(
    name: 'Личные вещи',
    subcategories: [
      'Музыкальные инструменты',
      'Рыбалка',
      'Спорт и отдых',
      'Книги и журналы',
    ],
  ),
];