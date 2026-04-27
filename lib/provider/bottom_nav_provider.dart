import 'package:flutter/material.dart';

class BottomNavProvider extends ChangeNotifier {
  int _currentIndex = 0;
  int? profileUserId;

  int get currentIndex => _currentIndex;

  void setIndex(int index) {
    _currentIndex = index;
    profileUserId = null;
    notifyListeners();
  }

  void showUserProfile(int userId) {
    profileUserId = userId;
    _currentIndex = 5;
    notifyListeners();
  }
}