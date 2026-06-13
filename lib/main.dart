import 'dart:async';
import 'package:AppRent/pages/active_leases.dart';
import 'package:AppRent/pages/add_edit_form.dart';
import 'package:AppRent/pages/admin/admin_screen.dart';
import 'package:AppRent/pages/chat_list_screen.dart';
import 'package:AppRent/pages/chat_screen.dart';
import 'package:AppRent/pages/favorite.dart';
import 'package:AppRent/pages/home.dart';
import 'package:AppRent/pages/log_reg_pages/login.dart';
import 'package:AppRent/pages/notifications.dart';
import 'package:AppRent/pages/person.dart';
import 'package:AppRent/pages/log_reg_pages/registration.dart';
import 'package:AppRent/pages/productScreen.dart';
import 'package:AppRent/pages/shopping_basket.dart';
import 'package:AppRent/pages/splash_screen.dart';
import 'package:AppRent/provider/AuthProvider.dart';
import 'package:AppRent/provider/LeaseRequestProvider.dart';
import 'package:AppRent/provider/ReviewsProvider.dart';
import 'package:AppRent/provider/activeLeasesProvider.dart';
import 'package:AppRent/provider/admin_provider.dart';
import 'package:AppRent/provider/archived_leases_provider.dart';
import 'package:AppRent/provider/basket_provider.dart';
import 'package:AppRent/provider/bottom_nav_provider.dart';
import 'package:AppRent/provider/chat_provider.dart';
import 'package:AppRent/provider/favorite_provider.dart';
import 'package:AppRent/provider/theme_provider.dart';
import 'package:AppRent/services/brand_service.dart';
import 'package:AppRent/services/category_service.dart';
import 'package:AppRent/services/connectivityService.dart';
import 'package:AppRent/services/github_update_service.dart';
import 'package:AppRent/services/product_service.dart';
import 'package:AppRent/services/secure_storage_service.dart';
import 'package:AppRent/theme/theme_data.dart';
import 'package:AppRent/widgets/bottomNavBar.dart';
import 'package:AppRent/services/notification_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'models/product.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await SecureStorageService().init();
  tz_data.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Europe/Moscow'));
  await NotificationService().init();
  await initializeDateFormatting('ru', null);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthProvider()),
        ChangeNotifierProvider(create: (context) => FavoriteProvider()),
        ChangeNotifierProvider(create: (context) => BasketProvider()),
        ChangeNotifierProvider(create: (context) => ActiveLeasesProvider()),
        ChangeNotifierProvider(create: (context) => BottomNavProvider()),
        ChangeNotifierProvider(create: (_) => LeaseRequestProvider()),
        ChangeNotifierProvider(create: (_) => ArchivedLeasesProvider()),
        ChangeNotifierProvider(create: (_) => ReviewsProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
        ChangeNotifierProvider(create: (_) => CategoryService()),
        ChangeNotifierProvider(create: (_) => BrandService()),
        ChangeNotifierProvider(create: (_) => ConnectivityService()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: MyApp(initialRoute: '/splash'),
    ),
  );
}

final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

class MyApp extends StatelessWidget {
  final String initialRoute;

  const MyApp({required this.initialRoute, super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return MaterialApp(
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      navigatorObservers: [routeObserver],
      navigatorKey: navigatorKey,
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/login': (context) => Login(),
        '/register': (context) => Registration(),
        '/home': (context) => MainScreen(),
        '/chat': (context) {
          final chatId = ModalRoute.of(context)!.settings.arguments as String;
          final chatProvider = context.read<ChatProvider>();
          final chat = chatProvider.getChatById(chatId);
          if (chat != null) {
            return ChatScreen(chat: chat);
          }
          return const MainScreen();
        },
        '/notifications': (context) => const NotificationsScreen(),
        '/active_leases': (context) => const ActiveLeases(),
        '/cart': (context) => const ShoppingBasket(),
        '/product': (context) {
          final productId = ModalRoute.of(context)!.settings.arguments as String;
          return FutureBuilder<Product?>(
            future: ProductService.getProductById(productId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }
              if (snapshot.hasData && snapshot.data != null) {
                return ProductScreen(product: snapshot.data!);
              }
              return const Scaffold(body: Center(child: Text('Товар не найден')));
            },
          );
        },
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  String? _lastUserId;
  StreamSubscription<QuerySnapshot>? _requestsSubscription;
  StreamSubscription<QuerySnapshot>? _myRequestsSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoryService>().startListening();
      context.read<BrandService>().startListening();
    });
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        GitHubUpdateService.checkForUpdate(context);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _requestsSubscription?.cancel();
    _myRequestsSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = context.read<AuthProvider>();
    final currentUserId = auth.currentUser?.uid;
    final connectivity = context.watch<ConnectivityService>();
    if (connectivity.hasInternet) {
      context.read<AuthProvider>().syncUserProfile();
    }
    if (_lastUserId != currentUserId || _lastUserId == null) {
      if (_lastUserId != null) {
        context.read<ChatProvider>().cancelChatsSubscription();
        context.read<ChatProvider>().cancelAllChatsSubscription();
        context.read<LeaseRequestProvider>().stopListening();
        context.read<BasketProvider>().stopListening();
        context.read<ActiveLeasesProvider>().stopListening();
        context.read<ArchivedLeasesProvider>().stopListening();
        context.read<AdminProvider>().stopListening();
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        NotificationService().cancelAllNotifications();
        if (currentUserId != null) {
          final chatProvider = context.read<ChatProvider>();
          chatProvider.clearMissedNotifications();
          chatProvider.notifyMissedMessages(currentUserId);
          chatProvider.listenForNewMessages(currentUserId);
          final leaseRequestProvider = context.read<LeaseRequestProvider>();
          leaseRequestProvider.listenForUser(currentUserId);
          final basketProvider = context.read<BasketProvider>();
          basketProvider.listenForUser(currentUserId);
        }
        context.read<BottomNavProvider>().setIndex(0);
      });
      _lastUserId = currentUserId;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isUser = authProvider.isUser;
    final isModerator = authProvider.isAdmin || authProvider.isSupport;
    final navProvider = context.watch<BottomNavProvider>();
    final currentIndex = navProvider.currentIndex;

    final requestsCount = context.watch<LeaseRequestProvider>()
        .getIncomingRequests(authProvider.currentUser?.uid ?? '')
        .length;

    final isBlocked = authProvider.currentUser?.blocked == true;
    final List<Widget> screens = [
      const Home(),
      if (isUser && !isBlocked) const Favorite(),
      if (isUser && !isBlocked) const ProductForm(),
      if (isUser && !isBlocked) const ShoppingBasket(),
      const ChatListScreen(),
      Profile(
        userId: navProvider.profileUserId,
        key: ValueKey('profile_${navProvider.profileUserId}'),
      ),
    ];

    final int profileIndex = screens.length - 1;
    navProvider.setProfileIndex(profileIndex);

    if (isModerator) {
      screens.add(const AdminScreen());
    }

    final safeIndex = currentIndex.clamp(0, screens.length - 1);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: IndexedStack(index: safeIndex, children: screens),
      bottomNavigationBar: BottomNavBar(
        currentIndex: safeIndex,
        onTap: (index) {
          if (index < screens.length) {
            navProvider.setIndex(index);
          }
        },
        isUser: isUser,
        isModerator: isModerator,
        itemCount: screens.length,
        requestsCount: requestsCount,
        isBlocked: isBlocked,
      ),
    );
  }
}