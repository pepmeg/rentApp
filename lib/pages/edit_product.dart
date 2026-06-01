import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../provider/bottom_nav_provider.dart';
import '../services/product_service.dart';
import '../models/product.dart';
import '../provider/AuthProvider.dart';
import '../services/storage_service.dart';
import '../utils/form_fields.dart';
import '../utils/snackbar_custom.dart';
import '../widgets/category_picker.dart';
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
  late bool _isPricePerHour;
  List<String> _categoryPath = [];

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
      debugPrint('Ошибка сохранения: $e');
      return sourcePath;
    }
  }

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    nameController = TextEditingController(text: p.name);
    priceController = TextEditingController(text: p.price.toString());
    daysController = TextEditingController(
      text: (p.isPricePerHour ? p.minRentHours : p.minRentDays).toString(),
    );
    locationController = TextEditingController(text: p.location);
    descriptionController = TextEditingController(text: p.description);
    brandController = TextEditingController(text: p.brand);
    _imagePaths = List<String>.from(p.images);
    _isPricePerHour = p.isPricePerHour;
    _categoryPath = List<String>.from(p.categoryPath);
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
    if (!mounted) return;
    if (pickedFiles.isEmpty) return;
    final remaining = maxImages - _imagePaths.length;
    if (remaining <= 0) {
      if (!mounted) return;
      SnackBarCustom.show(context, message: 'Лимит 10 фото');
      return;
    }
    final filesToAdd = pickedFiles.take(remaining);
    for (final file in filesToAdd) {
      final permanentPath = await _saveImagePermanently(file.path);
      _imagePaths.add(permanentPath);
    }
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _replaceImage(int index) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (!mounted) return;
    if (picked != null) {
      final localPath = await _saveImagePermanently(picked.path);
      final cloudUrl = await StorageService.uploadProductImage(localPath);
      if (!mounted) return;
      setState(() => _imagePaths[index] = cloudUrl);
    }
  }

  Future<void> _saveChanges() async {
    final name = nameController.text.trim();
    final price = int.tryParse(priceController.text.trim());
    if (name.isEmpty || price == null) {
      if (!mounted) return;
      SnackBarCustom.show(context, message: 'Введите название и цену');
      return;
    }

    if (_categoryPath.isEmpty) {
      if (!mounted) return;
      SnackBarCustom.show(context, message: 'Выберите категорию');
      return;
    }

    final currentUser = context.read<AuthProvider>().currentUser;
    String location = locationController.text.trim();
    if (location.isEmpty && currentUser != null && currentUser.address.isNotEmpty) {
      location = currentUser.address;
      locationController.text = location;
    }

    final daysValue = int.tryParse(daysController.text.trim()) ?? 1;
    final rentDays = _isPricePerHour ? 1 : daysValue.clamp(1, 365);
    final rentHours = _isPricePerHour ? daysValue.clamp(1, 720) : 0;

    final updated = Product(
      id: widget.product.id,
      ownerId: widget.product.ownerId,
      name: name,
      nameLowercase: name.toLowerCase(),
      price: price,
      location: location.isEmpty ? 'Не указано' : location,
      images: List<String>.from(_imagePaths),
      categoryPath: _categoryPath,
      description: descriptionController.text.trim(),
      brand: brandController.text.trim(),
      minRentDays: rentDays,
      minRentHours: rentHours,
      isPricePerHour: _isPricePerHour,
      createdAt: widget.product.createdAt,
    );

    try {
      await ProductService.updateProduct(updated);
      context.read<BottomNavProvider>().incrementHomeRefreshCounter();
      if (!mounted) return;
      SnackBarCustom.show(context, message: 'Товар обновлён');
      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      SnackBarCustom.show(context, message: 'Ошибка обновления');
    }
  }

  Future<void> _deleteProduct() async {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.cardTheme.color ?? theme.colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text(
          'Удалить товар',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
        ),
        content: Text(
          'Вы уверены? Товар исчезнет навсегда.',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: theme.colorScheme.onSurface),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Отмена',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: theme.colorScheme.onSurface),
            ),
          ),
          TextButton(
            onPressed: () async {
              final navigatorCtx = Navigator.of(ctx);
              final navigatorContext = Navigator.of(context);
              try {
                await ProductService.deleteProduct(widget.product.id);
                if (!mounted) return;
                navigatorCtx.pop();
                navigatorContext.pop(true);
                SnackBarCustom.show(context, message: 'Товар удалён');
              } catch (_) {
                if (!mounted) return;
                SnackBarCustom.show(context, message: 'Ошибка удаления');
              }
            },
            child: Text(
              'Удалить',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: theme.colorScheme.error),
            ),
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
    final theme = Theme.of(context);

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
                    icon: Icon(Icons.arrow_back, size: 24, color: theme.colorScheme.onSurface),
                    onPressed: () => Navigator.pop(context),
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Редактировать товар',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
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
                            color: theme.cardTheme.color ?? theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Icon(Icons.add_a_photo, color: theme.colorScheme.onSurface),
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
                          image: DecorationImage(image: FileImage(File(_imagePaths[index])), fit: BoxFit.cover),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              AppTextField(controller: nameController, hint: 'Название товара'),
              const SizedBox(height: 10),
              CategoryPicker(
                initialPath: _categoryPath,
                onPathChanged: (path) {
                  setState(() => _categoryPath = path);
                },
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
                  final navigator = Navigator.of(context);
                  final result = await navigator.push(
                    MaterialPageRoute(builder: (_) => const LocationPickerScreen()),
                  );
                  if (!mounted) return;
                  if (result != null) {
                    setState(() => locationController.text = result['address'] ?? '');
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
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveChanges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  foregroundColor: theme.colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: const Text('Сохранить изменения', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _deleteProduct,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.error,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: const Text('Удалить товар', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}