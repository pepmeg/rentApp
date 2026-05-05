import 'package:flutter/material.dart';

class BottomNavProvider extends ChangeNotifier {
  int _currentIndex = 0;
  int? profileUserId;
  int _profileIndex = 0;

  int get currentIndex => _currentIndex;

  void setIndex(int index) {
    _currentIndex = index;
    profileUserId = null;
    notifyListeners();
  }

  void setProfileIndex(int index) {
    _profileIndex = index;
  }

  void showUserProfile(int userId) {
    profileUserId = userId;
    _currentIndex = _profileIndex;
    notifyListeners();
  }
}