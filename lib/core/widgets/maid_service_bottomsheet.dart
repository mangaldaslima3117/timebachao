import 'package:bookmyservice/services/category_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/service_model.dart';
import '../../services/service_provider.dart';

class MaidServiceBottomSheet extends ConsumerStatefulWidget {
  final ServiceModel? initial;
  const MaidServiceBottomSheet({this.initial, super.key});

  @override
  ConsumerState<MaidServiceBottomSheet> createState() =>
      _MaidServiceBottomSheetState();
}

class _MaidServiceBottomSheetState
    extends ConsumerState<MaidServiceBottomSheet> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController name,
      description,
      mrpPrice,
      sellingPrice,
      duration,
      extraPricePerHour,
      pricePerBed,
      pricePerKitchen,
      pricePerBalcony,
      pricePerFamilyMember;

  String? selectedCategoryId;
  String? selectedCategoryName;

  late int numberOfBeds;
  late int numberOfKitchens;
  late int numberOfBalconies;
  late int numberOfFamilyMembers;

  @override
  void initState() {
    super.initState();
    name = TextEditingController(text: widget.initial?.name ?? '');
    mrpPrice = TextEditingController(
        text: widget.initial?.mrpPrice != null && widget.initial!.mrpPrice > 0
            ? widget.initial!.mrpPrice.toStringAsFixed(0)
            : '');
    sellingPrice = TextEditingController(
        text: widget.initial?.sellingPrice != null &&
                widget.initial!.sellingPrice > 0
            ? widget.initial!.sellingPrice.toStringAsFixed(0)
            : '');
    description =
        TextEditingController(text: widget.initial?.description ?? '');
    selectedCategoryId = widget.initial?.categoryId ?? '';
    selectedCategoryName = widget.initial?.categoryName ?? '';
    duration = TextEditingController(text: widget.initial?.duration ?? '');
    extraPricePerHour = TextEditingController(
        text: widget.initial?.extraPricePerDuration != null &&
                widget.initial!.extraPricePerDuration > 0
            ? widget.initial!.extraPricePerDuration.toStringAsFixed(0)
            : '');

    numberOfBeds = widget.initial?.numberOfBeds ?? 0;
    numberOfKitchens = widget.initial?.numberOfKitchens ?? 0;
    numberOfBalconies = widget.initial?.numberOfBalconies ?? 0;
    numberOfFamilyMembers = widget.initial?.numberOfFamilyMembers ?? 0;

    pricePerBed = TextEditingController(
        text: widget.initial?.pricePerBed != null &&
                widget.initial!.pricePerBed > 0
            ? widget.initial!.pricePerBed.toStringAsFixed(0)
            : '');
    pricePerKitchen = TextEditingController(
        text: widget.initial?.pricePerKitchen != null &&
                widget.initial!.pricePerKitchen > 0
            ? widget.initial!.pricePerKitchen.toStringAsFixed(0)
            : '');
    pricePerBalcony = TextEditingController(
        text: widget.initial?.pricePerBalcony != null &&
                widget.initial!.pricePerBalcony > 0
            ? widget.initial!.pricePerBalcony.toStringAsFixed(0)
            : '');
    pricePerFamilyMember = TextEditingController(
        text: widget.initial?.pricePerFamilyMember != null &&
                widget.initial!.pricePerFamilyMember > 0
            ? widget.initial!.pricePerFamilyMember.toStringAsFixed(0)
            : '');

    // Rebuild on every keystroke for live price preview
    for (final ctrl in [
      mrpPrice,
      sellingPrice,
      pricePerBed,
      pricePerKitchen,
      pricePerBalcony,
      pricePerFamilyMember,
    ]) {
      ctrl.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    name.dispose();
    mrpPrice.dispose();
    sellingPrice.dispose();
    description.dispose();
    duration.dispose();
    extraPricePerHour.dispose();
    pricePerBed.dispose();
    pricePerKitchen.dispose();
    pricePerBalcony.dispose();
    pricePerFamilyMember.dispose();
    super.dispose();
  }

  // ── Live price calculation ─────────────────────────────────────────────────
  double get _propertyTotal =>
      (numberOfBeds * (double.tryParse(pricePerBed.text.trim()) ?? 0)) +
      (numberOfKitchens *
          (double.tryParse(pricePerKitchen.text.trim()) ?? 0)) +
      (numberOfBalconies *
          (double.tryParse(pricePerBalcony.text.trim()) ?? 0)) +
      (numberOfFamilyMembers *
          (double.tryParse(pricePerFamilyMember.text.trim()) ?? 0));

  double get _calculatedFinalPrice {
    final base = double.tryParse(sellingPrice.text.trim()) ?? 0;
    final total = base + _propertyTotal;
    return total < 0 ? 0 : total;
  }

  bool get _hasDiscount {
    final mrp = double.tryParse(mrpPrice.text.trim()) ?? 0;
    final selling = double.tryParse(sellingPrice.text.trim()) ?? 0;
    return mrp > selling && mrp > 0 && selling > 0;
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  InputDecoration _inputDecoration(String label, {Widget? suffixIcon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.grey),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.grey.shade100,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.blue, width: 1.5),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4, left: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          color: Colors.teal,
        ),
      ),
    );
  }

  Widget _priceRow(String label, double amount, {Color? color}) {
    final isNegative = amount < 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '${isNegative ? '-' : '+'}₹${amount.abs().toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color ??
                  (isNegative ? Colors.red.shade400 : Colors.grey.shade800),
            ),
          ),
        ],
      ),
    );
  }

  Widget _propertyRow({
    required String label,
    required String icon,
    required int count,
    required VoidCallback onDecrement,
    required VoidCallback onIncrement,
    required TextEditingController priceController,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  Text(icon, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      label,
                      style: const TextStyle(fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  GestureDetector(
                    onTap: onDecrement,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color:
                            count > 0 ? Colors.teal : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.remove,
                          size: 14, color: Colors.white),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      '$count',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                  GestureDetector(
                    onTap: onIncrement,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.teal,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.add,
                          size: 14, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: TextFormField(
              controller: priceController,
              decoration: _inputDecoration('₹ / unit').copyWith(
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 14),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (count > 0 && (value == null || value.isEmpty)) {
                  return 'Enter price';
                }
                return null;
              },
            ),
          ),
        ],
      ),
    );
  }

  void _onSubmit() {
    if (_formKey.currentState!.validate()) {
      final service = ServiceModel(
        id: widget.initial?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        name: name.text.trim(),
        description: description.text.trim(),
        mrpPrice: double.parse(
            mrpPrice.text.isNotEmpty ? mrpPrice.text.trim() : '0'),
        sellingPrice: double.parse(sellingPrice.text.trim()),
        categoryId: selectedCategoryId!,
        categoryName: selectedCategoryName!,
        duration: duration.text.trim(),
        extraPricePerDuration:
            double.parse(extraPricePerHour.text.trim()),
        numberOfBeds: numberOfBeds,
        numberOfKitchens: numberOfKitchens,
        numberOfBalconies: numberOfBalconies,
        numberOfFamilyMembers: numberOfFamilyMembers,
        pricePerBed: pricePerBed.text.isNotEmpty
            ? double.parse(pricePerBed.text.trim())
            : 0,
        pricePerKitchen: pricePerKitchen.text.isNotEmpty
            ? double.parse(pricePerKitchen.text.trim())
            : 0,
        pricePerBalcony: pricePerBalcony.text.isNotEmpty
            ? double.parse(pricePerBalcony.text.trim())
            : 0,
        pricePerFamilyMember: pricePerFamilyMember.text.isNotEmpty
            ? double.parse(pricePerFamilyMember.text.trim())
            : 0,
      );

      if (widget.initial == null) {
        ref.read(maidServiceProvider.notifier).addService(service);
      } else {
        ref.read(maidServiceProvider.notifier).updateService(service);
      }
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.initial == null ? 'Add Service' : 'Edit Service',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.teal,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.teal),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Basic Info ──────────────────────────────────────────────
              _sectionHeader('Basic Info'),
              Padding(
                padding: const EdgeInsets.all(4.0),
                child: DropdownButtonFormField<String>(
                  value: selectedCategoryId != null &&
                          categories
                              .any((cat) => cat.id == selectedCategoryId)
                      ? selectedCategoryId
                      : null,
                  onChanged: (value) {
                    setState(() {
                      selectedCategoryId = value;
                      selectedCategoryName = categories
                          .firstWhere((cat) => cat.id == value)
                          .name;
                    });
                  },
                  validator: (value) =>
                      value == null ? 'Please select a category' : null,
                  decoration: _inputDecoration('Select Category'),
                  items: categories.map((cat) {
                    return DropdownMenuItem(
                      value: cat.id,
                      child: Text(cat.name),
                    );
                  }).toList(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(4.0),
                child: TextFormField(
                  controller: name,
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                  decoration: _inputDecoration('Service Name'),
                ),
              ),

              // ── Pricing ─────────────────────────────────────────────────
              _sectionHeader('Pricing'),
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 8),
                child: Text(
                  'MRP is shown as strikethrough. Selling price is what the customer pays.',
                  style:
                      TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ),

              // MRP + Selling Price side by side
              Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: TextFormField(
                        controller: mrpPrice,
                        decoration: _inputDecoration(
                          'MRP (₹)',
                          suffixIcon: const Tooltip(
                            message: 'Shown as strikethrough e.g. ₹699',
                            child: Icon(Icons.info_outline,
                                size: 18, color: Colors.grey),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        // MRP is optional — only show strikethrough if provided
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: TextFormField(
                        controller: sellingPrice,
                        decoration: _inputDecoration(
                          'Selling Price (₹)',
                          suffixIcon: const Tooltip(
                            message: 'Actual price customer pays e.g. ₹300',
                            child: Icon(Icons.info_outline,
                                size: 18, color: Colors.grey),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                    ),
                  ),
                ],
              ),

              // Live discount badge
              if (_hasDiscount)
                Padding(
                  padding: const EdgeInsets.only(left: 4, top: 4, bottom: 4),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.green.shade300),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.local_offer,
                                size: 14, color: Colors.green),
                            const SizedBox(width: 4),
                            Text(
                              '${(((double.tryParse(mrpPrice.text.trim()) ?? 0) - (double.tryParse(sellingPrice.text.trim()) ?? 0)) / (double.tryParse(mrpPrice.text.trim()) ?? 1) * 100).toStringAsFixed(0)}% off',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Customer saves ₹${((double.tryParse(mrpPrice.text.trim()) ?? 0) - (double.tryParse(sellingPrice.text.trim()) ?? 0)).toStringAsFixed(0)}',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),

              // ── Duration ────────────────────────────────────────────────
              _sectionHeader('Duration'),
              Padding(
                padding: const EdgeInsets.all(4.0),
                child: TextFormField(
                  controller: duration,
                  decoration: _inputDecoration('Duration (hrs)'),
                  keyboardType: TextInputType.number,
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(4.0),
                child: TextFormField(
                  controller: extraPricePerHour,
                  decoration: _inputDecoration('Extra Price / Hr (₹)'),
                  keyboardType: TextInputType.number,
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
              ),

              // ── Property Details ─────────────────────────────────────────
              _sectionHeader('Property Details'),
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 6),
                child: Text(
                  'Set count & price per unit — added on top of selling price',
                  style:
                      TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ),
              _propertyRow(
                label: 'Bedrooms',
                icon: '🛏️',
                count: numberOfBeds,
                onDecrement: () {
                  if (numberOfBeds > 0) setState(() => numberOfBeds--);
                },
                onIncrement: () => setState(() => numberOfBeds++),
                priceController: pricePerBed,
              ),
              _propertyRow(
                label: 'Kitchens',
                icon: '🍳',
                count: numberOfKitchens,
                onDecrement: () {
                  if (numberOfKitchens > 0) {
                    setState(() => numberOfKitchens--);
                  }
                },
                onIncrement: () => setState(() => numberOfKitchens++),
                priceController: pricePerKitchen,
              ),
              _propertyRow(
                label: 'Balconies',
                icon: '🏗️',
                count: numberOfBalconies,
                onDecrement: () {
                  if (numberOfBalconies > 0) {
                    setState(() => numberOfBalconies--);
                  }
                },
                onIncrement: () => setState(() => numberOfBalconies++),
                priceController: pricePerBalcony,
              ),
              _propertyRow(
                label: 'Family Members',
                icon: '👨‍👩‍👧',
                count: numberOfFamilyMembers,
                onDecrement: () {
                  if (numberOfFamilyMembers > 0) {
                    setState(() => numberOfFamilyMembers--);
                  }
                },
                onIncrement: () => setState(() => numberOfFamilyMembers++),
                priceController: pricePerFamilyMember,
              ),

              // ── Description ──────────────────────────────────────────────
              _sectionHeader('Description'),
              Padding(
                padding: const EdgeInsets.all(4.0),
                child: TextFormField(
                  controller: description,
                  decoration: _inputDecoration('Description'),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                  maxLines: 3,
                ),
              ),

              // ── Price Preview Card ───────────────────────────────────────
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.teal.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Price Breakdown',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.teal,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // MRP row (strikethrough style)
                    if (_hasDiscount)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '🏷️ MRP',
                              style: TextStyle(
                                  fontSize: 13, color: Colors.grey.shade500),
                            ),
                            Text(
                              '₹${(double.tryParse(mrpPrice.text.trim()) ?? 0).toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade500,
                                decoration: TextDecoration.lineThrough,
                                decorationColor: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Selling price row
                    _priceRow(
                      '💰 Selling Price',
                      double.tryParse(sellingPrice.text.trim()) ?? 0,
                    ),

                    // Property additions
                    if (numberOfBeds > 0)
                      _priceRow(
                        '🛏️ Beds ($numberOfBeds × ₹${pricePerBed.text.isEmpty ? 0 : pricePerBed.text})',
                        numberOfBeds *
                            (double.tryParse(pricePerBed.text.trim()) ?? 0),
                      ),
                    if (numberOfKitchens > 0)
                      _priceRow(
                        '🍳 Kitchens ($numberOfKitchens × ₹${pricePerKitchen.text.isEmpty ? 0 : pricePerKitchen.text})',
                        numberOfKitchens *
                            (double.tryParse(pricePerKitchen.text.trim()) ??
                                0),
                      ),
                    if (numberOfBalconies > 0)
                      _priceRow(
                        '🏗️ Balconies ($numberOfBalconies × ₹${pricePerBalcony.text.isEmpty ? 0 : pricePerBalcony.text})',
                        numberOfBalconies *
                            (double.tryParse(pricePerBalcony.text.trim()) ??
                                0),
                      ),
                    if (numberOfFamilyMembers > 0)
                      _priceRow(
                        '👨‍👩‍👧 Members ($numberOfFamilyMembers × ₹${pricePerFamilyMember.text.isEmpty ? 0 : pricePerFamilyMember.text})',
                        numberOfFamilyMembers *
                            (double.tryParse(
                                    pricePerFamilyMember.text.trim()) ??
                                0),
                      ),

                    const Divider(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Customer Pays',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          '₹${_calculatedFinalPrice.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.teal,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── Submit Button ────────────────────────────────────────────
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _onSubmit,
                child: Text(
                  widget.initial == null ? 'Add Service' : 'Update Service',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}