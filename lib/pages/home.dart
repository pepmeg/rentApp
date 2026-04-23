import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:untitled/pages/productScreen.dart';
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
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
            child: Column(
              children: [
                Container(
                  padding: EdgeInsetsGeometry.symmetric(horizontal: 10),
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
                      hintText: 'Поиск',
                      hintStyle: TextStyle(color: AppColors.oliveGray.withOpacity(0.5), fontSize: 16),
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
                          vertical: 15, horizontal: 20),
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
                      childAspectRatio: 0.84
                    ),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return ProductCard(
                        id: product.id,
                        name: product.name,
                        price: product.price,
                        location: product.location,
                        images: product.images,
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProductScreen(product: product),
                              ),
                          );
                        },
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