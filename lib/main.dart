import 'package:AppRent/pages/add_product.dart';
import 'package:AppRent/pages/chat_list_screen.dart';
import 'package:AppRent/pages/favorite.dart';
import 'package:AppRent/pages/home.dart';
import 'package:AppRent/pages/login.dart';
import 'package:AppRent/pages/person.dart';
import 'package:AppRent/pages/registration.dart';
import 'package:AppRent/pages/shopping_basket.dart';
import 'package:AppRent/pages/splash_screen.dart';
import 'package:AppRent/provider/AuthProvider.dart';
import 'package:AppRent/provider/LeaseRequestProvider.dart';
import 'package:AppRent/provider/ReviewsProvider.dart';
import 'package:AppRent/provider/activeLeasesProvider.dart';
import 'package:AppRent/provider/basket_provider.dart';
import 'package:AppRent/provider/bottom_nav_provider.dart';
import 'package:AppRent/provider/chat_provider.dart';
import 'package:AppRent/provider/favorite_provider.dart';
import 'package:AppRent/utils/colors.dart';
import 'package:AppRent/widgets/bottomNavBar.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ru', null);

  final prefs = await SharedPreferences.getInstance();
  final currentUserEmail = prefs.getString('current_user_email');
  final initialRoute = (currentUserEmail != null && currentUserEmail.isNotEmpty)
      ? '/home'
      : '/login';

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
        ChangeNotifierProvider(create: (_) => ChatProvider()),
      ],
      child: MyApp(initialRoute: initialRoute),
    ),
  );
}

class MyApp extends StatelessWidget {
  final String initialRoute;

  const MyApp({required this.initialRoute, super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
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
          ChatListScreen(),
          Profile(userId: navProvider.profileUserId, key: ValueKey('profile_${navProvider.profileUserId}')),
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