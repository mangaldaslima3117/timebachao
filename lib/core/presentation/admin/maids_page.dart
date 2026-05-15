
import 'package:bookmyservice/core/widgets/maids_account.dart';
import 'package:bookmyservice/models/category_model.dart';
import 'package:bookmyservice/models/maid_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/maids_provider.dart';
import '../../../services/skill_provider.dart';
import 'single_maid_sales_dashboard_page.dart';

class MaidsPage extends ConsumerStatefulWidget {
  const MaidsPage({super.key});

  @override
  ConsumerState<MaidsPage> createState() => _MaidsPageState();
}

class _MaidsPageState extends ConsumerState<MaidsPage> {
  String? selectedCategoryId;

  Future<List<String>?> showSkillsSelectorBottomSheet(
    BuildContext context,
    MaidModel maid,
    List<CategoryModel> allSkills,
  ) async {
    // final List<String> allSkills = [
    //   'Cooking',
    //   'Cleaning',
    //   'Babysitting',
    //   'Driving',
    //   'Elderly Care',
    //   'Gardening',
    //   'Laundry',
    //   'Shopping',
    // ];

    // Use a set to avoid duplicates and start with current selections
    Set<String> selectedSkills = Set<String>.from(maid.skills);

    return await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.only(
            top: 16,
            left: 16,
            right: 16,
            bottom: 32,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Select Skills',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              StatefulBuilder(
                builder: (context, setState) {
                  return Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: allSkills.map((skill) {
                      final isSelected = selectedSkills.contains(skill.name);

                      return FilterChip(
                        selectedColor: Colors.blue.shade100,
                        label: Text(skill.name),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              selectedSkills.add(skill.name);
                            } else {
                              selectedSkills.remove(skill.name);
                            }
                          });
                        },
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  debugPrint('Selected Skills: $selectedSkills');
                  ref
                      .read(maidAccountProvider.notifier)
                      .updateMaidSkills(maid, selectedSkills.toList());
                  Navigator.pop(context, selectedSkills.toList());
                },
                child: const Text('Save Skills'),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final maids = ref.watch(maidAccountProvider);
    final skills = ref.watch(skillProvider);

    // Filter logic
    // final filteredServices =
    //     (selectedCategoryId == null || selectedCategoryId!.isEmpty)
    //         ? maids
    //         : maids
    //             .where((service) => service.categoryId == selectedCategoryId)
    //             .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Maids',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.teal,
          ),
        ),
        centerTitle: true,
        // actions: [
        //   // Filter icon
        //   if (categories.isNotEmpty)
        //     PopupMenuButton<String?>(
        //       icon: const Icon(Icons.filter_list),
        //       onSelected: (value) {
        //         setState(() {
        //           selectedCategoryId = value;
        //         });
        //         debugPrint('Selected category: $selectedCategoryId');
        //       },
        //       itemBuilder: (context) => [
        //         const PopupMenuItem(
        //           value: '',
        //           child: Text('All Categories'),
        //         ),
        //         ...categories.map(
        //           (cat) => PopupMenuItem(
        //             value: cat.id,
        //             child: Text(cat.name),
        //           ),
        //         ),
        //       ],
        //     )
        // ],
      ),
      body: maids.isNotEmpty
          ? SingleChildScrollView(
              child: Column(
                children: [
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const ScrollPhysics(),
                    itemCount: maids.length,
                    itemBuilder: (context, index) {
                      final maid = maids[index];
                      return GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SingleMaidSalesDashboardPage(
                              maid: maid,
                            ),
                          ),
                        ),
                        child: Dismissible(
                          key: Key(maid.id),
                          direction: DismissDirection.startToEnd,
                          confirmDismiss: (_) async {
                            return await showDialog(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text('Delete Item?'),
                                content: const Text(
                                    'Are you sure you want to delete this item?'),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text(
                                      'Cancel',
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      ref
                                          .read(maidAccountProvider.notifier)
                                          .deleteMaid(maid.id);
                                      Navigator.pop(context, true);
                                    },
                                    child: const Text(
                                      'Delete',
                                      style: TextStyle(
                                        color: Colors.red,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                          onDismissed: (_) {
                            // perform delete
                          },
                          background: Container(
                            alignment: Alignment.centerRight,
                            color: Colors.red,
                            padding: const EdgeInsets.only(right: 16),
                            child: const Icon(Icons.delete, color: Colors.white),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(
                                  15,
                                ),
                                //color: Colors.grey.shade300,
                        
                                // border: Border.all(
                                //   color: Colors.grey,
                                // ),
                              ),
                              child: Card(
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                elevation: 4,
                                margin: const EdgeInsets.all(5),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    children: [
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Profile Image
                        
                                          CircleAvatar(
                                            radius: 40,
                                            backgroundImage: maid
                                                            .profilePictureUrl !=
                                                        null &&
                                                    maid.profilePictureUrl!
                                                        .isNotEmpty
                                                ? CachedNetworkImageProvider(
                                                    cacheKey:
                                                        maid.profilePictureUrl!,
                                                    maid.profilePictureUrl!,
                                                  )
                                                : const AssetImage(
                                                    'assets/images/profile_picture.png',
                                                  ) as ImageProvider,
                                            backgroundColor: Colors.grey[200],
                                          ),
                                          const SizedBox(width: 16),
                        
                                          // Info section
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                // Name
                                                Text(
                                                  maid.name,
                                                  style: const TextStyle(
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                // Gender and Status
                                                Row(
                                                  children: [
                                                    Text(
                                                        "Gender: ${maid.gender}"),
                                                    const SizedBox(width: 20),
                                                  ],
                                                ),
                                                const SizedBox(height: 8),
                                                Row(
                                                  children: [
                                                    const Text(
                                                      "Status: ",
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                    Text(
                                                      maid.isAvailable
                                                          ? 'Available'
                                                          : 'Work in progress',
                                                      style: TextStyle(
                                                        color: maid.isAvailable
                                                            ? Colors.green
                                                            : Colors.orange,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 12),
                        
                                                // Skills + Edit Icon
                                              ],
                                            ),
                                          ),
                        
                                          // Edit Button
                                          IconButton(
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) => MaidsAccount(
                                                    maid: maid,
                                                  ),
                                                ),
                                              );
                                            },
                                            icon: const Icon(
                                              Icons.edit,
                                              size: 20,
                                              color: Colors.orange,
                                            ),
                                            tooltip: "Edit Skills",
                                          ),
                                        ],
                                      ),
                                      const SizedBox(
                                        height: 12,
                                      ),
                                      Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            "Skills: ",
                                            style: TextStyle(
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Wrap(
                                                  spacing: 4.0,
                                                  runSpacing: 0.0,
                                                  children:
                                                      maid.skills.map((skill) {
                                                    return Chip(
                                                      label: Text(
                                                        skill,
                                                        style: const TextStyle(
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                        horizontal: 4,
                                                        vertical: 0,
                                                      ),
                                                      backgroundColor:
                                                          Colors.grey[200],
                                                      shape:
                                                          RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                                16),
                                                      ),
                                                    );
                                                  }).toList(),
                                                ),
                                              ),
                                              IconButton(
                                                onPressed: () {
                                                  showSkillsSelectorBottomSheet(
                                                    context,
                                                    maid,
                                                    skills, //These are all skills
                                                  );
                                                },
                                                icon: const Icon(
                                                  Icons.edit_note,
                                                  size: 20,
                                                  color: Colors.teal,
                                                ),
                                                tooltip: "Edit Skills",
                                              ),
                                            ],
                                          ),
                                        ],
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(
                    height: 100,
                  ),
                ],
              ),
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
          Icons.person_add_alt_1_rounded,
          color: Colors.teal,
          size: 30,
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const MaidsAccount(),
            ),
          );
        },
      ),
    );
  }
}
