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
import 'package:untitled/provider/LeaseRequestProvider.dart';
import 'package:untitled/provider/ReviewsProvider.dart';
import 'package:untitled/provider/activeLeasesProvider.dart';
import 'package:untitled/provider/basket_provider.dart';
import 'package:untitled/provider/bottom_nav_provider.dart';
import 'package:untitled/provider/favorite_provider.dart';
import 'package:untitled/utils/colors.dart';
import 'package:untitled/widgets/bottomNavBar.dart';

import 'data/product_data.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ProductData.loadFromPrefs();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthProvider()),
        ChangeNotifierProvider(create: (context) => FavoriteProvider()),
        ChangeNotifierProvider(create: (context) => BasketProvider()),
        ChangeNotifierProvider(create: (context) => ActiveLeasesProvider()),
        ChangeNotifierProvider(create: (context) => BottomNavProvider()),
        ChangeNotifierProvider(create: (_) => LeaseRequestProvider()),
        ChangeNotifierProvider(create: (_) => ReviewsProvider()),
      ],
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

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final navProvider = context.watch<BottomNavProvider>();
    final currentIndex = navProvider.currentIndex;

    return Scaffold(
      backgroundColor: AppColors.spaceCream,
      body: IndexedStack(
        index: currentIndex,
        children: [
          Home(),
          Favorite(),
          AddProduct(),
          ShoppingBasket(),
          Profile(),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: currentIndex,
        onTap: (index) {
          navProvider.setIndex(index);
        },
      ),
    );
  }
}