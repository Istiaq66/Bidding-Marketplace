import 'dart:async';

import 'package:app/core/theme/theme_provider.dart';
import 'package:app/features/auctions/data/product_repository.dart';
import 'package:app/features/auctions/domain/product.dart';
import 'package:app/features/auth/data/auth_repository.dart';
import 'package:app/features/bids/data/bid_repository.dart';
import 'package:app/core/utils/money.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Dialog for placing a bid. Pops `true` once the bid is placed.
///
/// Owns its own submitting state (the page's `setState` doesn't rebuild a
/// dialog route, so the button would otherwise never disable) and keeps the
/// product live, so the minimum shown and validated tracks bids that land
/// while the dialog is open.
class BidDialog extends StatefulWidget {
  const BidDialog({super.key, required this.initialProduct});

  final Product initialProduct;

  @override
  State<BidDialog> createState() => _BidDialogState();
}

class _BidDialogState extends State<BidDialog> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  late Product _product = widget.initialProduct;
  StreamSubscription<Product?>? _sub;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _sub = ProductRepository.watchById(widget.initialProduct.id).listen((p) {
      if (p != null && mounted) setState(() => _product = p);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _controller.dispose();
    super.dispose();
  }

  String? _validate(String? value) {
    final bid = double.tryParse(value?.trim() ?? '');
    if (value == null || value.trim().isEmpty) return 'Enter bid amount';
    if (bid == null) return 'Enter a valid number';
    if (bid <= _product.currentBid) {
      return 'Bid must be > ${formatMoney(_product.currentBid)}';
    }
    if (_product.bidCount > 0 && bid < _product.nextMinBid) {
      return 'Bid must be ≥ ${formatMoney(_product.nextMinBid)}';
    }
    return null;
  }

  Future<void> _submit() async {
    if (_submitting || !_formKey.currentState!.validate()) return;
    final userId = AuthRepository.currentUserId;
    if (userId == null) {
      setState(() => _error = 'Please login to place a bid');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await BidRepository.place(
        productId: _product.id,
        bidderId: userId,
        amount: double.parse(_controller.text.trim()),
      );
      if (mounted) Navigator.pop(context, true);
    } on Exception catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorToken = ThemeProvider.of(context).colorToken;
    final product = _product;

    return AlertDialog(
      backgroundColor: colorToken.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        'Place Your Bid',
        style: TextStyle(
          color: colorToken.textPrimary,
          fontWeight: FontWeight.bold,
          fontFamily: 'SourceSans3',
        ),
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current bid: ${formatMoney(product.currentBid)}',
              style: TextStyle(
                color: colorToken.textSecondary,
                fontFamily: 'SourceSans3',
              ),
            ),
            const SizedBox(height: 4),
            Text(
              product.bidCount == 0
                  ? 'First bid must clear the start price.'
                  : 'Min next bid: ${formatMoney(product.nextMinBid)} '
                      '(${formatMoney(product.minIncrement)} increment)',
              style: TextStyle(
                color: colorToken.textSecondary,
                fontFamily: 'SourceSans3',
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _controller,
              enabled: !_submitting,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              autofocus: true,
              onFieldSubmitted: (_) => _submit(),
              style: TextStyle(
                color: colorToken.textPrimary,
                fontFamily: 'SourceSans3',
              ),
              decoration: InputDecoration(
                labelText: 'Your Bid Amount',
                prefixIcon: Icon(Icons.attach_money, color: colorToken.primary),
                labelStyle: TextStyle(
                  color: colorToken.textSecondary,
                  fontFamily: 'SourceSans3',
                ),
                filled: true,
                fillColor: colorToken.surfaceVariant,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorToken.primary, width: 2),
                ),
              ),
              validator: _validate,
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TextStyle(
                  color: colorToken.error,
                  fontFamily: 'SourceSans3',
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.pop(context, false),
          child: Text(
            'Cancel',
            style: TextStyle(
              color: colorToken.textSecondary,
              fontFamily: 'SourceSans3',
            ),
          ),
        ),
        ElevatedButton(
          onPressed: _submitting ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: colorToken.primary,
            foregroundColor: colorToken.onPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child:
              _submitting
                  ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: colorToken.onPrimary,
                      strokeWidth: 2,
                    ),
                  )
                  : const Text(
                    'Place Bid',
                    style: TextStyle(fontFamily: 'SourceSans3'),
                  ),
        ),
      ],
    );
  }
}
