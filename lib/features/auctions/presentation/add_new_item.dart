import 'package:app/features/auth/data/auth_repository.dart';
import 'package:app/features/auctions/data/product_repository.dart';
import 'package:app/core/theme/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class NewItem extends StatefulWidget {
  const NewItem({super.key});

  @override
  State<NewItem> createState() => _NewItemState();
}

class _NewItemState extends State<NewItem> {
  final String? _sellerId = AuthRepository.currentUserId;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _minBidPriceController = TextEditingController();
  final _imageUrlController = TextEditingController();

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

  Future<void> _submitAuction() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final sellerId = _sellerId;
    if (sellerId == null) {
      _showErrorSnackbar('You must be signed in to create an auction');
      setState(() => _isLoading = false);
      return;
    }

    try {
      await ProductRepository.create(
        sellerId: sellerId,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        minBidPrice: _minBidPriceController.text.trim(),
        date: DateFormat('yyyy-MM-dd').format(_selectedDate),
        imageUrl: _imageUrlController.text.trim(),
      );

      _showSuccessSnackbar('Auction created successfully!');

      _nameController.clear();
      _descriptionController.clear();
      _minBidPriceController.clear();
      _imageUrlController.clear();
      setState(() {
        _selectedDate = DateTime.now().add(const Duration(days: 7));
      });

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
    _imageUrlController.dispose();
    super.dispose();
  }

  InputDecoration _decoration(
    ColorToken colorToken, {
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: colorToken.primary),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorToken = ThemeProvider.of(context).colorToken;
    final imageUrl = _imageUrlController.text.trim();

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
                  // Image preview
                  Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      color: colorToken.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colorToken.divider, width: 2),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: imageUrl.isEmpty
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.image_outlined,
                                  size: 64,
                                  color: colorToken.textSecondary,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Paste an image URL below',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: colorToken.textSecondary,
                                    fontFamily: 'SourceSans3',
                                  ),
                                ),
                              ],
                            )
                          : Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Center(
                                child: Icon(
                                  Icons.broken_image_outlined,
                                  size: 64,
                                  color: colorToken.textSecondary,
                                ),
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _imageUrlController,
                    onChanged: (_) => setState(() {}),
                    style: TextStyle(
                      color: colorToken.textPrimary,
                      fontFamily: 'SourceSans3',
                    ),
                    decoration: _decoration(
                      colorToken,
                      label: 'Image URL',
                      hint: 'https://...',
                      icon: Icons.link,
                    ),
                    validator: (value) {
                      final v = value?.trim() ?? '';
                      if (v.isEmpty) return 'Please paste an image URL';
                      final uri = Uri.tryParse(v);
                      if (uri == null || !uri.hasAbsolutePath || uri.host.isEmpty) {
                        return 'Enter a valid URL (https://...)';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 24),

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

                  TextFormField(
                    controller: _nameController,
                    style: TextStyle(
                      color: colorToken.textPrimary,
                      fontFamily: 'SourceSans3',
                    ),
                    decoration: _decoration(
                      colorToken,
                      label: 'Product Name',
                      hint: 'Enter product name',
                      icon: Icons.shopping_bag_outlined,
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

                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 4,
                    style: TextStyle(
                      color: colorToken.textPrimary,
                      fontFamily: 'SourceSans3',
                    ),
                    decoration: _decoration(
                      colorToken,
                      label: 'Description',
                      hint: 'Describe your product...',
                      icon: Icons.description_outlined,
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

                  TextFormField(
                    controller: _minBidPriceController,
                    keyboardType: TextInputType.number,
                    style: TextStyle(
                      color: colorToken.textPrimary,
                      fontFamily: 'SourceSans3',
                    ),
                    decoration: _decoration(
                      colorToken,
                      label: 'Minimum Bid Price',
                      hint: 'Enter minimum bid amount',
                      icon: Icons.attach_money,
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
                          Icon(Icons.calendar_today,
                              color: colorToken.primary, size: 24),
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
                                  DateFormat('MMMM dd, yyyy')
                                      .format(_selectedDate),
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
                          Icon(Icons.arrow_forward_ios,
                              color: colorToken.textSecondary, size: 16),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

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