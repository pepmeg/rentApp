import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:untitled/pages/login.dart';
import 'package:untitled/pages/registration.dart';
import 'package:untitled/provider/AuthProvider.dart';
import 'package:untitled/pages/add_product.dart';
import 'package:untitled/pages/favorite.dart';
import 'package:untitled/pages/home.dart';
import 'package:untitled/pages/person.dart';
import 'package:untitled/pages/shopping_basket.dart';
import 'package:untitled/utils/colors.dart';
import 'package:untitled/widgets/bottomNavBar.dart';

void main() {
  runApp(
      ChangeNotifierProvider(
        create: (context) => AuthProvider(),
        child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget{
  @override
  Widget build(BuildContext context){
    return MaterialApp(
      initialRoute: '/login',
      routes: {
        '/login': (context) => Login(),
        '/register': (context) => Registration(),
        '/home': (context) => MainScreen(),
      },
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.spaceCream,
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
    Add_Product(),
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
      backgroundColor: AppColors.spaceCream,
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