import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../provider/bottom_nav_provider.dart';
import '../services/brand_service.dart';
import '../services/image_file_service.dart';
import '../services/product_service.dart';
import '../models/product.dart';
import '../provider/AuthProvider.dart';
import '../services/storage_service.dart';
import '../utils/form_fields.dart';
import '../utils/snackbar_custom.dart';
import '../widgets/app_button.dart';
import '../widgets/category_picker.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/product_image.dart';
import 'location_screen.dart';

class ProductForm extends StatefulWidget {
  final Product? product;

  const ProductForm({super.key, this.product});

  bool get isEditing => product != null;

  @override
  State<ProductForm> createState() => _ProductFormState();
}

class _ProductFormState extends State<ProductForm> {
  late TextEditingController nameController;
  late TextEditingController priceController;
  late TextEditingController daysController;
  late TextEditingController locationController;
  late TextEditingController descriptionController;
  late TextEditingController brandController;
  late List<String> _imagePaths;
  late bool _isPricePerHour;
  List<String> _categoryPath = [];
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;
  int _categoryPickerKey = 0;
  static const int maxImages = 10;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    final user = context.read<AuthProvider>().currentUser;

    nameController = TextEditingController(text: p?.name ?? '');
    priceController = TextEditingController(text: p?.price.toString() ?? '');
    daysController = TextEditingController(
      text: p != null
          ? (p.isPricePerHour ? p.minRentHours : p.minRentDays).toString()
          : '',
    );
    locationController = TextEditingController(
      text: p?.location ?? (user?.address.isNotEmpty == true ? user!.address : ''),
    );
    descriptionController = TextEditingController(text: p?.description ?? '');
    brandController = TextEditingController(text: p?.brand ?? '');

    _imagePaths = p != null ? List<String>.from(p.images) : [];
    _isPricePerHour = p?.isPricePerHour ?? false;
    _categoryPath = p != null ? List<String>.from(p.categoryPath) : [];

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !context.read<AuthProvider>().isUser) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    });
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
      final localPath = await ImageFileService.saveProductImage(file.path);
      _imagePaths.add(localPath);
    }
    if (mounted) setState(() {});
  }

  Future<void> _replaceImage(int index) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (!mounted || picked == null) return;

    if (_imagePaths.contains(picked.path)) {
      if (mounted) SnackBarCustom.show(context, message: 'Это фото уже добавлено');
      return;
    }
    final localPath = await ImageFileService.saveProductImage(picked.path);
    setState(() {
      _imagePaths[index] = localPath;
    });
  }

  void _removeImage(int index) {
    setState(() {
      _imagePaths.removeAt(index);
    });
  }

  Future<void> _submit() async {
    if (widget.isEditing) {
      await _saveChanges();
    } else {
      await _addProduct();
    }
  }

  Future<void> _addProduct() async {
    final navProvider = context.read<BottomNavProvider>();
    final authProvider = context.read<AuthProvider>();
    final currentUser = authProvider.currentUser;
    if (currentUser == null) {
      if (mounted) SnackBarCustom.show(context, message: 'Пользователь не авторизован');
      return;
    }
    if (!_validateForm()) return;
    setState(() => _isSubmitting = true);
    try {
      final name = nameController.text.trim();
      final price = int.tryParse(priceController.text.trim())!;

      String location = locationController.text.trim();
      if (location.isEmpty && currentUser.address.isNotEmpty) {
        location = currentUser.address;
      }
      final cloudKeys = <String>[];
      for (final localPath in _imagePaths) {
        final key = await StorageService.uploadProductImage(localPath);
        cloudKeys.add(key);
      }

      final daysValue = int.tryParse(daysController.text.trim()) ?? 1;
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
        minRentDays: _isPricePerHour ? 1 : daysValue.clamp(1, 365),
        minRentHours: _isPricePerHour ? daysValue.clamp(1, 720) : 0,
        isPricePerHour: _isPricePerHour,
        createdAt: DateTime.now(),
      );
      await ProductService.addProduct(newProduct);
      final brandName = brandController.text.trim();
      if (brandName.isNotEmpty && !context.read<BrandService>().brands.contains(brandName)) {
        await context.read<BrandService>().addBrand(brandName);
      }
      navProvider.incrementHomeRefreshCounter();
      if (mounted) {
        SnackBarCustom.show(context, message: 'Товар добавлен');
        _clearForm();
      }
    } catch (e) {
      debugPrint('Ошибка добавления товара: $e');
      if (mounted) SnackBarCustom.show(context, message: 'Ошибка при добавлении товара');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _saveChanges() async {
    if (!_validateForm()) return;
    setState(() => _isSubmitting = true);
    try {
      final name = nameController.text.trim();
      final price = int.tryParse(priceController.text.trim())!;

      String location = locationController.text.trim();
      final currentUser = context.read<AuthProvider>().currentUser;
      if (location.isEmpty && currentUser != null && currentUser.address.isNotEmpty) {
        location = currentUser.address;
        locationController.text = location;
      }
      final cloudKeys = <String>[];
      for (final path in _imagePaths) {
        final file = File(path);
        if (file.existsSync()) {
          final key = await StorageService.uploadProductImage(path);
          cloudKeys.add(key);
        } else {
          cloudKeys.add(path);
        }
      }

      final daysValue = int.tryParse(daysController.text.trim()) ?? 1;
      final updated = Product(
        id: widget.product!.id,
        ownerId: widget.product!.ownerId,
        name: name,
        nameLowercase: name.toLowerCase(),
        price: price,
        location: location.isEmpty ? 'Не указано' : location,
        images: cloudKeys,
        categoryPath: _categoryPath,
        description: descriptionController.text.trim(),
        brand: brandController.text.trim(),
        minRentDays: _isPricePerHour ? 1 : daysValue.clamp(1, 365),
        minRentHours: _isPricePerHour ? daysValue.clamp(1, 720) : 0,
        isPricePerHour: _isPricePerHour,
        createdAt: widget.product!.createdAt,
      );

      await ProductService.updateProduct(updated);
      context.read<BottomNavProvider>().incrementHomeRefreshCounter();

      if (mounted) {
        SnackBarCustom.show(context, message: 'Товар обновлён');
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('Ошибка обновления товара: $e');
      if (mounted) SnackBarCustom.show(context, message: 'Ошибка обновления');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  bool _validateForm() {
    final formValid = _formKey.currentState!.validate();
    if (!formValid) {
      if (mounted) SnackBarCustom.show(context, message: 'Заполните все обязательные поля');
      return false;
    }
    if (_categoryPath.isEmpty) {
      if (mounted) SnackBarCustom.show(context, message: 'Выберите категорию');
      return false;
    }
    final location = locationController.text.trim();
    final user = context.read<AuthProvider>().currentUser;
    if (location.isEmpty && (user?.address.isEmpty ?? true)) {
      if (mounted) SnackBarCustom.show(context, message: 'Укажите местоположение');
      return false;
    }
    return true;
  }

  void _clearForm() {
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
      _categoryPickerKey++;
    });
  }

  Future<void> _deleteProduct() async {
    final confirm = await showConfirmDialog(
      context,
      title: 'Удалить товар?',
      message: 'Это действие нельзя отменить. Товар будет удалён навсегда вместе со всеми связанными данными.',
      confirmText: 'Удалить',
      icon: Icons.delete_forever_rounded,
    );

    if (confirm != true || !mounted) return;

    try {
      await ProductService.deleteProduct(widget.product!.id);
      context.read<BottomNavProvider>().incrementHomeRefreshCounter();
      if (mounted) {
        SnackBarCustom.show(context, message: 'Товар удалён');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) SnackBarCustom.show(context, message: 'Ошибка удаления');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthProvider>().currentUser;
    final isUser = context.read<AuthProvider>().isUser;
    final theme = Theme.of(context);
    final price = int.tryParse(priceController.text.trim());
    final commission = price != null ? Product.commissionForPrice(price) : null;
    final commissionRate = price != null ? (price > 1000 ? 3 : 5) : null;

    if (!isUser) {
      return const SizedBox.shrink();
    }

    if (!widget.isEditing && user?.blocked == true) {
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
                Row(
                  children: [
                    if (widget.isEditing)
                      IconButton(
                        icon: Icon(Icons.arrow_back, size: 24, color: theme.colorScheme.onSurface),
                        onPressed: () => Navigator.pop(context),
                        constraints: const BoxConstraints(),
                      ),
                    if (widget.isEditing) const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        widget.isEditing ? 'Редактировать товар' : 'Добавить товар',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),

                _buildImageGallery(theme),
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
                  key: ValueKey('category_picker_$_categoryPickerKey'),
                  initialPath: _categoryPath,
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

                _buildPriceTypeSelector(theme),
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
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LocationPickerScreen()),
                    );
                    if (result != null && mounted) {
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
                  maxLength: 500,
                ),
                const SizedBox(height: 20),
                Button(
                  text: widget.isEditing ? 'Сохранить изменения' : 'Опубликовать',
                  onPressed: _isSubmitting ? null : _submit,
                  isLoading: _isSubmitting,
                  size: ButtonSize.large,
                ),
                if (widget.isEditing) ...[
                  const SizedBox(height: 12),
                  Button(
                    text: 'Удалить товар',
                    onPressed: _deleteProduct,
                    variant: ButtonVariant.destructive,
                    size: ButtonSize.large,
                  ),
                ],
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageGallery(ThemeData theme) {
    final showAddButton = _imagePaths.length < maxImages;
    final itemCount = _imagePaths.length + (showAddButton ? 1 : 0);

    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: itemCount,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          if (index == _imagePaths.length) {
            return GestureDetector(
              onTap: _pickImages,
              child: Container(
                width: 100,
                height: 100,
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
            clipBehavior: Clip.none,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: imageWidget,
              ),
              Positioned(
                top: -6,
                right: -6,
                child: GestureDetector(
                  onTap: () => _removeImage(index),
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: const Icon(Icons.close, size: 14, color: Colors.white),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPriceTypeSelector(ThemeData theme) {
    return Row(
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
    );
  }
}