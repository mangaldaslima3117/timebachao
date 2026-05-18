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
  Future<void> _showSkillsSelectorBottomSheet(
    BuildContext context,
    MaidModel maid,
    List<CategoryModel> allSkills,
  ) async {
    Set<String> selectedSkills = Set<String>.from(maid.skills);

    await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Edit Skills',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'Select all skills that apply to ${maid.name}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              StatefulBuilder(
                builder: (context, setModalState) {
                  return Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: allSkills.map((skill) {
                      final isSelected = selectedSkills.contains(skill.name);
                      return FilterChip(
                        label: Text(
                          skill.name,
                          style: TextStyle(
                            fontSize: 12,
                            color: isSelected ? Colors.teal : Colors.black87,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: Colors.teal.shade50,
                        checkmarkColor: Colors.teal,
                        side: BorderSide(
                          color: isSelected
                              ? Colors.teal
                              : Colors.grey.shade300,
                        ),
                        backgroundColor: Colors.grey.shade50,
                        onSelected: (selected) {
                          setModalState(() {
                            selected
                                ? selectedSkills.add(skill.name)
                                : selectedSkills.remove(skill.name);
                          });
                        },
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  ref
                      .read(maidAccountProvider.notifier)
                      .updateMaidSkills(maid, selectedSkills.toList());
                  Navigator.pop(context, selectedSkills.toList());
                },
                child: const Text(
                  'Save Skills',
                  style: TextStyle(color: Colors.white, fontSize: 15),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<bool> _confirmDelete(BuildContext context, MaidModel maid) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text(
              'Delete Maid?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: Text(
              'Are you sure you want to delete ${maid.name}? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  ref.read(maidAccountProvider.notifier).deleteMaid(maid.id);
                  Navigator.pop(context, true);
                },
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final maids = ref.watch(maidAccountProvider);
    final skills = ref.watch(skillProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          children: [
            const Text(
              'Maids',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.teal,
              ),
            ),
            Text(
              '${maids.length} registered',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: maids.isNotEmpty
          ? ListView.builder(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: maids.length,
              itemBuilder: (context, index) {
                final maid = maids[index];
                return _buildMaidCard(context, maid, skills);
              },
            )
          : _buildEmptyState(),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.teal,
        icon: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white),
        label: const Text(
          'Add Maid',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MaidsAccount()),
        ),
      ),
    );
  }

  Widget _buildMaidCard(
    BuildContext context,
    MaidModel maid,
    List<CategoryModel> skills,
  ) {
    final isAvailable = maid.isAvailable;

    return Dismissible(
      key: Key(maid.id),
      direction: DismissDirection.startToEnd,
      confirmDismiss: (_) => _confirmDelete(context, maid),
      onDismissed: (_) {},
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: const Row(
          children: [
            Icon(Icons.delete_outline, color: Colors.white, size: 22),
            SizedBox(width: 8),
            Text(
              'Delete',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SingleMaidSalesDashboardPage(maid: maid),
          ),
        ),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade100),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Top row: avatar + info + edit ──────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar with availability ring
                    Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isAvailable
                                  ? Colors.green
                                  : Colors.orange,
                              width: 2,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 34,
                            backgroundImage: maid.profilePictureUrl != null &&
                                    maid.profilePictureUrl!.isNotEmpty
                                ? CachedNetworkImageProvider(
                                    maid.profilePictureUrl!,
                                    cacheKey: maid.profilePictureUrl!,
                                  )
                                : const AssetImage(
                                        'assets/images/profile_picture.png')
                                    as ImageProvider,
                            backgroundColor: Colors.grey.shade200,
                          ),
                        ),
                        // Online dot
                        Positioned(
                          bottom: 2,
                          right: 2,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: isAvailable
                                  ? Colors.green
                                  : Colors.orange,
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 14),

                    // Name + details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            maid.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.person_outline,
                                  size: 13, color: Colors.grey.shade400),
                              const SizedBox(width: 4),
                              Text(
                                maid.gender,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          // Availability badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isAvailable
                                  ? Colors.green.shade50
                                  : Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isAvailable
                                    ? Colors.green.shade200
                                    : Colors.orange.shade200,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isAvailable
                                      ? Icons.check_circle_outline
                                      : Icons.work_outline,
                                  size: 12,
                                  color: isAvailable
                                      ? Colors.green
                                      : Colors.orange,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isAvailable
                                      ? 'Available'
                                      : 'Work in Progress',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isAvailable
                                        ? Colors.green
                                        : Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Action buttons
                    Column(
                      children: [
                        _actionButton(
                          icon: Icons.bar_chart_rounded,
                          color: Colors.teal,
                          tooltip: 'View Dashboard',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  SingleMaidSalesDashboardPage(maid: maid),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        _actionButton(
                          icon: Icons.edit_outlined,
                          color: Colors.orange,
                          tooltip: 'Edit Profile',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => MaidsAccount(maid: maid),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // ── Divider ─────────────────────────────────────────────
                if (maid.skills.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Divider(height: 1, color: Colors.grey.shade100),
                  const SizedBox(height: 10),

                  // ── Skills row ───────────────────────────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: maid.skills.map((skill) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.teal.shade50,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: Colors.teal.shade100),
                              ),
                              child: Text(
                                skill,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.teal.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      // Edit skills button
                      GestureDetector(
                        onTap: () => _showSkillsSelectorBottomSheet(
                            context, maid, skills),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.teal.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.edit_note_rounded,
                            size: 18,
                            color: Colors.teal.shade600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                // ── Swipe hint (first card only) ─────────────────────────
                if (maid == ref.read(maidAccountProvider).first) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.swipe_right_outlined,
                          size: 12, color: Colors.grey.shade300),
                      const SizedBox(width: 4),
                      Text(
                        'Swipe right to delete',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade300,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 72, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No maids registered yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tap the button below to add a maid',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }
}