import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'registration.dart';
import '../../provider/AuthProvider.dart';
import '../../utils/form_fields.dart';
import '../../utils/snackbar_custom.dart';

class Login extends StatefulWidget {
  @override
  LoginState createState() => LoginState();
}

class LoginState extends State<Login> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final error = await authProvider.login(
      emailController.text.trim(),
      passwordController.text,
    );
    if (error == null) {
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    } else {
      if (error == 'Нет подключения к интернету') {
        final cachedEmail = await SharedPreferences.getInstance().then((prefs) => prefs.getString('cached_user_email'));
        if (cachedEmail == emailController.text.trim()) {
          Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
          return;
        }
      }
      SnackBarCustom.show(context, message: error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Войдите в аккаунт',
                style: TextStyle(fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface),
              ),
              const SizedBox(height: 50),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Почта',
                    style: TextStyle(fontSize: 16,
                        fontWeight: FontWeight.normal,
                        color: theme.colorScheme.onSurface),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              AppTextField(
                controller: emailController,
                hint: 'yourmail@shrestha.com',
                keyboardType: TextInputType.emailAddress,
                maxLines: 1,
              ),
              const SizedBox(height: 30),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Пароль',
                    style: TextStyle(fontSize: 16,
                        fontWeight: FontWeight.normal,
                        color: theme.colorScheme.onSurface),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              AppTextField(
                controller: passwordController,
                hint: '••••••••',
                maxLines: 1,
                obscure: true,
                isPassword: true,
              ),
              const SizedBox(height: 70),
              Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  return ElevatedButton(
                    onPressed: authProvider.isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                      foregroundColor: theme.colorScheme.onPrimary,
                      minimumSize: const Size(double.infinity, 48),
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: authProvider.isLoading
                        ? const CircularProgressIndicator()
                        : Text(
                      'Войти',
                      style: TextStyle(fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onPrimary),
                    ),
                  );
                },
              ),
              const SizedBox(height: 15),
              Text(
                'Нет аккаунта?',
                style: TextStyle(fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface),
              ),
              const SizedBox(height: 15),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => Registration()));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  foregroundColor: theme.colorScheme.onPrimary,
                  minimumSize: const Size(double.infinity, 48),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Создать аккаунт',
                  style: TextStyle(fontSize: 16,
                      fontWeight: FontWeight.normal,
                      color: theme.colorScheme.onPrimary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}