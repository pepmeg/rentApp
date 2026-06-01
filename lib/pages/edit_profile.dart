import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../models/user.dart';
import '../provider/AuthProvider.dart';
import '../services/storage_service.dart';
import '../utils/avatar.dart';
import 'change_password.dart';
import '../utils/form_fields.dart';
import 'location_screen.dart';

class EditProfile extends StatefulWidget {
  const EditProfile({super.key});

  @override
  State<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  late TextEditingController firstNameController;
  late TextEditingController lastNameController;
  late TextEditingController phoneController;
  late TextEditingController emailController;
  late TextEditingController locationController;

  String? _avatarUrl;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser;
    firstNameController = TextEditingController(text: user?.firstName ?? '');
    lastNameController = TextEditingController(text: user?.lastName ?? '');
    phoneController = TextEditingController(text: user?.phoneNumber ?? '');
    emailController = TextEditingController(text: user?.email ?? '');
    locationController = TextEditingController(text: user?.address ?? '');
    _avatarUrl = user?.avatarUrl;
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    locationController.dispose();
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
      return sourcePath;
    }
  }

  Future<void> save() async {
    final authProvider = context.read<AuthProvider>();
    final currentUser = authProvider.currentUser;
    if (currentUser == null) return;

    final updatedUser = UserModel(
      uid: currentUser.uid,
      email: emailController.text.trim(),
      firstName: firstNameController.text.trim(),
      lastName: lastNameController.text.trim(),
      address: locationController.text.trim(),
      phoneNumber: phoneController.text.trim(),
      avatarUrl: _avatarUrl,
      role: currentUser.role,
      blocked: currentUser.blocked,
    );

    await authProvider.updateUser(updatedUser);
    if (mounted) {
      Navigator.pop(context);
    }
  }

  UserModel? _buildCurrentUserWithAvatar() {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return null;
    return UserModel(
      uid: user.uid,
      email: user.email,
      firstName: user.firstName,
      lastName: user.lastName,
      phoneNumber: user.phoneNumber,
      address: user.address,
      avatarUrl: _avatarUrl,
      role: user.role,
      blocked: user.blocked,
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final localPath = await _saveAvatarPermanently(pickedFile.path);
      final oldKey = _extractKeyFromPath(context.read<AuthProvider>().currentUser?.avatarUrl ?? '');
      final newKey = await StorageService.uploadAvatar(localPath, oldKey: oldKey);
      if (!mounted) return;
      setState(() {
        _avatarUrl = newKey;
      });
    }
  }

  String? _extractKeyFromPath(String path) {
    if (path.isEmpty) return null;
    if (path.startsWith('http://') || path.startsWith('https://')) {
      final uri = Uri.parse(path);
      final segments = uri.pathSegments;
      if (segments.length >= 2 && segments[0] == 'apprent-storage') {
        return segments.sublist(1).join('/');
      }
      return null;
    }
    return path;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(left: 20, right: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
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
                    'Редактировать профиль',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: _pickImage,
                child: buildUserAvatar(
                  _buildCurrentUserWithAvatar(),
                  radius: 50,
                  fallbackIcon: Icons.camera_alt,
                ),
              ),
              const SizedBox(height: 20),
              _buildField(firstNameController, 'Имя', theme),
              const SizedBox(height: 10),
              _buildField(lastNameController, 'Фамилия', theme),
              const SizedBox(height: 10),
              _buildField(emailController, 'Почта', theme),
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
                    hint: 'Адрес (нажмите для выбора)',
                    maxLength: 200,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              _buildField(phoneController, 'Номер телефона', theme),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  foregroundColor: theme.colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: const Text(
                  'Сохранить',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.onSurface,
                  foregroundColor: theme.colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: const Text(
                  'Сменить пароль',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String hint, ThemeData theme) {
    return TextField(
      controller: controller,
      style: TextStyle(fontSize: 16, color: theme.colorScheme.onSurface),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5), fontSize: 16),
        filled: true,
        fillColor: theme.cardTheme.color ?? theme.colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: theme.colorScheme.onSurface.withOpacity(0.5), width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: theme.primaryColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      ),
    );
  }
}