import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/AuthProvider.dart';
import '../models/user.dart';
import '../widgets/profile_widget/profile_own.dart';
import '../widgets/profile_widget/profile_public.dart';

class Profile extends StatefulWidget {
  final String? userId;

  const Profile({super.key, this.userId});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  UserModel? _user;
  bool _isLoading = true;
  String? _lastUserId;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  @override
  void didUpdateWidget(Profile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.userId != _lastUserId) {
      _loadUser();
    }
  }

  Future<void> _loadUser() async {
    if (widget.userId == null) {
      setState(() {
        _user = null;
        _isLoading = false;
      });
      return;
    }
    _lastUserId = widget.userId;
    setState(() => _isLoading = true);
    final user = await context.read<AuthProvider>().getUserById(widget.userId!);
    if (mounted) {
      setState(() {
        _user = user;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    final currentUser = authProvider.currentUser;
    final theme = Theme.of(context);

    if (widget.userId == null || widget.userId == currentUser?.uid) {
      return const ProfileOwn();
    }

    if (_isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator(color: theme.primaryColor)),
      );
    }

    if (_user == null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text('Пользователь не найден'),
          automaticallyImplyLeading: true,
        ),
        body: Center(
          child: Text(
            'Данные недоступны',
            style: TextStyle(color: theme.colorScheme.onSurface),
          ),
        ),
      );
    }

    return ProfilePublic(user: _user!);
  }
}