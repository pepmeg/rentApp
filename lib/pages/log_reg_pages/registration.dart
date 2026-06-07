import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../provider/AuthProvider.dart';
import '../../utils/form_fields.dart';
import '../../utils/snackbar_custom.dart';
import '../../widgets/app_button.dart';

class Registration extends StatefulWidget {
  const Registration({super.key});

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
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (!formKey.currentState!.validate()) return;
    if (passwordController.text != confirmPasswordController.text) {
      SnackBarCustom.show(context, message: 'Пароли не совпадают');
      return;
    }

    final error = await authProvider.register(
      emailController.text.trim(),
      passwordController.text.trim(),
      firstNameController.text.trim(),
      lastNameController.text.trim(),
      phone: phoneNumberController.text.trim(),
      address: addressController.text.trim(),
    );

    if (!mounted) return;
    if (error == null) {
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    } else {
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
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Регистрация',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                ),
                const SizedBox(height: 50),
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        controller: firstNameController,
                        hint: 'Имя',
                        maxLines: 1,
                        validator: (v) => v!.isEmpty ? 'Введите имя' : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: AppTextField(
                        controller: lastNameController,
                        hint: 'Фамилия',
                        maxLines: 1,
                        validator: (v) => v!.isEmpty ? 'Введите фамилию' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                AppTextField(
                  controller: phoneNumberController,
                  hint: '+79643435453',
                  maxLength: 12,
                  maxLines: 1,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d\+]')),
                  ],
                  validator: (v) => null,
                ),
                const SizedBox(height: 10),
                AppTextField(
                  controller: emailController,
                  hint: 'yourmail@shrestha.com',
                  maxLines: 1,
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
                    return Button(
                      text: 'Зарегистрироваться',
                      onPressed: authProvider.isLoading ? null : register,
                      isLoading: authProvider.isLoading,
                    );
                  },
                ),
                const SizedBox(height: 30),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Text(
                    'вернуться',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w300,
                      color: theme.colorScheme.onSurface,
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