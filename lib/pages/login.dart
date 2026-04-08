import 'package:flutter/material.dart';
import 'package:untitled/utils/colors.dart';

class Login extends StatelessWidget {
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
                  onChanged: (value) {},
                  decoration: InputDecoration(
                    hintText: 'yourmail@shrestha.com',
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
                  onChanged: (value) {},
                  decoration: InputDecoration(
                    hintText: '.........',
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
              Expanded(
                  child: ElevatedButton(
                      onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.macaroniCheese,
                      foregroundColor: AppColors.oliveGray,
                      padding: const EdgeInsetsGeometry.symmetric(horizontal: 105, vertical: 5)
                    ),
                      child: Text(
                          'Войти',
                          style: TextStyle(fontSize: 28, fontWeight: FontWeight.normal, color: AppColors.copper),
                        ),
                  )
              ),
              SizedBox(height: 15,),
              Text(
                'Нет аккаунта?',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.oliveGray),
              ),
              SizedBox(height: 15,),
              Expanded(
                  child: ElevatedButton(
                    onPressed: () {},
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