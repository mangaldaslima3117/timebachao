import 'package:bookmyservice/core/widgets/delete_confirmation_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/category_provider.dart';
import '../../../services/skill_provider.dart';
import '../../widgets/service_category_bottomsheet.dart';
import '../../widgets/skill_bottomsheetmodal.dart';

class MaidSkillsPage extends ConsumerStatefulWidget {
  const MaidSkillsPage({super.key});

  @override
  ConsumerState<MaidSkillsPage> createState() => _MaidSkillsPageState();
}

class _MaidSkillsPageState extends ConsumerState<MaidSkillsPage> {
  String? selectedCategoryId;

  @override
  Widget build(BuildContext context) {
    final skills = ref.watch(skillProvider);

    // Filter logic

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Maid Skills',
          style: TextStyle(
            color: Colors.teal,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: skills.isNotEmpty
          ? ListView.builder(
              itemCount: skills.length,
              itemBuilder: (context, index) {
                final skill = skills[index];
                return Padding(
                  padding: const EdgeInsets.all(3.0),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                        10,
                      ),
                      color: Colors.grey.shade100,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 10,
                        ),
                        SizedBox(
                          width: MediaQuery.of(context).size.width * 0.6,
                          child: Text(
                            skill.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.edit,
                            size: 20,
                          ),
                          onPressed: () => showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            builder: (_) => SkillBottomSheet(initial: skill),
                          ),
                        ),
                        // SizedBox(
                        //   height: MediaQuery.of(context).size.height * 0.01,
                        // ),
                        IconButton(
                            icon: const Icon(
                              Icons.delete,
                              color: Colors.red,
                              size: 20,
                            ),
                            onPressed: () async {
                              final confirmed =
                                  await showDeleteConfirmationDialog(
                                context: context,
                                title: 'Delete Category',
                                content:
                                    'Are you sure you want to delete this ${skill.name}?',
                              );
                              if (confirmed == true) {
                                ref
                                    .read(categoryProvider.notifier)
                                    .deleteCategory(skill.id);
                              }
                            }),
                      ],
                    ),
                  ),
                );
              },
            )
          : Container(
              alignment: Alignment.center,
              child: const Text(
                'No services available',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(
          Icons.add,
          color: Colors.teal,
          size: 30,
        ),
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (_) => const SkillBottomSheet(),
        ),
      ),
    );
  }
}
