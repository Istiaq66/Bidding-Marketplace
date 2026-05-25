import 'package:app/models/product.dart';
import 'package:app/providers/theme_provider.dart';
import 'package:app/repositories/product_repository.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Lets the seller update an auction's description, end date, and minimum
/// bid — but only while no bids have been placed. The bid-count guard is
/// enforced both in [ProductRepository.updateEditable] (transaction) and in
/// the Firestore security rules.
class EditAuctionPage extends StatefulWidget {
  final Product product;

  const EditAuctionPage({super.key, required this.product});

  @override
  State<EditAuctionPage> createState() => _EditAuctionPageState();
}

class _EditAuctionPageState extends State<EditAuctionPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _description;
  late final TextEditingController _minBid;
  late final TextEditingController _date;
  DateTime? _endDate;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _description = TextEditingController(text: widget.product.description);
    _minBid = TextEditingController(text: widget.product.minBidPrice);
    _date = TextEditingController(text: widget.product.date);
    if (widget.product.date.isNotEmpty) {
      _endDate = DateTime.tryParse(widget.product.date);
    }
  }

  @override
  void dispose() {
    _description.dispose();
    _minBid.dispose();
    _date.dispose();
    super.dispose();
  }

  bool get _isEditable => widget.product.bidCount == 0;

  Future<void> _pickDate() async {
    final initial = _endDate ?? DateTime.now().add(const Duration(days: 1));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null) return;
    setState(() {
      _endDate = picked;
      _date.text = DateFormat('yyyy-MM-dd').format(picked);
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      await ProductRepository.updateEditable(
        id: widget.product.id,
        description: _description.text.trim(),
        date: _date.text.trim(),
        minBidPrice: _minBid.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Auction updated'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorToken = ThemeProvider.of(context).colorToken;

    return Scaffold(
      backgroundColor: colorToken.background,
      appBar: AppBar(
        backgroundColor: colorToken.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorToken.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Edit Auction',
          style: TextStyle(
            color: colorToken.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: 'SourceSans3',
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                if (!_isEditable)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorToken.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.lock_outline, color: colorToken.error),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'This auction already has bids and can no longer be edited.',
                            style: TextStyle(
                              color: colorToken.error,
                              fontFamily: 'SourceSans3',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                _readOnlyField(
                  colorToken,
                  label: 'Product Name',
                  value: widget.product.name,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _description,
                  enabled: _isEditable,
                  minLines: 3,
                  maxLines: 6,
                  style: TextStyle(color: colorToken.textPrimary),
                  decoration: _decoration(colorToken, 'Description'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _minBid,
                  enabled: _isEditable,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  style: TextStyle(color: colorToken.textPrimary),
                  decoration: _decoration(colorToken, 'Minimum Bid (USD)'),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Required';
                    final n = double.tryParse(v.trim());
                    if (n == null || n <= 0) return 'Must be a positive number';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _date,
                  readOnly: true,
                  enabled: _isEditable,
                  onTap: _isEditable ? _pickDate : null,
                  style: TextStyle(color: colorToken.textPrimary),
                  decoration: _decoration(colorToken, 'End Date').copyWith(
                    suffixIcon: Icon(
                      Icons.calendar_today,
                      color: colorToken.textSecondary,
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Required';
                    final d = DateTime.tryParse(v.trim());
                    if (d == null) return 'Invalid date';
                    if (d.isBefore(DateTime.now().subtract(const Duration(days: 1)))) {
                      return 'End date must be in the future';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: (!_isEditable || _isSaving) ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorToken.primary,
                    foregroundColor: colorToken.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _readOnlyField(
    ColorToken colorToken, {
    required String label,
    required String value,
  }) {
    return TextFormField(
      enabled: false,
      initialValue: value,
      decoration: _decoration(colorToken, label),
    );
  }

  InputDecoration _decoration(ColorToken colorToken, String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: colorToken.textSecondary),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: colorToken.divider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: colorToken.divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: colorToken.primary),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: colorToken.divider),
      ),
    );
  }
}