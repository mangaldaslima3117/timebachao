import 'package:bookmyservice/models/category_model.dart';
import 'package:bookmyservice/services/category_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/skill_provider.dart';

class SkillBottomSheet extends ConsumerStatefulWidget {
  final CategoryModel? initial;
  const SkillBottomSheet({this.initial, super.key});

  @override
  ConsumerState<SkillBottomSheet> createState() => _SkillBottomSheetState();
}

class _SkillBottomSheetState extends ConsumerState<SkillBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController name, description, minPrice, maxPrice;

  @override
  void initState() {
    super.initState();
    name = TextEditingController(text: widget.initial?.name ?? '');
  }

  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Padding(
      padding: MediaQuery.of(context).viewInsets + const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          alignment: WrapAlignment.center,
          children: [
            Text(
              widget.initial == null ? 'Add Skill' : 'Edit Skill',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            // 🟡 Category Dropdown

            TextFormField(
              controller: name,
              validator: (value) => value!.isEmpty ? 'Required' : null,
              keyboardType: TextInputType.text,
              decoration: InputDecoration(
                labelText: 'Category Name',
                labelStyle: const TextStyle(color: Colors.grey),
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
              ),
            ),
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.08,
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
                    final category = CategoryModel(
                      id: widget.initial?.id ?? DateTime.now().toString(),
                      name: name.text.trim(),
                    );

                    if (widget.initial == null) {
                      ref.read(skillProvider.notifier).addSkill(category);
                    } else {
                      ref.read(skillProvider.notifier).updateSkill(category);
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
    );
  }
}
