import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:untitled/utils/colors.dart';
import 'package:untitled/models/product.dart';
import 'package:untitled/data/product_data.dart';

class AddProduct extends StatefulWidget {
  const AddProduct({super.key});

  @override
  State<AddProduct> createState() => _AddProductState();
}

class _AddProductState extends State<AddProduct> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController categoryController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController daysController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final List<String> _imagePaths = [];

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _imagePaths.add(picked.path);
      });
    }
  }

  void _addProduct() {
    final name = nameController.text.trim();
    final price = int.tryParse(priceController.text.trim());
    if (name.isEmpty || price == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите название и цену')),
      );
      return;
    }

    final newProduct = Product(
      id: DateTime.now().millisecondsSinceEpoch,
      name: name,
      price: price,
      location: locationController.text.trim().isEmpty
          ? 'Не указано'
          : locationController.text.trim(),
      images: _imagePaths,
    );

    ProductData.addProduct(newProduct);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Товар добавлен')),
    );

    nameController.clear();
    categoryController.clear();
    priceController.clear();
    daysController.clear();
    locationController.clear();
    descriptionController.clear();
    setState(() {
      _imagePaths.clear();
    });
  }

  @override
  void dispose() {
    nameController.dispose();
    categoryController.dispose();
    priceController.dispose();
    daysController.dispose();
    locationController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.only(left: 20, right: 20, top: 40),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Добавить товар',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.oliveGray),
              ),
              const SizedBox(height: 15),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _imagePaths.length + 1,
                  itemBuilder: (context, index) {
                    if (index == _imagePaths.length) {
                      return GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          height: 100,
                          width: 100,
                          margin: const EdgeInsets.only(right: 10),
                          decoration: BoxDecoration(
                            color: AppColors.whiteAntique,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: const Icon(Icons.add_a_photo,
                              color: AppColors.oliveGray),
                        ),
                      );
                    }
                    return GestureDetector(
                      onTap: () async {
                        final picker = ImagePicker();
                        final picked =
                        await picker.pickImage(source: ImageSource.gallery);
                        if (picked != null) {
                          setState(() {
                            _imagePaths[index] = picked.path;
                          });
                        }
                      },
                      child: Container(
                        height: 100,
                        width: 100,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          image: DecorationImage(
                            image: FileImage(File(_imagePaths[index])),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              _buildField(nameController, 'Название товара'),
              const SizedBox(height: 10),
              _buildField(categoryController, 'Категория'),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _buildField(priceController, '500 ₽')),
                  const SizedBox(width: 10),
                  Expanded(child: _buildField(daysController, 'Срок аренды (дни)')),
                ],
              ),
              const SizedBox(height: 10),
              _buildField(locationController, 'Город, район'),
              const SizedBox(height: 10),
              _buildField(descriptionController,
                  'Опишите товар, его состояние и условия аренды...'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _addProduct,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.copper,
                  foregroundColor: AppColors.spaceCream,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                ),
                child: const Text(
                  'Создать',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
      style: const TextStyle(fontSize: 16, color: AppColors.oliveGray),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
            color: AppColors.oliveGray.withOpacity(0.5), fontSize: 16),
        filled: true,
        fillColor: AppColors.whiteAntique,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.grey, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide:
          const BorderSide(color: AppColors.oliveGray, width: 2),
        ),
        contentPadding:
        const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      ),
    );
  }
}