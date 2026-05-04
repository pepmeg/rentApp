import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../data/category.dart';
import '../data/product_data.dart';
import '../models/product.dart';
import '../provider/AuthProvider.dart';
import '../utils/colors.dart';
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
  bool _isPricePerHour = false;

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

    @override
    void initState() {
      super.initState();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !context.read<AuthProvider>().isUser) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      });
    }

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
      location: location,
      images: List<String>.from(_imagePaths),
      category: _selectedCategory ?? '',
      subcategory: _selectedSubcategory ?? '',
      description: descriptionController.text.trim(),
      brand: brandController.text.trim(),
      minRentDays: int.tryParse(daysController.text.trim()) ?? 1,
      minRentHours: _isPricePerHour ? (int.tryParse(daysController.text.trim()) ?? 1) : 0,
      isPricePerHour: _isPricePerHour,
      createdAt: DateTime.now(),
    );

    ProductData.addProduct(newProduct);
    SnackBarCustom.show(context, message: 'Товар добавлен');
    context.read<AuthProvider>().notifyListeners();

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
      _isPricePerHour = false;
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
    final priceText = priceController.text.trim();
    final price = int.tryParse(priceText);
    final commission = price != null ? Product.commissionForPrice(price) : null;
    final commissionRate = price != null ? (price > 1000 ? 3 : 5) : null;

    if (!context.watch<AuthProvider>().isUser) {
      return const SizedBox.shrink();
    }

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
              AppTextField(
                controller: nameController,
                hint: 'Название товара',
                maxLength: 100,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Введите название';
                  if (v.trim().length < 3) return 'Название должно быть не менее 3 символов';
                  return null;
                },
              ),
              const SizedBox(height: 10),
              AppDropdownMenu(
                key: ValueKey('category_$_selectedCategory'),
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
              AppTextField(
                controller: brandController,
                hint: 'Бренд',
                maxLength: 50,
              ),
              const SizedBox(height: 10),
              AppTextField(
                controller: priceController,
                hint: 'Цена, ₽',
                keyboardType: TextInputType.number,
                maxLength: 7,
                onChanged: (_) => setState(() {}),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Введите цену';
                  final price = int.tryParse(v.trim());
                  if (price == null || price < 1) return 'Цена должна быть ≥ 1 ₽';
                  if (price > 999999) return 'Слишком высокая цена';
                  return null;
                },
              ),
              if (commission != null && commissionRate != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Сервисный сбор $commissionRate% (~ $commission ₽)',
                    style: TextStyle(fontSize: 13, color: AppColors.oliveGray.withOpacity(0.6)),
                  ),
                ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isPricePerHour = false),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: _isPricePerHour ? Colors.transparent : AppColors.copper,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _isPricePerHour ? AppColors.oliveGray.withOpacity(0.3) : AppColors.copper,
                            width: 1.5,
                          ),
                          boxShadow: _isPricePerHour
                              ? []
                              : [
                            BoxShadow(
                              color: AppColors.copper.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            )
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.calendar_today,
                                size: 18,
                                color: _isPricePerHour ? AppColors.oliveGray : Colors.white),
                            const SizedBox(width: 8),
                            Text('за день',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: _isPricePerHour ? AppColors.oliveGray : Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isPricePerHour = true),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: _isPricePerHour ? AppColors.copper : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _isPricePerHour ? AppColors.copper : AppColors.oliveGray.withOpacity(0.3),
                            width: 1.5,
                          ),
                          boxShadow: _isPricePerHour
                              ? [
                            BoxShadow(
                              color: AppColors.copper.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            )
                          ]
                              : [],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.schedule,
                                size: 18,
                                color: _isPricePerHour ? Colors.white : AppColors.oliveGray),
                            const SizedBox(width: 8),
                            Text('за час',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: _isPricePerHour ? Colors.white : AppColors.oliveGray,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              AppTextField(
                controller: daysController,
                hint: _isPricePerHour ? 'Минимальный срок (часы)' : 'Минимальный срок (дни)',
                maxLines: 1,
                keyboardType: TextInputType.number,
                maxLength: _isPricePerHour ? 3 : 3,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  final value = int.tryParse(v.trim());
                  final maxVal = _isPricePerHour ? 720 : 365;
                  final unit = _isPricePerHour ? 'час' : 'день';
                  if (value == null || value < 1) return 'Срок должен быть ≥ 1 $unit';
                  if (value > maxVal) return 'Максимум $maxVal $unit';
                  return null;
                },
              ),
              const SizedBox(height: 10),
              AppTextField(
                controller: locationController,
                hint: 'Город, район (необязательно)',
                maxLength: 200,
              ),
              const SizedBox(height: 10),
              AppTextField(
                controller: descriptionController,
                hint: 'Опишите товар, его состояние и условия аренды...',
                maxLines: 10,
                minLines: 1,
                maxLength: 500,
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