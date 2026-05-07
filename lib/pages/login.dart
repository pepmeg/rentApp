import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../pages/registration.dart';
import '../provider/chat_provider.dart';
import '../utils/colors.dart';
import '../provider/AuthProvider.dart';
import '../provider/bottom_nav_provider.dart';
import '../utils/form_fields.dart';
import '../utils/snackbar_custom.dart';

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
      context.read<BottomNavProvider>().setIndex(0);
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    } else {
      SnackBarCustom.show(context, message: error);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                    color: AppColors.oliveGray),
              ),
              SizedBox(height: 50),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Почта',
                    style: TextStyle(fontSize: 16,
                        fontWeight: FontWeight.normal,
                        color: AppColors.oliveGray),
                  ),
                ],
              ),
              SizedBox(height: 10),
              AppTextField(
                controller: emailController,
                hint: 'yourmail@shrestha.com',
                keyboardType: TextInputType.emailAddress,
              ),
              SizedBox(height: 30),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Пароль',
                    style: TextStyle(fontSize: 16,
                        fontWeight: FontWeight.normal,
                        color: AppColors.oliveGray),
                  ),
                ],
              ),
              SizedBox(height: 10),
              AppTextField(
                controller: passwordController,
                hint: '••••••••',
                maxLines: 1,
                obscure: true,
                isPassword: true,
              ),
              SizedBox(height: 70),
              Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  return ElevatedButton(
                    onPressed: authProvider.isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.copper,
                      foregroundColor: AppColors.oliveGray,
                      minimumSize: const Size(double.infinity, 48),
                      padding: const EdgeInsetsGeometry.symmetric(vertical: 5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: authProvider.isLoading
                        ? CircularProgressIndicator()
                        : Text(
                      'Войти',
                      style: TextStyle(fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.spaceCream),
                    ),
                  );
                },
              ),
              SizedBox(height: 15),
              Text(
                'Нет аккаунта?',
                style: TextStyle(fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.oliveGray),
              ),
              SizedBox(height: 15),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => Registration()));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.oliveGray,
                  foregroundColor: AppColors.oliveGray,
                  minimumSize: const Size(double.infinity, 48),
                  padding: const EdgeInsetsGeometry.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Создать аккаунт',
                  style: TextStyle(fontSize: 16,
                      fontWeight: FontWeight.normal,
                      color: AppColors.spaceCream),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}