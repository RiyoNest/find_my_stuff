import 'package:find_my_stuff/shared/entities/storage_node_entity.dart';
import 'package:find_my_stuff/shared/enums/node_type.dart';
import 'package:find_my_stuff/shared/providers/storage_node_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

class QuickAddItemPage extends ConsumerStatefulWidget {
  const QuickAddItemPage({super.key});

  @override
  ConsumerState<QuickAddItemPage> createState() => _QuickAddItemPageState();
}

class _QuickAddItemPageState extends ConsumerState<QuickAddItemPage> {
  StorageNodeEntity? selectedDestination;

  final nameController = TextEditingController();

  final descriptionController = TextEditingController();

  final tagsController = TextEditingController();

  bool isImportant = false;

  bool trackExpiry = false;

  DateTime? expiryDate;

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    tagsController.dispose();
    super.dispose();
  }

  Future<void> _saveItem() async {
    if (selectedDestination == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a destination')),
      );
      return;
    }

    if (nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Item name is required')));
      return;
    }

    final repo = ref.read(storageNodeRepositoryProvider);

    final item = StorageNodeEntity(
      uuid: const Uuid().v4(),
      roomUuid: selectedDestination!.roomUuid,
      parentUuid: selectedDestination!.uuid,
      nodeType: NodeType.item.name,
      name: nameController.text.trim(),
      description: descriptionController.text.trim(),
      tags: tagsController.text.trim(),
      isImportant: isImportant,
      trackExpiry: trackExpiry,
      expiryDate: expiryDate,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    repo.save(item);

    ref.read(storageRefreshProvider.notifier).state++;

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Item added successfully')));

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final destinationsAsync = ref.watch(quickAddDestinationsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Quick Add Item')),
      body: destinationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (destinations) {
          final repo = ref.read(storageNodeRepositoryProvider);

          destinations.sort(
            (a, b) => repo
                .getPathToRoot(b)
                .length
                .compareTo(repo.getPathToRoot(a).length),
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add Item To',
                  style: Theme.of(context).textTheme.titleLarge,
                ),

                const SizedBox(height: 12),

                ...destinations.map((destination) {
                  final path = repo.buildPath(destination);

                  return RadioListTile<StorageNodeEntity>(
                    value: destination,
                    groupValue: selectedDestination,
                    title: Text(destination.name),
                    subtitle: Text(path),
                    onChanged: (value) {
                      setState(() {
                        selectedDestination = value;
                      });
                    },
                  );
                }),

                const Divider(height: 32),

                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Item Name *',
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 16),

                TextField(
                  controller: descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 16),

                TextField(
                  controller: tagsController,
                  decoration: const InputDecoration(
                    labelText: 'Tags',
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 16),

                SwitchListTile(
                  value: isImportant,
                  title: const Text('Important Item'),
                  onChanged: (value) {
                    setState(() {
                      isImportant = value;
                    });
                  },
                ),

                SwitchListTile(
                  value: trackExpiry,
                  title: const Text('Track Expiry'),
                  onChanged: (value) {
                    setState(() {
                      trackExpiry = value;
                    });
                  },
                ),

                if (trackExpiry)
                  ListTile(
                    title: Text(
                      expiryDate == null
                          ? 'Select Expiry Date'
                          : expiryDate.toString().split(' ').first,
                    ),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                        initialDate: DateTime.now(),
                      );

                      if (picked != null) {
                        setState(() {
                          expiryDate = picked;
                        });
                      }
                    },
                  ),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _saveItem,
                    icon: const Icon(Icons.save),
                    label: const Text('Save Item'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
