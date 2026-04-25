import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:untitled/utils/colors.dart';
import 'package:untitled/models/product.dart';
import 'package:untitled/data/product_data.dart';
import '../data/category.dart';
import '../provider/AuthProvider.dart';
import '../utils/form_fields.dart';
import '../utils/snackbar_custom.dart';

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
  final TextEditingController brandController = TextEditingController();
  final List<String> _imagePaths = [];
  final _formKey = GlobalKey<FormState>();

  String? _selectedCategory;
  String? _selectedSubcategory;
  bool _categoryError = false;
  bool _subcategoryError = false;

  static const int maxImages = 10;

  Future<String> _saveImagePermanently(String sourcePath) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final appDir = Directory('${directory.path}/product_images');
      if (!await appDir.exists()) {
        await appDir.create(recursive: true);
      }
      final fileName = 'product_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedImage = File('${appDir.path}/$fileName');
      await File(sourcePath).copy(savedImage.path);
      return savedImage.path;
    } catch (e) {
      print('Ошибка сохранения изображения: $e');
      return sourcePath;
    }
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage();

    if (pickedFiles == null || pickedFiles.isEmpty) return;

    final remaining = maxImages - _imagePaths.length;
    if (remaining <= 0) {
      SnackBarCustom.show(context, message: 'Достигнут лимит в 10 фотографий');
      return;
    }

    final filesToAdd = pickedFiles.take(remaining);
    int added = 0;
    for (final file in filesToAdd) {
      final permanentPath = await _saveImagePermanently(file.path);
      _imagePaths.add(permanentPath);
      added++;
    }

    setState(() {});

    if (added < pickedFiles.length) {
      SnackBarCustom.show(context, message: 'Добавлено $added из ${pickedFiles.length}. Лимит 10 фото.');
    }
  }

  Future<void> _replaceImage(int index) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final permanentPath = await _saveImagePermanently(picked.path);
      setState(() {
        _imagePaths[index] = permanentPath;
      });
    }
  }

  void _addProduct() {
    final authProvider = context.read<AuthProvider>();
    final currentUser = authProvider.currentUser;

    if (currentUser == null) {
      SnackBarCustom.show(context, message: 'Пользователь не авторизован');
      return;
    }

    setState(() {
      _categoryError = false;
      _subcategoryError = false;
    });

    final formValid = _formKey.currentState!.validate();

    final catError = (_selectedCategory == null || _selectedCategory!.isEmpty);
    final subError = (_selectedSubcategory == null || _selectedSubcategory!.isEmpty);
    if (catError || subError) {
      setState(() {
        _categoryError = catError;
        _subcategoryError = subError;
      });
    }

    if (!formValid || catError || subError) {
      final List<String> messages = [];
      if (!formValid) messages.add('Поля заполнены неверно');
      if (catError) messages.add('Выберите категорию');
      if (subError) messages.add('Выберите подкатегорию');
      SnackBarCustom.show(context, message: messages.join('\n'));
      return;
    }

    final name = nameController.text.trim();
    final price = int.tryParse(priceController.text.trim());
    if (name.isEmpty || price == null) {
      return;
    }

    String location = locationController.text.trim();
    if (location.isEmpty) {
      if (currentUser.address != null && currentUser.address!.isNotEmpty) {
        location = currentUser.address!;
      } else {
        SnackBarCustom.show(
          context,
          message: 'Укажите город/район или заполните адрес в профиле',
        );
        return;
      }
    }

    final newProduct = Product(
      id: DateTime.now().millisecondsSinceEpoch,
      ownerId: currentUser.id,
      name: name,
      price: price!,
      location: locationController.text.trim().isEmpty
          ? 'Не указано'
          : locationController.text.trim(),
      images: List<String>.from(_imagePaths),
      category: _selectedCategory ?? '',
      subcategory: _selectedSubcategory ?? '',
      description: descriptionController.text.trim(),
      brand: brandController.text.trim(),
      minRentDays: int.tryParse(daysController.text.trim()) ?? 1,
      createdAt: DateTime.now(),
    );

    ProductData.addProduct(newProduct);
    SnackBarCustom.show(context, message: 'Товар добавлен');

    nameController.clear();
    priceController.clear();
    daysController.clear();
    locationController.clear();
    descriptionController.clear();
    brandController.clear();
    setState(() {
      _imagePaths.clear();
      _selectedCategory = null;
      _selectedSubcategory = null;
    });
  }

  @override
  void dispose() {
    nameController.dispose();
    categoryController.dispose();
    brandController.dispose();
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
        child: Form(
          key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Добавить товар',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.oliveGray,
                ),
              ),
              const SizedBox(height: 15),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _imagePaths.length + 1,
                  itemBuilder: (context, index) {
                    if (index == _imagePaths.length) {
                      return _imagePaths.length < maxImages
                          ? GestureDetector(
                              onTap: _pickImages,
                              child: Container(
                                height: 100,
                                width: 100,
                                margin: const EdgeInsets.only(right: 10),
                                decoration: BoxDecoration(
                                  color: AppColors.whiteAntique,
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: const Icon(
                                  Icons.add_a_photo,
                                  color: AppColors.oliveGray,
                                ),
                              ),
                            )
                          : const SizedBox.shrink();
                    }
                    return GestureDetector(
                      onTap: () => _replaceImage(index),
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
              AppTextField(controller: nameController, hint: 'Название товара',
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Введите название' : null,),
              const SizedBox(height: 10),
              AppDropdownMenu(
                value: _selectedCategory,
                hint: 'Категория',
                errorText: _categoryError ? 'Выберите категорию' : null,
                options: categories.map((cat) => cat.name).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value;
                    _selectedSubcategory = null;
                    _categoryError = false;
                    _subcategoryError = false;
                  });
                },
              ),
              const SizedBox(height: 10),
              AppDropdownMenu(
                key: ValueKey('subcategory_$_selectedCategory'),
                value: _selectedSubcategory,
                hint: 'Подкатегория',
                errorText: _categoryError ? 'Выберите подкатегорию' : null,
                options: _selectedCategory != null
                    ? categories
                    .firstWhere((c) => c.name == _selectedCategory)
                    .subcategories
                    : [],
                onChanged: _selectedCategory != null
                    ? (value) {
                  setState(() {
                    _selectedSubcategory = value;
                    _subcategoryError = false;
                  });
                }
                    : null,
              ),
              const SizedBox(height: 10),
              AppTextField(controller: brandController, hint: 'Бренд'),
              const SizedBox(height: 10),
              AppTextField(
                controller: daysController,
                hint: 'Минимальный срок аренды (дни)',
                maxLines: 1,
              ),
              const SizedBox(height: 10),
              AppTextField(
                controller: priceController,
                hint: 'Цена, ₽',
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Введите цену';
                  if (int.tryParse(v.trim()) == null) return 'Цена должна быть числом';
                  return null;
                },
              ),
              const SizedBox(height: 10),
              AppTextField(
                controller: locationController,
                hint: 'Город, район (необязательно)',
              ),
              const SizedBox(height: 10),
              AppTextField(
                controller: descriptionController,
                hint: 'Опишите товар, его состояние и условия аренды...',
                maxLines: 10,
                minLines: 1,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _addProduct,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.copper,
                  foregroundColor: AppColors.spaceCream,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: const Text(
                  'Опубликовать',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      ),
    );
  }
}
