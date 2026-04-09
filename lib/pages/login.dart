import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:untitled/pages/registration.dart';
import 'package:untitled/utils/colors.dart';
import '../provider/AuthProvider.dart';

class Login extends StatefulWidget {
  @override
  LoginState createState() => LoginState();
}

 class LoginState extends State<Login> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  void dispose(){
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.login(
      emailController.text.trim(),
      passwordController.text,
    );

    if (success) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Неверный email или пароль')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
          padding: EdgeInsetsGeometry.symmetric(horizontal: 35, vertical: 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Войдите в аккаунт',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.normal, color: AppColors.copper),
              ),
              SizedBox(height: 50,),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Почта',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: AppColors.copper),
                  ),
                ],
              ),
              SizedBox(height: 10,),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.macaroniCheese,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.copper,
                    fontWeight: FontWeight.normal,
                  ),
                  decoration: InputDecoration(
                    hintText: 'yourmail@shrestha.com',
                    hintStyle: TextStyle(
                      fontSize: 16,
                      color: AppColors.copper,
                      fontWeight: FontWeight.w100,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsetsGeometry.symmetric(vertical: 15, horizontal: 20),
                  ),
                ),
              ),
              SizedBox(height: 30,),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Пароль',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: AppColors.copper),
                  ),
                ],
              ),
              SizedBox(height: 10,),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.macaroniCheese,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: TextField(
                  controller: passwordController,
                  obscureText: true,
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.copper,
                    fontWeight: FontWeight.normal,
                  ),
                  decoration: InputDecoration(
                    hintText: '.........',
                    hintStyle: TextStyle(
                      fontSize: 16,
                      color: AppColors.copper,
                      fontWeight: FontWeight.w100,
                    ),
                    suffixIcon: IconButton(
                        onPressed: () {},
                        icon: Icon(Icons.panorama_fish_eye, size: 25, color: AppColors.copper,),
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsetsGeometry.symmetric(vertical: 15, horizontal: 20),
                  ),
                ),
              ),
              SizedBox(height: 70,),
              Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    return Expanded(
                        child: ElevatedButton(
                          onPressed: authProvider.isLoading ? null : _login,
                          style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.macaroniCheese,
                              foregroundColor: AppColors.oliveGray,
                              padding: const EdgeInsetsGeometry.symmetric(horizontal: 105, vertical: 5)
                          ),
                          child: authProvider.isLoading
                          ? CircularProgressIndicator()
                          : Text(
                            'Войти',
                            style: TextStyle(fontSize: 28, fontWeight: FontWeight.normal, color: AppColors.copper),
                          ),
                        )
                    );
                  }
              ),
              SizedBox(height: 15,),
              GestureDetector(
                onTap: (){
                  Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => Registration()),
                  );
                },
                child:
                Text(
                  'Нет аккаунта?',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.oliveGray),
                ),
              ),
              SizedBox(height: 15,),
              Expanded(
                  child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, 'register');
                      },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.copper,
                        foregroundColor: AppColors.oliveGray,
                        padding: const EdgeInsetsGeometry.symmetric(horizontal: 105, vertical: 5)
                    ),
                    child: Text(
                      'Создать аккаунт',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.normal, color: AppColors.oliveGray),
                    ),
                  )
              ),
            ],
          ),
      ),
    );
  }
}