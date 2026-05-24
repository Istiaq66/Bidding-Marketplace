import 'dart:io';
import 'package:app/services/new_auction_item.dart';
import 'package:app/providers/theme_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class NewItem extends StatefulWidget {
  const NewItem({super.key});

  @override
  State<NewItem> createState() => _NewItemState();
}

class _NewItemState extends State<NewItem> {
  final currentUser = FirebaseAuth.instance.currentUser;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _minBidPriceController = TextEditingController();

  File? _image;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 7));
  bool _isLoading = false;

  Future<void> _selectDate(BuildContext context) async {
    final colorToken = ThemeProvider.of(context).colorToken;

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: colorToken.primary,
              onPrimary: Colors.white,
              surface: colorToken.surface,
              onSurface: colorToken.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      setState(() {
        _image = File(pickedFile.path);
      });

      // Close bottom sheet if open
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    } on PlatformException catch (e) {
      _showErrorSnackbar('Failed to pick image: ${e.message}');
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
                onTap: () => _pickImage(ImageSource.camera),
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
                onTap: () => _pickImage(ImageSource.gallery),
              ),
              if (_image != null)
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
                    setState(() => _image = null);
                    Navigator.pop(context);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitAuction() async {
    if (!_formKey.currentState!.validate()) return;

    if (_image == null) {
      _showErrorSnackbar('Please select an image');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await NewAuctionItem().addItem(
        _nameController.text.trim(),
        _minBidPriceController.text.trim(),
        _descriptionController.text.trim(),
        DateFormat('yyyy-MM-dd').format(_selectedDate),
        _image!,
        currentUser!.uid,
      );

      _showSuccessSnackbar('Auction created successfully!');

      // Clear form
      _nameController.clear();
      _descriptionController.clear();
      _minBidPriceController.clear();
      setState(() {
        _image = null;
        _selectedDate = DateTime.now().add(const Duration(days: 7));
      });

      // Navigate back
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) Navigator.pop(context);

    } catch (e) {
      _showErrorSnackbar('Failed to create auction: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
    _descriptionController.dispose();
    _minBidPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorToken = ThemeProvider.of(context).colorToken;

    return Scaffold(
      backgroundColor: colorToken.background,
      appBar: AppBar(
        title: Text(
          'Create Auction',
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
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image Upload Section
                  Center(
                    child: GestureDetector(
                      onTap: _showImageSourceDialog,
                      child: Container(
                        width: double.infinity,
                        height: 200,
                        decoration: BoxDecoration(
                          color: colorToken.surfaceVariant,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: colorToken.divider,
                            width: 2,
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: _image != null
                            ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            _image!,
                            fit: BoxFit.cover,
                          ),
                        )
                            : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_photo_alternate_outlined,
                              size: 64,
                              color: colorToken.textSecondary,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Tap to add photo',
                              style: TextStyle(
                                fontSize: 16,
                                color: colorToken.textSecondary,
                                fontFamily: 'SourceSans3',
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Camera or Gallery',
                              style: TextStyle(
                                fontSize: 14,
                                color: colorToken.textTertiary,
                                fontFamily: 'SourceSans3',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Product Details Section
                  Text(
                    'Product Details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colorToken.textPrimary,
                      fontFamily: 'SourceSans3',
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Product Name
                  TextFormField(
                    controller: _nameController,
                    style: TextStyle(
                      color: colorToken.textPrimary,
                      fontFamily: 'SourceSans3',
                    ),
                    decoration: InputDecoration(
                      labelText: 'Product Name',
                      hintText: 'Enter product name',
                      prefixIcon: Icon(Icons.shopping_bag_outlined, color: colorToken.primary),
                      labelStyle: TextStyle(
                        color: colorToken.textSecondary,
                        fontFamily: 'SourceSans3',
                      ),
                      hintStyle: TextStyle(
                        color: colorToken.textTertiary,
                        fontFamily: 'SourceSans3',
                      ),
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
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter product name';
                      }
                      if (value.length < 3) {
                        return 'Name must be at least 3 characters';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Description
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 4,
                    style: TextStyle(
                      color: colorToken.textPrimary,
                      fontFamily: 'SourceSans3',
                    ),
                    decoration: InputDecoration(
                      labelText: 'Description',
                      hintText: 'Describe your product...',
                      alignLabelWithHint: true,
                      prefixIcon: Padding(
                        padding: const EdgeInsets.only(bottom: 60),
                        child: Icon(Icons.description_outlined, color: colorToken.primary),
                      ),
                      labelStyle: TextStyle(
                        color: colorToken.textSecondary,
                        fontFamily: 'SourceSans3',
                      ),
                      hintStyle: TextStyle(
                        color: colorToken.textTertiary,
                        fontFamily: 'SourceSans3',
                      ),
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
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter description';
                      }
                      if (value.length < 10) {
                        return 'Description must be at least 10 characters';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Minimum Bid Price
                  TextFormField(
                    controller: _minBidPriceController,
                    keyboardType: TextInputType.number,
                    style: TextStyle(
                      color: colorToken.textPrimary,
                      fontFamily: 'SourceSans3',
                    ),
                    decoration: InputDecoration(
                      labelText: 'Minimum Bid Price',
                      hintText: 'Enter minimum bid amount',
                      prefixIcon: Icon(Icons.attach_money, color: colorToken.primary),
                      labelStyle: TextStyle(
                        color: colorToken.textSecondary,
                        fontFamily: 'SourceSans3',
                      ),
                      hintStyle: TextStyle(
                        color: colorToken.textTertiary,
                        fontFamily: 'SourceSans3',
                      ),
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
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter minimum bid price';
                      }
                      final price = double.tryParse(value);
                      if (price == null || price <= 0) {
                        return 'Please enter a valid price';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 24),

                  // Auction End Date Section
                  Text(
                    'Auction Duration',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colorToken.textPrimary,
                      fontFamily: 'SourceSans3',
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Date Picker
                  InkWell(
                    onTap: () => _selectDate(context),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorToken.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: colorToken.divider),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            color: colorToken.primary,
                            size: 24,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Auction End Date',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: colorToken.textSecondary,
                                    fontFamily: 'SourceSans3',
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  DateFormat('MMMM dd, yyyy').format(_selectedDate),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: colorToken.textPrimary,
                                    fontFamily: 'SourceSans3',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            color: colorToken.textSecondary,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitAuction,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorToken.primary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: colorToken.textSecondary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                          : const Text(
                        'Create Auction',
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
                    height: 56,
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
          ),
        ),
      ),
    );
  }
}