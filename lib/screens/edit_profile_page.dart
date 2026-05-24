import 'dart:io';
import 'package:app/repositories/auth_repository.dart';
import 'package:app/repositories/user_repository.dart';
import 'package:app/providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();
  final _addressController = TextEditingController();

  File? _imageFile;
  String? _currentImageUrl;
  bool _isLoading = false;
  bool _isUploading = false;
  final String? userId = AuthRepository.currentUserId;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final uid = userId;
    if (uid == null) return;
    setState(() => _isLoading = true);
    try {
      final user = await UserRepository.getById(uid);
      if (user != null) {
        _nameController.text = user.name ?? '';
        _emailController.text = user.email ?? '';
        _phoneController.text = user.phone ?? '';
        _bioController.text = user.bio ?? '';
        _addressController.text = user.address ?? '';
        _currentImageUrl = user.profileImage;
      }
    } catch (_) {
      _showErrorSnackbar('Failed to load profile data');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  void _showImageSourceDialog() {
    final colorToken = ThemeProvider.of(context).colorToken;

    showModalBottomSheet(
      context: context,
      backgroundColor: colorToken.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: colorToken.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                'Choose Photo Source',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colorToken.textPrimary,
                  fontFamily: 'SourceSans3',
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Icon(Icons.camera_alt, color: colorToken.primary),
                title: Text(
                  'Camera',
                  style: TextStyle(
                    color: colorToken.textPrimary,
                    fontFamily: 'SourceSans3',
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_library, color: colorToken.primary),
                title: Text(
                  'Gallery',
                  style: TextStyle(
                    color: colorToken.textPrimary,
                    fontFamily: 'SourceSans3',
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              if (_currentImageUrl != null || _imageFile != null)
                ListTile(
                  leading: Icon(Icons.delete, color: colorToken.error),
                  title: Text(
                    'Remove Photo',
                    style: TextStyle(
                      color: colorToken.error,
                      fontFamily: 'SourceSans3',
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _imageFile = null;
                      _currentImageUrl = null;
                    });
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<String?> _uploadImage() async {
    final uid = userId;
    if (_imageFile == null || uid == null) return _currentImageUrl;

    try {
      setState(() => _isUploading = true);
      return await UserRepository.uploadProfileImage(uid, _imageFile!);
    } catch (_) {
      _showErrorSnackbar('Failed to upload image');
      return null;
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    final uid = userId;
    if (uid == null) return;

    setState(() => _isLoading = true);
    final navigator = Navigator.of(context);

    try {
      final imageUrl = await _uploadImage();
      await UserRepository.updateProfile(
        uid: uid,
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        bio: _bioController.text.trim(),
        address: _addressController.text.trim(),
        profileImageUrl: imageUrl,
      );

      _showSuccessSnackbar('Profile updated successfully');
      navigator.pop(true);
    } catch (_) {
      _showErrorSnackbar('Failed to update profile');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessSnackbar(String message) {
    final colorToken = ThemeProvider.of(context).colorToken;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: colorToken.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    final colorToken = ThemeProvider.of(context).colorToken;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: colorToken.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = ThemeProvider.of(context, listen: true);
    final colorToken = themeProvider.colorToken;

    return Scaffold(
      backgroundColor: colorToken.background,
      appBar: AppBar(
        title: Text(
          'Edit Profile',
          style: TextStyle(
            color: colorToken.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
            fontFamily: 'SourceSans3',
          ),
        ),
        backgroundColor: colorToken.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorToken.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (!_isLoading)
            TextButton(
              onPressed: _saveProfile,
              child: Text(
                'Save',
                style: TextStyle(
                  color: colorToken.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  fontFamily: 'SourceSans3',
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? Center(
        child: CircularProgressIndicator(color: colorToken.primary),
      )
          : SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Profile Image Section - NO GRADIENT
              Container(
                width: double.infinity,
                color: colorToken.surface, // Solid surface color
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Column(
                  children: [
                    Stack(
                      children: [
                        // Profile Image
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: colorToken.surfaceVariant,
                          backgroundImage: _imageFile != null
                              ? FileImage(_imageFile!)
                              : _currentImageUrl != null
                              ? NetworkImage(_currentImageUrl!)
                          as ImageProvider
                              : null,
                          child: _imageFile == null &&
                              _currentImageUrl == null
                              ? Icon(
                            Icons.person,
                            size: 60,
                            color: colorToken.textSecondary,
                          )
                              : null,
                        ),

                        // Upload indicator
                        if (_isUploading)
                          Positioned.fill(
                            child: CircleAvatar(
                              radius: 60,
                              backgroundColor: Colors.black54,
                              child: CircularProgressIndicator(
                                color: colorToken.surface,
                              ),
                            ),
                          ),

                        // Camera button
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _showImageSourceDialog,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.black,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: colorToken.surface,
                                  width: 3,
                                ),
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Tap to change photo',
                      style: TextStyle(
                        color: colorToken.textSecondary,
                        fontSize: 14,
                        fontFamily: 'SourceSans3',
                      ),
                    ),
                  ],
                ),
              ),

              // Form Fields
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Personal Information Section
                    _buildSectionHeader(context, 'Personal Information'),
                    const SizedBox(height: 12),

                    _buildTextField(
                      controller: _nameController,
                      label: 'Full Name',
                      icon: Icons.person_outline,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your name';
                        }
                        if (value.length < 2) {
                          return 'Name must be at least 2 characters';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    _buildTextField(
                      controller: _emailController,
                      label: 'Email',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                            .hasMatch(value)) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    _buildTextField(
                      controller: _phoneController,
                      label: 'Phone Number',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          if (!RegExp(r'^\+?[\d\s-()]+$')
                              .hasMatch(value)) {
                            return 'Please enter a valid phone number';
                          }
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 24),

                    // About Section
                    _buildSectionHeader(context, 'About'),
                    const SizedBox(height: 12),

                    _buildTextField(
                      controller: _bioController,
                      label: 'Bio',
                      icon: Icons.info_outline,
                      maxLines: 4,
                      validator: (value) {
                        if (value != null && value.length > 500) {
                          return 'Bio must be less than 500 characters';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 24),

                    // Location Section
                    _buildSectionHeader(context, 'Location'),
                    const SizedBox(height: 12),

                    _buildTextField(
                      controller: _addressController,
                      label: 'Address',
                      icon: Icons.location_on_outlined,
                      maxLines: 3,
                    ),

                    const SizedBox(height: 32),

                    // Save Button - BLACK
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          disabledBackgroundColor:
                          colorToken.textSecondary,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                            : const Text(
                          'Save Changes',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'SourceSans3',
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Cancel Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: colorToken.textSecondary,
                          side: BorderSide(color: colorToken.divider),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'SourceSans3',
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final colorToken = ThemeProvider.of(context).colorToken;

    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: colorToken.textPrimary,
        fontFamily: 'SourceSans3',
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    final colorToken = ThemeProvider.of(context).colorToken;

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      style: TextStyle(
        color: colorToken.textPrimary,
        fontFamily: 'SourceSans3',
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: colorToken.textSecondary,
          fontFamily: 'SourceSans3',
        ),
        prefixIcon: Icon(icon, color: colorToken.primary),
        filled: true,
        fillColor: colorToken.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorToken.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorToken.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorToken.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorToken.error, width: 2),
        ),
        errorStyle: TextStyle(
          color: colorToken.error,
          fontFamily: 'SourceSans3',
        ),
      ),
    );
  }
}