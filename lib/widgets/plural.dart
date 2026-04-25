class Plural {
  static String days(int count) {
    if (count % 100 >= 11 && count % 100 <= 19) return 'дней';
    switch (count % 10) {
      case 1:
        return 'день';
      case 2:
      case 3:
      case 4:
        return 'дня';
      default:
        return 'дней';
    }
  }
}