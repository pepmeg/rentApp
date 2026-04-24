import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:untitled/provider/AuthProvider.dart';
import 'package:untitled/models/user.dart';
import 'package:untitled/utils/colors.dart';

class EditProfile extends StatefulWidget {
  const EditProfile({super.key});

  @override
  State<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  late TextEditingController firstNameController;
  late TextEditingController lastNameController;
  late TextEditingController addressController;
  late TextEditingController phoneController;
  late TextEditingController emailController;

  String? _avatarPath;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser;
    firstNameController = TextEditingController(text: user?.firstName ?? '');
    lastNameController = TextEditingController(text: user?.lastName ?? '');
    addressController = TextEditingController(text: user?.address ?? '');
    phoneController = TextEditingController(text: user?.phoneNumber ?? '');
    emailController = TextEditingController(text: user?.email ?? '');
    _avatarPath = user?.avatarPath;
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    addressController.dispose();
    phoneController.dispose();
    emailController.dispose();
    super.dispose();
  }

  Future<String> _saveAvatarPermanently(String sourcePath) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final avatarDir = Directory('${directory.path}/avatars');
      if (!await avatarDir.exists()) {
        await avatarDir.create(recursive: true);
      }
      final fileName = 'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedImage = File('${avatarDir.path}/$fileName');
      await File(sourcePath).copy(savedImage.path);
      return savedImage.path;
    } catch (e) {
      print('Ошибка сохранения аватара: $e');
      return sourcePath;
    }
  }

  Future<void> save() async {
    final authProvider = context.read<AuthProvider>();
    final currentUser = authProvider.currentUser;
    if (currentUser == null) return;

    final updatedUser = UserModel(
      id: currentUser.id,
      email: emailController.text.trim(),
      password: currentUser.password,
      firstName: firstNameController.text.trim(),
      lastName: lastNameController.text.trim(),
      address: addressController.text.trim(),
      phoneNumber: phoneController.text.trim(),
      avatarPath: _avatarPath,
    );

    await authProvider.updateUser(updatedUser);
    if (mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final permanentPath = await _saveAvatarPermanently(pickedFile.path);
      setState(() {
        _avatarPath = permanentPath;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.only(left: 20, right: 20, top: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, size: 24, color: AppColors.oliveGray),
                  onPressed: () => Navigator.pop(context),
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 5),
                const Text(
                  'Редактировать',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.oliveGray),
                ),
              ],
            ),
            const SizedBox(height: 15),
            GestureDetector(
              onTap: _pickImage,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(50),
                child: _avatarPath != null
                    ? Image.file(
                  File(_avatarPath!),
                  height: 100,
                  width: 100,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Image.asset(
                    'assets/silly_cat.jpg',
                    height: 100,
                    width: 100,
                    fit: BoxFit.cover,
                  ),
                )
                    : Image.asset(
                  'assets/silly_cat.jpg',
                  height: 100,
                  width: 100,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildField(firstNameController, 'Имя'),
            const SizedBox(height: 10),
            _buildField(lastNameController, 'Фамилия'),
            const SizedBox(height: 10),
            _buildField(addressController, 'Адрес'),
            const SizedBox(height: 10),
            _buildField(phoneController, 'Номер телефона'),
            const SizedBox(height: 10),
            _buildField(emailController, 'Почта'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.copper,
                foregroundColor: AppColors.spaceCream,
                padding: const EdgeInsets.symmetric(vertical: 12),
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              child: const Text(
                'Сохранить',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ],
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
}