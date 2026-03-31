import 'package:flutter/material.dart';
import 'package:untitled/pages/favorite.dart';
import 'package:untitled/pages/home.dart';
import 'package:untitled/pages/person.dart';
import 'package:untitled/pages/shopping_basket.dart';
import 'package:untitled/utils/colors.dart';
import 'package:untitled/widgets/bottomNavBar.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget{
  @override
  Widget build(BuildContext context){
    return MaterialApp(
      home: MainScreen(),
      theme: ThemeData(
        primaryColor: AppColors.spaceCream
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  @override
  ScreenState createState() => ScreenState();
}

class ScreenState extends State<MainScreen> {
  int currentIndex = 0;

  final List<Widget> screens = [
    Home(),
    Favorite(),
    ShoppingBasket(),
    Profile(),
  ];

  void onTabTapped(int index) {
    setState(() {
      currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: currentIndex,
        onTap: onTabTapped,
      ),
    );
  }
}