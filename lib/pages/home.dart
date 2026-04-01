import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:untitled/utils/colors.dart';
import '../data/product_data.dart';
import '../models/product.dart';
import '../widgets/product_card.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => HomeState();
}

class HomeState extends State<Home> {
  String searcQuery = '';

  List<Product> get filteredProducts {
    return ProductData.searchProducts(searcQuery);
  }

  @override
  Widget build(BuildContext context) {

    final products = ProductData.getAllProducts();
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
                        searcQuery = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Поиск...',
                      prefixIcon: Icon(Icons.search, color: AppColors.copper,),
                      suffixIcon: IconButton(
                          icon: Icon(
                            Icons.filter_list, color: AppColors.copper,),
                          onPressed: () {
                            setState(() {
                              searcQuery = '';
                            });
                          }
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                          vertical: 20, horizontal: 20),
                    ),
                  ),
                ),
                SizedBox(height: 15),
                Expanded(
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return ProductCard(
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