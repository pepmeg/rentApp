import 'dart:convert';
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
import 'package:AppRent/provider/admin_provider.dart';
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
import 'models/user.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ru', null);
  await _createAdminIfNeeded();
  await _createSupportIfNeeded();
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
        ChangeNotifierProvider(create: (_) => AdminProvider()),
      ],
      child: MyApp(initialRoute: initialRoute),
    ),
  );
}

Future<void> _createSupportIfNeeded() async {
  final prefs = await SharedPreferences.getInstance();
  const supportEmail = 'support@rentapp.local';
  if (!prefs.containsKey('user_$supportEmail')) {
    final support = UserModel(
      id: 0,
      email: supportEmail,
      password: '',
      firstName: 'Support',
      lastName: 'Team',
      address: '',
      phoneNumber: '',
      role: 'support',
      blocked: false,
      avatarPath: 'assets/support_avatar.jpg',
    );
    await prefs.setString('user_$supportEmail', jsonEncode(support.toJson()));
  }
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
    final authProvider = context.watch<AuthProvider>();
    final isUser = authProvider.isUser;
    final navProvider = context.watch<BottomNavProvider>();
    final currentIndex = navProvider.currentIndex;

    final List<Widget> screens = [];
    screens.add(Home());
    if (isUser) {
      screens.add(Favorite());
      screens.add(AddProduct());
      screens.add(ShoppingBasket());
    }
    screens.add(ChatListScreen());
    screens.add(Profile(
      userId: navProvider.profileUserId,
      key: ValueKey('profile_${navProvider.profileUserId}'),
    ));

    final safeIndex = currentIndex.clamp(0, screens.length - 1);

    return Scaffold(
      backgroundColor: AppColors.spaceCream,
      body: IndexedStack(index: safeIndex, children: screens),
      bottomNavigationBar: BottomNavBar(
        currentIndex: safeIndex,
        onTap: (index) {
          navProvider.setIndex(index);
        },
        isUser: isUser,
      ),
    );
  }
}

Future<void> _createAdminIfNeeded() async {
  final prefs = await SharedPreferences.getInstance();
  const adminEmail = 'admin@test.com';
  if (!prefs.containsKey('user_$adminEmail')) {
    await prefs.remove('user_$adminEmail');
    final admin = UserModel(
      id: 999,
      email: adminEmail,
      password: 'admin123',
      firstName: 'Admin',
      lastName: 'Support',
      address: 'Москва',
      phoneNumber: '+79000000000',
      role: 'admin',
      blocked: false,
      avatarPath: 'assets/admin_avatar.jpg',
    );
    await prefs.setString('user_$adminEmail', jsonEncode(admin.toJson()));
  }
}