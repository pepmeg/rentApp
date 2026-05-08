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
import 'location_screen.dart';

class EditProduct extends StatefulWidget {
  final Product product;

  const EditProduct({required this.product, super.key});

  @override
  State<EditProduct> createState() => _EditProductState();
}

class _EditProductState extends State<EditProduct> {
  late TextEditingController nameController;
  late TextEditingController priceController;
  late TextEditingController daysController;
  late TextEditingController locationController;
  late TextEditingController descriptionController;
  late TextEditingController brandController;
  late List<String> _imagePaths;
  String? _selectedCategory;
  String? _selectedSubcategory;
  late bool _isPricePerHour;
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
      print('Ошибка сохранения: $e');
      return sourcePath;
    }
  }

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    nameController = TextEditingController(text: p.name);
    priceController = TextEditingController(text: p.price.toString());
    // Для почасового товара в поле показываем minRentHours, иначе minRentDays
    daysController = TextEditingController(
      text: (p.isPricePerHour ? p.minRentHours : p.minRentDays).toString(),
    );
    locationController = TextEditingController(text: p.location);
    descriptionController = TextEditingController(text: p.description);
    brandController = TextEditingController(text: p.brand);
    _imagePaths = List.from(p.images);
    _selectedCategory = p.category.isEmpty ? null : p.category;
    _selectedSubcategory = p.subcategory.isEmpty ? null : p.subcategory;
    _isPricePerHour = p.isPricePerHour;
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

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage();
    if (pickedFiles == null || pickedFiles.isEmpty) return;
    final remaining = maxImages - _imagePaths.length;
    if (remaining <= 0) {
      SnackBarCustom.show(context, message: 'Лимит 10 фото');
      return;
    }
    final filesToAdd = pickedFiles.take(remaining);
    for (final file in filesToAdd) {
      final permanentPath = await _saveImagePermanently(file.path);
      _imagePaths.add(permanentPath);
    }
    setState(() {});
  }

  Future<void> _replaceImage(int index) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final permanentPath = await _saveImagePermanently(picked.path);
      setState(() => _imagePaths[index] = permanentPath);
    }
  }

  void _saveChanges() {
    final name = nameController.text.trim();
    final price = int.tryParse(priceController.text.trim());
    if (name.isEmpty || price == null) {
      SnackBarCustom.show(context, message: 'Введите название и цену');
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final currentUser = authProvider.currentUser;
    String location = locationController.text.trim();
    if (location.isEmpty &&
        currentUser != null &&
        currentUser.address != null &&
        currentUser.address!.isNotEmpty) {
      location = currentUser.address!;
      locationController.text = location;
    }

    final int rentDays;
    final int rentHours;
    final int daysValue = int.tryParse(daysController.text.trim()) ?? 1;
    if (_isPricePerHour) {
      rentHours = daysValue.clamp(1, 720);
      rentDays = 1;
    } else {
      rentDays = daysValue.clamp(1, 365);
      rentHours = 0;
    }

    final updatedProduct = Product(
      id: widget.product.id,
      ownerId: widget.product.ownerId,
      name: name,
      price: price,
      location: location.isEmpty ? 'Не указано' : location,
      images: List.from(_imagePaths),
      createdAt: widget.product.createdAt,
      category: _selectedCategory ?? '',
      subcategory: _selectedSubcategory ?? '',
      description: descriptionController.text.trim(),
      brand: brandController.text.trim(),
      minRentDays: rentDays,
      minRentHours: rentHours,
      isPricePerHour: _isPricePerHour,
    );

    ProductData.updateProduct(widget.product.id, updatedProduct);
    SnackBarCustom.show(context, message: 'Товар обновлён');
    context.read<AuthProvider>().notifyListeners();
    Navigator.pop(context, true);
  }

  void _deleteProduct() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.whiteAntique,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        title: const Text('Удалить товар',
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.oliveGray)),
        content: const Text('Вы уверены? Товар исчезнет навсегда.',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.normal,
                color: AppColors.oliveGray)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.normal,
                    color: AppColors.oliveGray)),
          ),
          TextButton(
            onPressed: () {
              ProductData.deleteProduct(widget.product.id);
              context.read<AuthProvider>().notifyListeners();
              Navigator.pop(ctx);
              Navigator.pop(context, true);
              SnackBarCustom.show(context, message: 'Товар удалён');
            },
            child: const Text('Удалить',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.normal,
                    color: AppColors.copper)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final priceText = priceController.text.trim();
    final price = int.tryParse(priceText);
    final commission = price != null ? Product.commissionForPrice(price) : null;
    final commissionRate = price != null ? (price > 1000 ? 3 : 5) : null;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.only(left: 20, right: 20, top: 40),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back,
                        size: 24, color: AppColors.oliveGray),
                    onPressed: () => Navigator.pop(context),
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 5),
                  const Text(
                    'Редактировать товар',
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.oliveGray),
                  ),
                ],
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
                          child: const Icon(Icons.add_a_photo,
                              color: AppColors.oliveGray),
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
              AppTextField(controller: nameController, hint: 'Название товара'),
              const SizedBox(height: 10),
              AppDropdownMenu(
                key: ValueKey('category_$_selectedCategory'),
                value: _selectedCategory,
                hint: 'Категория',
                options: categories.map((cat) => cat.name).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value;
                    _selectedSubcategory = null;
                  });
                },
              ),
              const SizedBox(height: 10),
              AppDropdownMenu(
                key: ValueKey('subcategory_$_selectedCategory'),
                value: _selectedSubcategory,
                hint: 'Подкатегория',
                options: _selectedCategory != null
                    ? categories
                    .firstWhere((c) => c.name == _selectedCategory)
                    .subcategories
                    : [],
                onChanged: _selectedCategory != null
                    ? (value) => setState(() => _selectedSubcategory = value)
                    : null,
              ),
              const SizedBox(height: 10),
              AppTextField(controller: brandController, hint: 'Бренд'),
              const SizedBox(height: 10),
              AppTextField(
                controller: priceController,
                hint: 'Цена, ₽',
                keyboardType: TextInputType.number,
                maxLength: 7,
                onChanged: (_) => setState(() {}),
              ),
              if (commission != null && commissionRate != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Сервисный сбор $commissionRate% (~ $commission ₽)',
                    style: TextStyle(
                        fontSize: 13,
                        color: AppColors.oliveGray.withOpacity(0.6)),
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
                          color: _isPricePerHour
                              ? Colors.transparent
                              : AppColors.copper,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _isPricePerHour
                                ? AppColors.oliveGray.withOpacity(0.3)
                                : AppColors.copper,
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
                                color: _isPricePerHour
                                    ? AppColors.oliveGray
                                    : Colors.white),
                            const SizedBox(width: 8),
                            Text('за день',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: _isPricePerHour
                                        ? AppColors.oliveGray
                                        : Colors.white)),
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
                          color: _isPricePerHour
                              ? AppColors.copper
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _isPricePerHour
                                ? AppColors.copper
                                : AppColors.oliveGray.withOpacity(0.3),
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
                                color: _isPricePerHour
                                    ? Colors.white
                                    : AppColors.oliveGray),
                            const SizedBox(width: 8),
                            Text('за час',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: _isPricePerHour
                                        ? Colors.white
                                        : AppColors.oliveGray)),
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
                hint: _isPricePerHour
                    ? 'Минимальный срок (часы)'
                    : 'Минимальный срок (дни)',
                maxLines: 1,
                keyboardType: TextInputType.number,
                maxLength: 3,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  final value = int.tryParse(v.trim());
                  final maxVal = _isPricePerHour ? 720 : 365;
                  final unit = _isPricePerHour ? 'час' : 'день';
                  if (value == null || value < 1)
                    return 'Срок должен быть ≥ 1 $unit';
                  if (value > maxVal) return 'Максимум $maxVal $unit';
                  return null;
                },
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LocationPickerScreen()),
                  );
                  if (result != null) {
                    setState(() {
                      locationController.text = result['address'] ?? '';
                    });
                  }
                },
                child: AbsorbPointer(
                  child: AppTextField(
                    controller: locationController,
                    hint: 'Местоположение (нажмите для выбора)',
                    maxLength: 200,
                  ),
                ),
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
                onPressed: _saveChanges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.copper,
                  foregroundColor: AppColors.spaceCream,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                ),
                child: const Text('Сохранить изменения',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _deleteProduct,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                ),
                child: const Text('Удалить товар',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}