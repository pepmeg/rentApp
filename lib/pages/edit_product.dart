import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:untitled/utils/colors.dart';
import 'package:untitled/models/product.dart';
import 'package:untitled/data/product_data.dart';
import '../data/category.dart';

class EditProduct extends StatefulWidget {
  final Product product;

  const EditProduct({required this.product, super.key});

  @override
  State<EditProduct> createState() => _EditProductState();
}

class _EditProductState extends State<EditProduct> {
  late TextEditingController nameController;
  late TextEditingController categoryController;
  late TextEditingController priceController;
  late TextEditingController daysController;
  late TextEditingController locationController;
  late TextEditingController descriptionController;
  late List<String> _imagePaths;
  String? _selectedCategory;
  String? _selectedSubcategory;
  static const int maxImages = 15;

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
    categoryController = TextEditingController();
    priceController = TextEditingController(text: p.price.toString());
    daysController = TextEditingController();
    locationController = TextEditingController(text: p.location);
    descriptionController = TextEditingController(text: p.description);
    _imagePaths = List.from(p.images);
    _selectedCategory = p.category.isEmpty ? null : p.category;
    _selectedSubcategory = p.subcategory.isEmpty ? null : p.subcategory;
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

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage();
    if (pickedFiles == null || pickedFiles.isEmpty) return;
    final remaining = maxImages - _imagePaths.length;
    if (remaining <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Лимит 15 фото')),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите название и цену')),
      );
      return;
    }
    final updatedProduct = Product(
      id: widget.product.id,
      ownerId: widget.product.ownerId,
      name: name,
      price: price,
      location: locationController.text.trim().isEmpty ? 'Не указано' : locationController.text.trim(),
      images: List.from(_imagePaths),
      createdAt: widget.product.createdAt,
      category: _selectedCategory ?? '',
      subcategory: _selectedSubcategory ?? '',
      description: descriptionController.text.trim(),
    );

    ProductData.updateProduct(widget.product.id, updatedProduct);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Товар обновлён',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.normal, color: AppColors.whiteAntique),
        ),
        backgroundColor: AppColors.oliveGray,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(16),
        duration: Duration(seconds: 3),
      ),
    );
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
        title: const Text('Удалить товар', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.oliveGray)),
        content: const Text('Вы уверены? Товар исчезнет навсегда.', style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: AppColors.oliveGray)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена', style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: AppColors.oliveGray)),
          ),
          TextButton(
            onPressed: () {
              ProductData.deleteProduct(widget.product.id);
              Navigator.pop(ctx);
              Navigator.pop(context, true);
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Товар удалён',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.normal, color: AppColors.whiteAntique),
                    ),
                    backgroundColor: AppColors.oliveGray,
                    behavior: SnackBarBehavior.floating,
                    margin: EdgeInsets.all(16),
                    duration: Duration(seconds: 3),
                  ),
                );
            },
            child: const Text('Удалить', style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: AppColors.copper)),
          ),
        ],
      ),
    );
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
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, size: 24, color: AppColors.oliveGray),
                    onPressed: () => Navigator.pop(context),
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 5),
                  const Text(
                    'Редактировать товар',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.oliveGray),
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
                          child: const Icon(Icons.add_a_photo, color: AppColors.oliveGray),
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
              _buildField(nameController, 'Название товара'),
              const SizedBox(height: 10),
              _buildDropdown(
                value: _selectedCategory,
                hint: 'Категория',
                items: categories.map((cat) => DropdownMenuItem(value: cat.name, child: Text(cat.name))).toList(),
                onChanged: (value) => setState(() { _selectedCategory = value; _selectedSubcategory = null; }),
              ),
              const SizedBox(height: 10),
              _buildDropdown(
                value: _selectedSubcategory,
                hint: 'Подкатегория',
                items: _selectedCategory != null
                    ? categories
                    .firstWhere((c) => c.name == _selectedCategory)
                    .subcategories
                    .map((sub) => DropdownMenuItem(value: sub, child: Text(sub)))
                    .toList()
                    : [],
                onChanged: _selectedCategory != null ? (value) => setState(() => _selectedSubcategory = value) : null,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _buildField(priceController, 'Цена (₽)')),
                  const SizedBox(width: 10),
                  Expanded(child: _buildField(daysController, 'Срок аренды (дни)')),
                ],
              ),
              const SizedBox(height: 10),
              _buildField(locationController, 'Город, район'),
              const SizedBox(height: 10),
              _buildField(descriptionController, 'Описание...'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveChanges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.copper,
                  foregroundColor: AppColors.spaceCream,
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
                  backgroundColor: Colors.red.shade700,
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

  Widget _buildField(TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
      style: const TextStyle(fontSize: 16, color: AppColors.oliveGray),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: AppColors.oliveGray.withOpacity(0.5), fontSize: 16),
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
          borderSide: const BorderSide(color: AppColors.oliveGray, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required String hint,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?>? onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.whiteAntique,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey, width: 2),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(hint, style: TextStyle(color: AppColors.oliveGray.withOpacity(0.5), fontSize: 16)),
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down, color: AppColors.oliveGray),
          style: const TextStyle(fontSize: 16, color: AppColors.oliveGray),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}