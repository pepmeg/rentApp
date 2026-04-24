import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:untitled/provider/AuthProvider.dart';
import '../models/user.dart';
import '../utils/colors.dart';

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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Пароли не совпадают')));
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка регистрации. Попробуйте другой email.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 35, vertical: 100),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Регистрация',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.oliveGray,
                ),
              ),
              SizedBox(height: 50),
              Row(
                children: [
                  Expanded(
                    child: buildInputField(
                      firstNameController,
                      'Имя',
                      validator: (v) => v!.isEmpty ? 'Введите имя' : null,
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: buildInputField(
                      lastNameController,
                      'Фамилия',
                      validator: (v) => v!.isEmpty ? 'Введите фамилию' : null,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
              buildInputField(
                addressController,
                'Адрес',
                validator: (v) => v!.isEmpty ? 'Введите адрес' : null,
              ),
              SizedBox(height: 10),
              buildInputField(
                phoneNumberController,
                '+79643435453',
                validator: (v) => v!.isEmpty ? 'Введите телефон' : null,
              ),
              SizedBox(height: 10),
              buildInputField(
                emailController,
                'yourmail@shrestha.com',
                validator: (v) {
                  if (v!.isEmpty) return 'Введите email';
                  if (!v.contains('@')) return 'Введите корректный email';
                  return null;
                },
              ),
              SizedBox(height: 10),
              buildInputField(
                passwordController,
                'Пароль',
                obscure: true,
                validator: (v) => v!.length < 6
                    ? 'Пароль должен быть не менее 6 символов'
                    : null,
              ),
              SizedBox(height: 10),
              buildInputField(
                confirmPasswordController,
                'Подтвердите пароль',
                obscure: true,
                validator: (v) {
                  if (v!.isEmpty) return 'Подтвердите пароль';
                  if (v != passwordController.text)
                    return 'Пароли не совпадают';
                  return null;
                },
              ),
              SizedBox(height: 30),
              Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  return ElevatedButton(
                    onPressed: authProvider.isLoading ? null : register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.copper,
                      foregroundColor: AppColors.oliveGray,
                      minimumSize: const Size(double.infinity, 48),
                      padding: const EdgeInsets.symmetric(vertical: 5,),
                    ),
                    child: authProvider.isLoading
                        ? CircularProgressIndicator()
                        : Text(
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
              SizedBox(height: 30),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Text(
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
    );
  }

  Widget buildInputField(
    TextEditingController controller,
    String hint, {
    bool obscure = false,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.whiteAntique,
        borderRadius: BorderRadius.circular(15),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        validator: validator,
        style: TextStyle(
          fontSize: 16,
          color: AppColors.oliveGray,
          fontWeight: FontWeight.normal,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            fontSize: 16,
            color: AppColors.oliveGray.withOpacity(0.5),
            fontWeight: FontWeight.normal,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        ),
      ),
    );
  }
}
