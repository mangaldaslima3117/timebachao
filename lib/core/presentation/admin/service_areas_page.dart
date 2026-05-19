import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/service_area_model.dart';
import '../../../services/service_area_provider.dart';
import '../../widgets/delete_confirmation_dialog.dart';

class ServiceAreasPage extends ConsumerStatefulWidget {
  const ServiceAreasPage({super.key});

  @override
  ConsumerState<ServiceAreasPage> createState() => _ServiceAreasPageState();
}

class _ServiceAreasPageState extends ConsumerState<ServiceAreasPage> {
  final _formKey = GlobalKey<FormState>();
  final _cityController = TextEditingController();
  final _areaController = TextEditingController();
  final _searchController = TextEditingController();

  bool _isServiceable = true;
  bool _isSaving = false;
  ServiceAreaModel? _editingArea;

  @override
  void dispose() {
    _cityController.dispose();
    _areaController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _saveArea() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSaving = true);

    final area = ServiceAreaModel(
      id: _editingArea?.id ?? '',
      city: _cityController.text.trim(),
      areaName: _areaController.text.trim(),
      cityKey: ServiceAreaModel.normalizeKey(_cityController.text),
      areaKey: ServiceAreaModel.normalizeKey(_areaController.text),
      isServiceable: _isServiceable,
    );

    try {
      await ref.read(serviceAreaProvider.notifier).addOrUpdateServiceArea(
            area,
            previousId: _editingArea?.id,
          );

      if (!mounted) return;
      _showSnack(
          _editingArea == null ? 'Service area saved' : 'Service area updated');
      _clearForm();
    } catch (_) {
      if (!mounted) return;
      _showSnack('Could not save service area. Please try again.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _editArea(ServiceAreaModel area) {
    setState(() {
      _editingArea = area;
      _cityController.text = area.city;
      _areaController.text = area.areaName;
      _isServiceable = area.isServiceable;
    });
  }

  void _clearForm() {
    setState(() {
      _editingArea = null;
      _cityController.clear();
      _areaController.clear();
      _isServiceable = true;
    });
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final areasAsync = ref.watch(serviceAreaProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0.5,
        shadowColor: Colors.grey.shade300,
        centerTitle: true,
        title: const Text(
          'Service Areas',
          style: TextStyle(
            color: Colors.teal,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _buildEditor(),
          const SizedBox(height: 16),
          _buildSearchField(),
          const SizedBox(height: 12),
          areasAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.only(top: 40),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, stackTrace) => _buildEmptyState(
              icon: Icons.error_outline,
              title: 'Could not load service areas',
              subtitle: 'Please check your connection and try again.',
            ),
            data: _buildAreaList,
          ),
        ],
      ),
    );
  }

  Widget _buildEditor() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.location_city_outlined, color: Colors.teal.shade600),
                const SizedBox(width: 8),
                Text(
                  _editingArea == null ? 'Add Area' : 'Edit Area',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (_editingArea != null)
                  TextButton(
                    onPressed: _clearForm,
                    child: const Text('Cancel'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _cityController,
              textCapitalization: TextCapitalization.words,
              decoration: _inputDecoration('City', Icons.location_city),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Enter city name';
                }
                return null;
              },
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _areaController,
              textCapitalization: TextCapitalization.words,
              decoration: _inputDecoration('Area Name', Icons.place_outlined),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Enter area name';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              activeColor: Colors.teal,
              title: const Text(
                'Serviceable',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(_isServiceable
                  ? 'Bookings are allowed in this area'
                  : 'Bookings are blocked in this area'),
              value: _isServiceable,
              onChanged: (value) => setState(() => _isServiceable = value),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                onPressed: _isSaving ? null : _saveArea,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(_editingArea == null ? 'Save Area' : 'Update Area'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.teal),
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.teal, width: 1.5),
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        hintText: 'Search city or area',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _searchController.text.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  _searchController.clear();
                  setState(() {});
                },
              ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
      ),
    );
  }

  Widget _buildAreaList(List<ServiceAreaModel> areas) {
    final query = ServiceAreaModel.normalizeKey(_searchController.text);
    final filteredAreas = query.isEmpty
        ? areas
        : areas
            .where(
              (area) =>
                  area.cityKey.contains(query) || area.areaKey.contains(query),
            )
            .toList();

    if (filteredAreas.isEmpty) {
      return _buildEmptyState(
        icon: Icons.place_outlined,
        title: 'No service areas found',
        subtitle: query.isEmpty
            ? 'Add your first city and area above.'
            : 'No city or area matches your search.',
      );
    }

    final groupedAreas = <String, List<ServiceAreaModel>>{};
    for (final area in filteredAreas) {
      groupedAreas.putIfAbsent(area.city, () => []).add(area);
    }

    final cities = groupedAreas.keys.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    return Column(
      children: [
        for (final city in cities) ...[
          _CityHeader(city: city, areas: groupedAreas[city]!),
          ...groupedAreas[city]!.map(_buildAreaTile),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _buildAreaTile(ServiceAreaModel area) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: area.isServiceable ? Colors.green : Colors.red,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  area.areaName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  area.isServiceable ? 'Open for booking' : 'Closed',
                  style: TextStyle(
                    color: area.isServiceable
                        ? Colors.green.shade700
                        : Colors.red.shade700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            activeColor: Colors.teal,
            value: area.isServiceable,
            onChanged: (value) async {
              try {
                await ref
                    .read(serviceAreaProvider.notifier)
                    .toggleServiceable(area, value);
              } catch (_) {
                if (mounted) {
                  _showSnack('Could not update area status.');
                }
              }
            },
          ),
          IconButton(
            tooltip: 'Edit',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => _editArea(area),
          ),
          IconButton(
            tooltip: 'Delete',
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () async {
              final confirmed = await showDeleteConfirmationDialog(
                context: context,
                title: 'Delete Service Area',
                content:
                    'Are you sure you want to delete ${area.areaName}, ${area.city}?',
              );

              if (confirmed == true) {
                try {
                  await ref
                      .read(serviceAreaProvider.notifier)
                      .deleteServiceArea(area.id);
                } catch (_) {
                  if (mounted) {
                    _showSnack('Could not delete service area.');
                  }
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      margin: const EdgeInsets.only(top: 28),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(icon, size: 52, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}

class _CityHeader extends StatelessWidget {
  final String city;
  final List<ServiceAreaModel> areas;

  const _CityHeader({
    required this.city,
    required this.areas,
  });

  @override
  Widget build(BuildContext context) {
    final activeCount = areas.where((area) => area.isServiceable).length;

    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              city,
              style: const TextStyle(
                color: Colors.teal,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.teal.shade50,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$activeCount/${areas.length} active',
              style: TextStyle(
                color: Colors.teal.shade700,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
