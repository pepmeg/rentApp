class Plural {
  static String days(int n) {
    if (n % 100 >= 11 && n % 100 <= 19) return 'дней';
    if (n % 10 == 1) return 'день';
    if (n % 10 >= 2 && n % 10 <= 4) return 'дня';
    return 'дней';
  }

  static String hours(int n) {
    if (n % 100 >= 11 && n % 100 <= 19) return 'часов';
    if (n % 10 == 1) return 'час';
    if (n % 10 >= 2 && n % 10 <= 4) return 'часа';
    return 'часов';
  }
}