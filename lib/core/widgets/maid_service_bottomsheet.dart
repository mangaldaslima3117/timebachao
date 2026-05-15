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
      minPrice,
      maxPrice,
      duration,
      discountPrice,
      extraPricePerHour;
  String? selectedCategoryId;
  String? selectedCategoryName;

  @override
  void initState() {
    super.initState();
    name = TextEditingController(text: widget.initial?.name ?? '');
    minPrice =
        TextEditingController(text: widget.initial?.minPrice.toString() ?? '');
    maxPrice =
        TextEditingController(text: widget.initial?.maxPrice.toString() ?? '');
    description =
        TextEditingController(text: widget.initial?.description ?? '');
    selectedCategoryId = widget.initial?.categoryId ?? '';
    selectedCategoryName = widget.initial?.categoryName ?? '';
    duration = TextEditingController(text: widget.initial?.duration ?? '');
    discountPrice = TextEditingController(
        text: widget.initial?.discountPrice.toString() ?? '');
    extraPricePerHour = TextEditingController(
        text: widget.initial?.extraPricePerDuration.toString() ?? '');
  }

  @override
  void dispose() {
    name.dispose();
    minPrice.dispose();
    description.dispose();
    maxPrice.dispose();
    duration.dispose();
    discountPrice.dispose();
    extraPricePerHour.dispose();
    super.dispose();
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final categories = ref.watch(categoryProvider);
    return Padding(
      padding: MediaQuery.of(context).viewInsets + const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.center,
            children: [
              Text(
                widget.initial == null ? 'Add Service' : 'Edit Service',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              // 🟡 Category Dropdown
              Padding(
                padding: const EdgeInsets.all(4.0),
                child: DropdownButtonFormField<String>(
                  value: selectedCategoryId != null &&
                          categories.any((cat) => cat.id == selectedCategoryId)
                      ? selectedCategoryId
                      : null,
                  onChanged: (value) {
                    setState(() {
                      selectedCategoryId = value;
                      selectedCategoryName =
                          categories.firstWhere((cat) => cat.id == value).name;
                    });
                  },
                  validator: (value) =>
                      value == null ? 'Please select a category' : null,
                  decoration: InputDecoration(
                    labelText: 'Select Category',
                    labelStyle: const TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: Colors.blue, width: 1.5),
                    ),
                  ),
                  items: categories.map((cat) {
                    return DropdownMenuItem(
                      value: cat.id,
                      child: Text(
                        cat.name,
                      ),
                    );
                  }).toList(),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(4.0),
                child: TextFormField(
                  controller: name,
                  validator: (value) => value!.isEmpty ? 'Required' : null,
                  keyboardType: TextInputType.text,
                  decoration: InputDecoration(
                    labelText: 'Service Name',
                    labelStyle: const TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: Colors.blue, width: 1.5),
                    ),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(4.0),
                child: TextFormField(
                  controller: minPrice,
                  decoration: InputDecoration(
                    labelText: 'Base Price',
                    labelStyle: const TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: Colors.blue, width: 1.5),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) => value!.isEmpty ? 'Required' : null,
                ),
              ),

              // TextFormField(
              //   controller: maxPrice,
              //   decoration: InputDecoration(
              //     labelText: 'Max Price',
              //     labelStyle: const TextStyle(color: Colors.grey),
              //     filled: true,
              //     fillColor: Colors.grey.shade100,
              //     contentPadding:
              //         const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              //     border: OutlineInputBorder(
              //       borderRadius: BorderRadius.circular(12),
              //       borderSide: BorderSide(color: Colors.grey.shade300),
              //     ),
              //     focusedBorder: OutlineInputBorder(
              //       borderRadius: BorderRadius.circular(12),
              //       borderSide:
              //           const BorderSide(color: Colors.blue, width: 1.5),
              //     ),
              //   ),
              //   keyboardType: TextInputType.number,
              //   validator: (value) => value!.isEmpty ? 'Required' : null,
              // ),
              // SizedBox(
              //   height: MediaQuery.of(context).size.height * 0.08,
              // ),
              Padding(
                padding: const EdgeInsets.all(4.0),
                child: TextFormField(
                  controller: discountPrice,
                  decoration: InputDecoration(
                    labelText: 'Discount Price',
                    labelStyle: const TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: Colors.blue, width: 1.5),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) => value!.isEmpty ? 'Required' : null,
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(4.0),
                child: TextFormField(
                  controller: duration,
                  decoration: InputDecoration(
                    labelText: 'Duration/Hr',
                    labelStyle: const TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: Colors.blue, width: 1.5),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) => value!.isEmpty ? 'Required' : null,
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(4.0),
                child: TextFormField(
                  controller: extraPricePerHour,
                  decoration: InputDecoration(
                    labelText: 'Extra Price /Hr',
                    labelStyle: const TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: Colors.blue, width: 1.5),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) => value!.isEmpty ? 'Required' : null,
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(4.0),
                child: TextFormField(
                  controller: description,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    labelStyle: const TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: Colors.blue, width: 1.5),
                    ),
                  ),
                  validator: (value) => value!.isEmpty ? 'Required' : null,
                  maxLines: 3,
                ),
              ),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.1,
              ),
              Align(
                alignment: Alignment.center,
                child: ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all<Color>(
                      Colors.green,
                    ),
                  ),
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      final service = ServiceModel(
                        id: widget.initial?.id ??
                            DateTime.now().millisecondsSinceEpoch.toString(),
                        name: name.text.trim(),
                        description: description.text.trim(),
                        minPrice: double.parse(minPrice.text.trim()),
                        maxPrice: double.parse(maxPrice.text.isNotEmpty ? maxPrice.text.trim() : '0'),
                        categoryId: selectedCategoryId!,
                        categoryName: selectedCategoryName!,
                        duration: duration.text.trim(),
                        discountPrice: double.parse(discountPrice.text.trim()),
                        extraPricePerDuration:
                            double.parse(extraPricePerHour.text.trim()),
                      );

                      if (widget.initial == null) {
                        ref
                            .read(maidServiceProvider.notifier)
                            .addService(service);
                      } else {
                        ref
                            .read(maidServiceProvider.notifier)
                            .updateService(service);
                      }

                      Navigator.pop(context);
                    }
                  },
                  child: Text(
                    widget.initial == null ? 'Add' : 'Update',
                    style: const TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.2,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
