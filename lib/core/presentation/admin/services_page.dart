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

    // Filter logic
    final filteredServices =
        (selectedCategoryId == null || selectedCategoryId!.isEmpty)
            ? services
            : services
                .where((service) => service.categoryId == selectedCategoryId)
                .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Services',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.teal,
          ),
        ),
        centerTitle: true,
        actions: [
          // Filter icon
          if (categories.isNotEmpty)
            PopupMenuButton<String?>(
              icon: const Icon(
                Icons.filter_list,
                color: Colors.teal,
              ),
              onSelected: (value) {
                setState(() {
                  selectedCategoryId = value;
                });
                debugPrint('Selected category: $selectedCategoryId');
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
            )
        ],
      ),
      body: filteredServices.isNotEmpty
          ? ListView.builder(
              itemCount: filteredServices.length,
              itemBuilder: (context, index) {
                final service = filteredServices[index];
                return Padding(
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
                      //color: Colors.teal.shade50,
                      shadowColor: Colors.teal.shade700,
                      elevation: 3,
                      borderOnForeground: true,
                      child: ListTile(
                        isThreeLine: true,
                        title: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              service.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Service Name',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                        subtitle: Wrap(
                          direction: Axis.vertical,
                          children: [
                            SizedBox(
                              height:
                                  MediaQuery.of(context).size.height * 0.002,
                            ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                service.discountPrice > 0
                                    ? Row(
                                        children: [
                                          Text(
                                            '₹${service.minPrice.toStringAsFixed(0)}',
                                            style: TextStyle(
                                              color: Colors.grey.shade400,
                                              fontSize: 14,
                                              decoration:
                                                  TextDecoration.lineThrough,
                                              decorationColor:
                                                  Colors.grey.shade600,
                                            ),
                                          ),
                                          const SizedBox(
                                            width: 10,
                                          ),
                                          Text(
                                            '₹${service.discountPrice.toStringAsFixed(0)}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ],
                                      )
                                    : Text(
                                        '₹${service.minPrice.toStringAsFixed(0)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                Text(
                                  'Price',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(
                              height:
                                  MediaQuery.of(context).size.height * 0.002,
                            ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      service.duration.isNotEmpty
                                          ? '${service.duration} hr'
                                          : '',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      service.extraPricePerDuration > 0
                                          ? '  (extra ₹${service.extraPricePerDuration.toStringAsFixed(0)}/hr)'
                                          : '',
                                      style: const TextStyle(
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  'Duration',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(
                              height:
                                  MediaQuery.of(context).size.height * 0.002,
                            ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width:
                                      MediaQuery.of(context).size.width * 0.85,
                                  child: Text(
                                    service.description,
                                    softWrap: true,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Text(
                                  'Description',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: Wrap(
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.edit,
                                size: 20,
                              ),
                              onPressed: () => showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                builder: (_) =>
                                    MaidServiceBottomSheet(initial: service),
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
                                    title: 'Delete Service',
                                    content:
                                        'Are you sure you want to delete this ${service.name}?',
                                  );
                                  if (confirmed == true) {
                                    ref
                                        .read(maidServiceProvider.notifier)
                                        .deleteService(service.id);
                                  }
                                }),
                          ],
                        ),
                      ),
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
          builder: (_) => const MaidServiceBottomSheet(),
        ),
      ),
    );
  }
}
