import 'package:flutter/cupertino.dart';

class BottomNavProvider extends ChangeNotifier {
  int _currentIndex = 0;
  String? profileUserId;
  int _profileIndex = 0;
  int _homeRefreshCounter = 0;

  int get currentIndex => _currentIndex;
  int get homeRefreshCounter => _homeRefreshCounter;

  void setIndex(int index) {
    _currentIndex = index;
    profileUserId = null;
    notifyListeners();
  }

  void setProfileIndex(int index) {
    _profileIndex = index;
  }

  void showUserProfile(String userId) {
    profileUserId = userId;
    _currentIndex = _profileIndex;
    notifyListeners();
  }

  void incrementHomeRefreshCounter() {
    _homeRefreshCounter++;
    notifyListeners();
  }
}