import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();

  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();

  bool _isCurrentPasswordVisible = false;
  bool _isNewPasswordVisible = false;

  String? _selectedLocation;
  bool _isLoading = false;
  String _initialUsername = "";

  String? _currentPhotoUrl;
  File? _selectedImage;

  final List<String> _jordanAreas = [
    'Amman',
    'Zarqa',
    'Irbid',
    'Aqaba',
    'Salt',
    'Madaba',
    'Jerash',
    'Ajloun',
    'Mafraq',
    'Karak',
    'Tafilah',
    'Ma\'an',
    'Abdoun',
    'Dabouq',
    'Khalda',
    'Sweifieh',
    'Jubaiha',
    'Tla\' Al-Ali'
  ];

  @override
  void initState() {
    super.initState();
    _loadCurrentUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists && mounted) {
        setState(() {
          _nameController.text = doc['name'] ?? '';
          _usernameController.text = doc['username'] ?? '';
          _initialUsername = doc['username'] ?? '';
          _selectedLocation = doc['location'];
          _currentPhotoUrl = doc['photoUrl'];
        });
      }
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final newUsername = _usernameController.text.trim().toLowerCase();

      if (newUsername != _initialUsername) {
        bool isUnique = await AuthService().isUsernameUnique(newUsername);
        if (!isUnique) throw 'Username is already taken';
      }

      if (_newPasswordController.text.isNotEmpty) {
        if (_currentPasswordController.text.isEmpty) {
          throw 'Please enter your current password to set a new one.';
        }

        await AuthService().changePassword(
          currentPassword: _currentPasswordController.text,
          newPassword: _newPasswordController.text,
        );
      }

      await DatabaseService().updateUserProfile(
        uid: uid,
        name: _nameController.text.trim(),
        username: newUsername,
        location: _selectedLocation!,
        imageFile: _selectedImage,
      );

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Profile updated successfully!")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ImageProvider imageProvider;
    if (_selectedImage != null) {
      imageProvider = FileImage(_selectedImage!);
    } else if (_currentPhotoUrl != null && _currentPhotoUrl!.isNotEmpty) {
      imageProvider = NetworkImage(_currentPhotoUrl!);
    } else {
      imageProvider = const NetworkImage(
          'https://cdn-icons-png.flaticon.com/512/847/847969.png');
    }

    return Scaffold(
      appBar: AppBar(
          title: const Text("Edit Profile"),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Stack(
                          children: [
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: AppColors.primary.withOpacity(0.5),
                                    width: 3),
                                image: DecorationImage(
                                  image: imageProvider,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                  border:
                                      Border.all(color: Colors.white, width: 2),
                                ),
                                child: const Icon(Icons.camera_alt,
                                    color: Colors.white, size: 20),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    _buildTextField(
                      label: "Full Name",
                      controller: _nameController,
                      icon: Icons.person_outline,
                      validator: (v) => v!.isEmpty ? "Enter name" : null,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      label: "Username",
                      controller: _usernameController,
                      icon: Icons.alternate_email,
                      validator: (v) => v!.isEmpty ? "Enter username" : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedLocation,
                      decoration: _inputDecoration(
                          "Location", Icons.location_on_outlined),
                      items: _jordanAreas
                          .map(
                              (a) => DropdownMenuItem(value: a, child: Text(a)))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedLocation = v),
                      validator: (v) => v == null ? 'Select area' : null,
                    ),
                    const SizedBox(height: 30),
                    const Divider(),
                    const SizedBox(height: 10),
                    const Text(
                      "Change Password ",
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _currentPasswordController,
                      obscureText: !_isCurrentPasswordVisible,
                      decoration: _inputDecoration(
                              "Current Password", Icons.lock_outline)
                          .copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(
                              _isCurrentPasswordVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: Colors.grey),
                          onPressed: () => setState(() =>
                              _isCurrentPasswordVisible =
                                  !_isCurrentPasswordVisible),
                        ),
                      ),
                      validator: (val) {
                        if (_newPasswordController.text.isNotEmpty &&
                            (val == null || val.isEmpty)) {
                          return 'Required to change password';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _newPasswordController,
                      obscureText: !_isNewPasswordVisible,
                      decoration:
                          _inputDecoration("New Password", Icons.lock_reset)
                              .copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(
                              _isNewPasswordVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: Colors.grey),
                          onPressed: () => setState(() =>
                              _isNewPasswordVisible = !_isNewPasswordVisible),
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) return null;
                        if (val.length < 8) return 'At least 8 characters';
                        String pattern =
                            r'^(?=.*?[A-Za-z])(?=.*?[0-9])(?=.*?[!@#\$&*~]).{8,}$';
                        if (!RegExp(pattern).hasMatch(val)) {
                          return 'Must have letters, numbers & symbols';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15)),
                          elevation: 2,
                        ),
                        child: const Text("Save Changes",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTextField(
      {required String label,
      required TextEditingController controller,
      required IconData icon,
      String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      decoration: _inputDecoration(label, icon),
      validator: validator,
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: AppColors.textGrey),
      filled: true,
      fillColor: Colors.grey[50],
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[200]!)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary)),
    );
  }
}
