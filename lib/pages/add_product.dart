import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../provider/bottom_nav_provider.dart';
import '../services/brand_service.dart';
import '../services/product_service.dart';
import '../models/product.dart';
import '../provider/AuthProvider.dart';
import '../services/storage_service.dart';
import '../utils/form_fields.dart';
import '../utils/snackbar_custom.dart';
import '../widgets/category_picker.dart';
import '../widgets/product_image.dart';
import 'location_screen.dart';

class AddProduct extends StatefulWidget {
  const AddProduct({super.key});

  @override
  State<AddProduct> createState() => _AddProductState();
}

class _AddProductState extends State<AddProduct> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController daysController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController brandController = TextEditingController();
  final List<String> _imagePaths = [];
  List<String> _categoryPath = [];
  final _formKey = GlobalKey<FormState>();
  bool _isPricePerHour = false;
  bool _isUploading = false;

  static const int maxImages = 10;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser;
    if (user != null && user.address.isNotEmpty) {
      locationController.text = user.address;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !context.read<AuthProvider>().isUser) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    });
  }

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
      debugPrint('Ошибка сохранения изображения: $e');
      return sourcePath;
    }
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage();
    if (pickedFiles.isEmpty) return;

    final remaining = maxImages - _imagePaths.length;
    if (remaining <= 0) {
      if (mounted) SnackBarCustom.show(context, message: 'Достигнут лимит в 10 фотографий');
      return;
    }

    final filesToAdd = pickedFiles.take(remaining);
    for (final file in filesToAdd) {
      if (_imagePaths.contains(file.path)) {
        if (mounted) SnackBarCustom.show(context, message: 'Это фото уже добавлено');
        continue;
      }
      final localPath = await _saveImagePermanently(file.path);
      _imagePaths.add(localPath);
      setState(() {});
    }
  }

  Future<void> _replaceImage(int index) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (!mounted) return;
    if (picked != null) {
      if (_imagePaths.contains(picked.path)) {
        if (mounted) SnackBarCustom.show(context, message: 'Это фото уже добавлено');
        return;
      }
      final localPath = await _saveImagePermanently(picked.path);
      setState(() {
        _imagePaths[index] = localPath;
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _imagePaths.removeAt(index);
    });
  }

  Future<void> _addProduct() async {
    final navProvider = context.read<BottomNavProvider>();
    final authProvider = context.read<AuthProvider>();
    final currentUser = authProvider.currentUser;
    if (currentUser == null) {
      if (mounted) SnackBarCustom.show(context, message: 'Пользователь не авторизован');
      return;
    }

    setState(() => _isUploading = true);

    try {
      final formValid = _formKey.currentState!.validate();
      if (!formValid) {
        if (mounted) SnackBarCustom.show(context, message: 'Заполните все обязательные поля');
        return;
      }

      if (_categoryPath.isEmpty) {
        if (mounted) SnackBarCustom.show(context, message: 'Выберите категорию');
        return;
      }

      final name = nameController.text.trim();
      final price = int.tryParse(priceController.text.trim());
      if (name.isEmpty || price == null) return;

      String location = locationController.text.trim();
      if (location.isEmpty && currentUser.address.isNotEmpty) {
        location = currentUser.address;
      } else if (location.isEmpty) {
        if (mounted) SnackBarCustom.show(context, message: 'Укажите город/район или заполните адрес в профиле');
        return;
      }

      final cloudKeys = <String>[];
      for (final localPath in _imagePaths) {
        final key = await StorageService.uploadProductImage(localPath);
        cloudKeys.add(key);
      }

      final newProduct = Product(
        id: '',
        ownerId: currentUser.uid,
        name: name,
        nameLowercase: name.toLowerCase(),
        price: price,
        location: location,
        images: cloudKeys,
        categoryPath: _categoryPath,
        description: descriptionController.text.trim(),
        brand: brandController.text.trim(),
        minRentDays: int.tryParse(daysController.text.trim()) ?? 1,
        minRentHours: _isPricePerHour ? (int.tryParse(daysController.text.trim()) ?? 1) : 0,
        isPricePerHour: _isPricePerHour,
        createdAt: DateTime.now(),
      );

      await ProductService.addProduct(newProduct);
      if (mounted) {
        SnackBarCustom.show(context, message: 'Товар добавлен');
        nameController.clear();
        priceController.clear();
        daysController.clear();
        locationController.clear();
        descriptionController.clear();
        brandController.clear();
        setState(() {
          _imagePaths.clear();
          _categoryPath = [];
          _isPricePerHour = false;
        });
      }
      final brandName = brandController.text.trim();
      if (brandName.isNotEmpty && !context.read<BrandService>().brands.contains(brandName)) {
        await context.read<BrandService>().addBrand(brandName);
      }
      navProvider.incrementHomeRefreshCounter();
    } catch (e) {
      if (mounted) SnackBarCustom.show(context, message: 'Ошибка при добавлении товара');
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    priceController.dispose();
    daysController.dispose();
    locationController.dispose();
    descriptionController.dispose();
    brandController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final priceText = priceController.text.trim();
    final price = int.tryParse(priceText);
    final commission = price != null ? Product.commissionForPrice(price) : null;
    final commissionRate = price != null ? (price > 1000 ? 3 : 5) : null;
    final user = context.watch<AuthProvider>().currentUser;
    final theme = Theme.of(context);

    if (!context.watch<AuthProvider>().isUser) {
      return const SizedBox.shrink();
    }

    if (user?.blocked == true) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.block, size: 64, color: theme.primaryColor),
              const SizedBox(height: 16),
              Text(
                'Ваш аккаунт заблокирован',
                style: TextStyle(fontSize: 18, color: theme.colorScheme.onSurface),
              ),
              const SizedBox(height: 8),
              Text(
                'Вы не можете добавлять товары',
                style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurface.withOpacity(0.5)),
              ),
            ],
          ),
        ),
      );
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
                Text(
                  'Добавить товар',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                ),
                const SizedBox(height: 15),
                SizedBox(
                  height: 100,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _imagePaths.length + (_imagePaths.length < maxImages ? 1 : 0),
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      if (index == _imagePaths.length) {
                        return GestureDetector(
                          onTap: _pickImages,
                          child: Container(
                            width: 100,
                            height: 100,
                            margin: const EdgeInsets.only(right: 10),
                            decoration: BoxDecoration(
                              color: theme.cardTheme.color ?? theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Icon(Icons.add_a_photo, color: theme.colorScheme.onSurface),
                          ),
                        );
                      }

                      final imageWidget = GestureDetector(
                        onTap: () => _replaceImage(index),
                        child: ProductImage(
                          images: [_imagePaths[index]],
                          width: 100,
                          height: 100,
                          backgroundColor: theme.cardTheme.color ?? theme.colorScheme.surface,
                        ),
                      );

                      return Stack(
                        children: [
                          imageWidget,
                          Positioned(
                            top: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: () => _removeImage(index),
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.5),
                                  borderRadius: const BorderRadius.only(
                                    topRight: Radius.circular(12),
                                    bottomLeft: Radius.circular(12),
                                  ),
                                ),
                                child: const Icon(Icons.close, size: 16, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
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
                CategoryPicker(
                  onPathChanged: (path) {
                    setState(() => _categoryPath = path);
                  },
                ),
                BrandInput(controller: brandController),
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
                      style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface.withOpacity(0.6)),
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
                            color: _isPricePerHour ? Colors.transparent : theme.primaryColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _isPricePerHour ? theme.colorScheme.onSurface.withOpacity(0.3) : theme.primaryColor,
                              width: 1.5,
                            ),
                            boxShadow: _isPricePerHour
                                ? []
                                : [BoxShadow(color: theme.primaryColor.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.calendar_today, size: 18,
                                  color: _isPricePerHour ? theme.colorScheme.onSurface : Colors.white),
                              const SizedBox(width: 8),
                              Text('за день',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: _isPricePerHour ? theme.colorScheme.onSurface : Colors.white)),
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
                            color: _isPricePerHour ? theme.primaryColor : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _isPricePerHour ? theme.primaryColor : theme.colorScheme.onSurface.withOpacity(0.3),
                              width: 1.5,
                            ),
                            boxShadow: _isPricePerHour
                                ? [BoxShadow(color: theme.primaryColor.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))]
                                : [],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.schedule, size: 18,
                                  color: _isPricePerHour ? Colors.white : theme.colorScheme.onSurface),
                              const SizedBox(width: 8),
                              Text('за час',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: _isPricePerHour ? Colors.white : theme.colorScheme.onSurface)),
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
                  keyboardType: TextInputType.number,
                  maxLength: 3,
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
                GestureDetector(
                  onTap: () async {
                    final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const LocationPickerScreen()));
                    if (result != null && mounted) {
                      setState(() {
                        locationController.text = result['address'] ?? '';
                      });
                    }
                  },
                  child: AbsorbPointer(
                    child: AppTextField(controller: locationController, hint: 'Местоположение (нажмите для выбора)', maxLength: 200),
                  ),
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
                  onPressed: _isUploading ? null : _addProduct,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    foregroundColor: theme.colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: _isUploading
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Text('Опубликовать', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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