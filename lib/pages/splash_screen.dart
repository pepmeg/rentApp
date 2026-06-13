import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/AuthProvider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.6, 1.0, curve: Curves.easeInOutBack),
      ),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _initializeApp();
      }
    });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    await Future.delayed(const Duration(milliseconds: 400));
    final navigator = Navigator.of(context);
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    if (!auth.isProfileLoaded) {
      int attempts = 0;
      while (!auth.isProfileLoaded && attempts < 50) {
        if (!mounted) return;
        await Future.delayed(const Duration(milliseconds: 100));
        attempts++;
      }
    }
    if (!mounted) return;
    final user = FirebaseAuth.instance.currentUser;
    final route = (user != null) ? '/home' : '/login';
    navigator.pushReplacementNamed(route);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Opacity(
              opacity: _fadeAnimation.value,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        color: theme.cardTheme.color ?? theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(40),
                        boxShadow: [
                          BoxShadow(
                            color: theme.primaryColor.withOpacity(0.2),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Image.asset(
                          'assets/logo.png',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              Icon(Icons.handyman, size: 80, color: theme.primaryColor),
                        ),
                      ),
                    ),
                    const SizedBox(height: 100),
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _pulseAnimation.value,
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: theme.primaryColor.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}