import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/category_provider.dart';
import '../../../services/service_provider.dart';
import '../../widgets/delete_confirmation_dialog.dart';
import '../../widgets/maid_service_bottomsheet.dart';

class ServicesPage extends ConsumerStatefulWidget {
  const ServicesPage({super.key});

  @override
  ConsumerState<ServicesPage> createState() => _ServicesPageState();
}

class _ServicesPageState extends ConsumerState<ServicesPage> {
  String? selectedCategoryId;

  @override
  Widget build(BuildContext context) {
    final services = ref.watch(maidServiceProvider);
    final categories = ref.watch(categoryProvider);

    final filteredServices =
        (selectedCategoryId == null || selectedCategoryId!.isEmpty)
            ? services
            : services
                .where((s) => s.categoryId == selectedCategoryId)
                .toList();

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0.5,
        shadowColor: Colors.grey.shade300,
        title: const Text(
          'Services',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.teal,
          ),
        ),
        centerTitle: true,
        actions: [
          if (categories.isNotEmpty)
            PopupMenuButton<String?>(
              icon: Icon(
                Icons.filter_list_rounded,
                color: (selectedCategoryId == null || selectedCategoryId!.isEmpty)
                    ? Colors.grey.shade600
                    : Colors.teal,
              ),
              tooltip: 'Filter by category',
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onSelected: (value) {
                setState(() => selectedCategoryId = value);
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: '',
                  child: Text('All Categories'),
                ),
                ...categories.map(
                  (cat) => PopupMenuItem(
                    value: cat.id,
                    child: Text(cat.name),
                  ),
                ),
              ],
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: filteredServices.isNotEmpty
          ? ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: filteredServices.length,
              itemBuilder: (context, index) {
                final service = filteredServices[index];
                return _ServiceCard(
                  service: service,
                  onEdit: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => MaidServiceBottomSheet(initial: service),
                  ),
                  onDelete: () async {
                    final confirmed = await showDeleteConfirmationDialog(
                      context: context,
                      title: 'Delete Service',
                      content:
                          'Are you sure you want to delete "${service.name}"?',
                    );
                    if (confirmed == true) {
                      ref
                          .read(maidServiceProvider.notifier)
                          .deleteService(service.id);
                    }
                  },
                );
              },
            )
          : Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cleaning_services_outlined,
                      size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'No services found',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Tap + to add your first service',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.teal,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Service',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MaidServiceBottomSheet()),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Service Card Widget
// ─────────────────────────────────────────────────────────────────────────────

class _ServiceCard extends StatelessWidget {
  final dynamic service; // Replace with ServiceModel
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ServiceCard({
    required this.service,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasProperties = service.numberOfBeds > 0 ||
        service.numberOfKitchens > 0 ||
        service.numberOfBalconies > 0 ||
        service.numberOfFamilyMembers > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────────
          _CardHeader(service: service, onEdit: onEdit, onDelete: onDelete),

          const Divider(height: 1, thickness: 0.8),

          // ── Price + Duration row ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                _InfoTile(
                  icon: Icons.currency_rupee_rounded,
                  label: 'Price',
                  child: service.hasDiscount
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              '₹${service.mrpPrice.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade500,
                                decoration: TextDecoration.lineThrough,
                                decorationColor: Colors.grey.shade500,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '₹${service.finalPrice.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Colors.teal,
                              ),
                            ),
                            const SizedBox(width: 6),
                            _DiscountBadge(
                              mrp: service.mrpPrice,
                              selling: service.sellingPrice,
                            ),
                          ],
                        )
                      : Text(
                          '₹${service.finalPrice.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal,
                          ),
                        ),
                ),
                const SizedBox(width: 20),
                if (service.duration.isNotEmpty)
                  _InfoTile(
                    icon: Icons.schedule_rounded,
                    label: 'Duration',
                    child: Row(
                      children: [
                        Text(
                          '${service.duration} hr',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (service.extraPricePerDuration > 0) ...[
                          const SizedBox(width: 4),
                          Text(
                            '+₹${service.extraPricePerDuration.toStringAsFixed(0)}/hr',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // ── Description ──────────────────────────────────────────────────
          if (service.description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: _LabeledSection(
                label: 'Description',
                child: Text(
                  service.description,
                  style: TextStyle(
                    fontSize: 13.5,
                    color: Colors.grey.shade800,
                    height: 1.4,
                  ),
                ),
              ),
            ),

          // ── Property Details ─────────────────────────────────────────────
          if (hasProperties) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Text(
                'Property Details',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade500,
                  letterSpacing: 0.4,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (service.numberOfBeds > 0)
                    _PropertyChip(
                      icon: Icons.bed_rounded,
                      label: 'Beds',
                      count: service.numberOfBeds,
                      price: service.pricePerBed,
                    ),
                  if (service.numberOfKitchens > 0)
                    _PropertyChip(
                      icon: Icons.countertops_rounded,
                      label: 'Kitchens',
                      count: service.numberOfKitchens,
                      price: service.pricePerKitchen,
                    ),
                  if (service.numberOfBalconies > 0)
                    _PropertyChip(
                      icon: Icons.balcony_rounded,
                      label: 'Balconies',
                      count: service.numberOfBalconies,
                      price: service.pricePerBalcony,
                    ),
                  if (service.numberOfFamilyMembers > 0)
                    _PropertyChip(
                      icon: Icons.people_alt_rounded,
                      label: 'Members',
                      count: service.numberOfFamilyMembers,
                      price: service.pricePerFamilyMember,
                    ),
                ],
              ),
            ),
          ],

          // ── Price Breakdown (if has properties) ─────────────────────────
          if (hasProperties && service.propertyTotal > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Base  +  Property add-ons',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Colors.teal.shade800,
                      ),
                    ),
                    Text(
                      '₹${service.sellingPrice.toStringAsFixed(0)}  +  ₹${service.propertyTotal.toStringAsFixed(0)}  =  ₹${service.finalPrice.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.teal.shade800,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 14),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Card Header
// ─────────────────────────────────────────────────────────────────────────────

class _CardHeader extends StatelessWidget {
  final dynamic service;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CardHeader({
    required this.service,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Leading circle avatar with first letter
          CircleAvatar(
            radius: 22,
            backgroundColor: Colors.teal.shade50,
            child: Text(
              service.name.isNotEmpty
                  ? service.name[0].toUpperCase()
                  : 'S',
              style: TextStyle(
                color: Colors.teal.shade700,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                if (service.categoryName.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.teal.shade200),
                    ),
                    child: Text(
                      service.categoryName,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Colors.teal.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Actions
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20),
            color: Colors.grey.shade600,
            tooltip: 'Edit',
            onPressed: onEdit,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20),
            color: Colors.red.shade400,
            tooltip: 'Delete',
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget child;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 13, color: Colors.grey.shade500),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        child,
      ],
    );
  }
}

class _LabeledSection extends StatelessWidget {
  final String label;
  final Widget child;

  const _LabeledSection({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            color: Colors.grey.shade500,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        child,
      ],
    );
  }
}

class _PropertyChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final double price;

  const _PropertyChip({
    required this.icon,
    required this.label,
    required this.count,
    required this.price,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: Colors.teal.shade600),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$count $label',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (price > 0)
                Text(
                  '₹${price.toStringAsFixed(0)}/unit',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DiscountBadge extends StatelessWidget {
  final double mrp;
  final double selling;

  const _DiscountBadge({required this.mrp, required this.selling});

  @override
  Widget build(BuildContext context) {
    if (mrp <= 0) return const SizedBox.shrink();
    final pct = ((mrp - selling) / mrp * 100).round();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Text(
        '$pct% off',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.green.shade700,
        ),
      ),
    );
  }
}