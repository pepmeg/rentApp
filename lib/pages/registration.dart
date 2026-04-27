import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:untitled/provider/AuthProvider.dart';
import '../models/user.dart';
import '../utils/colors.dart';
import '../utils/form_fields.dart';
import '../utils/snackbar_custom.dart';

class Registration extends StatefulWidget {
  @override
  RegistrationState createState() => RegistrationState();
}

class RegistrationState extends State<Registration> {
  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final addressController = TextEditingController();
  final phoneNumberController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    firstNameController.dispose();
    lastNameController.dispose();
    addressController.dispose();
    phoneNumberController.dispose();
    super.dispose();
  }

  Future<void> register() async {
    if (!formKey.currentState!.validate()) return;

    if (passwordController.text != confirmPasswordController.text) {
      SnackBarCustom.show(context, message: 'Пароли не совпадают');
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final newUser = UserModel(
      id: DateTime.now().millisecondsSinceEpoch,
      email: emailController.text.trim(),
      password: passwordController.text.trim(),
      firstName: firstNameController.text.trim(),
      lastName: lastNameController.text.trim(),
      address: addressController.text.trim(),
      phoneNumber: phoneNumberController.text.trim(),
    );

    final success = await authProvider.register(newUser);
    if (success) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      SnackBarCustom.show(context, message: 'Ошибка регистрации. Попробуйте другой email.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 40),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'Регистрация',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.oliveGray),
                ),
                const SizedBox(height: 50),
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        controller: firstNameController,
                        hint: 'Имя',
                        validator: (v) => v!.isEmpty ? 'Введите имя' : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: AppTextField(
                        controller: lastNameController,
                        hint: 'Фамилия',
                        validator: (v) => v!.isEmpty ? 'Введите фамилию' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                AppTextField(
                  controller: addressController,
                  hint: 'Регион, город',
                ),
                const SizedBox(height: 10),
                AppTextField(
                  controller: phoneNumberController,
                  hint: '+79643435453',
                  validator: (v) => v!.isEmpty ? 'Введите телефон' : null,
                ),
                const SizedBox(height: 10),
                AppTextField(
                  controller: emailController,
                  hint: 'yourmail@shrestha.com',
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v!.isEmpty) return 'Введите email';
                    if (!v.contains('@')) return 'Введите корректный email';
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                AppTextField(
                  controller: passwordController,
                  hint: 'Пароль',
                  maxLines: 1,
                  obscure: true,
                  validator: (v) =>
                  v!.length < 6 ? 'Пароль должен быть не менее 6 символов' : null,
                ),
                const SizedBox(height: 10),
                AppTextField(
                  controller: confirmPasswordController,
                  hint: 'Подтвердите пароль',
                  maxLines: 1,
                  obscure: true,
                  validator: (v) {
                    if (v!.isEmpty) return 'Подтвердите пароль';
                    if (v != passwordController.text) return 'Пароли не совпадают';
                    return null;
                  },
                ),
                const SizedBox(height: 30),
                Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    return ElevatedButton(
                      onPressed: authProvider.isLoading ? null : register,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.copper,
                        foregroundColor: AppColors.oliveGray,
                        minimumSize: const Size(double.infinity, 48),
                        padding: const EdgeInsets.symmetric(vertical: 5),
                      ),
                      child: authProvider.isLoading
                          ? CircularProgressIndicator()
                          : const Text(
                        'Зарегистрироваться',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.spaceCream,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 30),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Text(
                    'вернуться',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w300,
                      color: AppColors.oliveGray,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}