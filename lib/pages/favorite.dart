import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:untitled/data/product_data.dart';
import 'package:untitled/utils/colors.dart';
import 'package:untitled/widgets/favorite_card.dart';
import 'package:untitled/widgets/category.dart';
import '../models/product.dart';

class Favorite extends StatefulWidget {
  const Favorite({super.key});

  @override
  State<Favorite> createState() => FavoriteState();
}

class FavoriteState extends State<Favorite> {
  String searchQuery = '';

  List<Product> get filteredProducts {
    return ProductData.searchProducts(searchQuery);
  }

  @override
  Widget build(BuildContext context) {
    final products = ProductData.getAllProducts();
    final Category category = Category();
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: AppColors.lightGreen,
                borderRadius: BorderRadius.circular(30),
              ),
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    searchQuery = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Поиск...',
                  prefixIcon: Icon(Icons.search, color: AppColors.copper),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 20,
                    horizontal: 20,
                  ),
                ),
              ),
            ),
            SizedBox(height: 15),
            SizedBox(
                height: 30,
                child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount:category.items.length,
                    itemBuilder:(context, index){
                      return Padding(padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: ElevatedButton(
                          onPressed: () {},
                          child: Text(category.items[index]),
                        ),
                      );
                    }
                )
            ),
            SizedBox(height: 15,),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 1,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemBuilder: (context, index) {
                  final product = products[index];
                  return FavoriteCard(
                    name: product.name,
                    price: product.price,
                    location: product.location,
                    image: product.image,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
