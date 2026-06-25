// File: lib/features/storage_tree/presentation/pages/move_node_page.dart
//
// CHANGES:
//   - Destination list is now a fixed-height searchable card (same
//     pattern as the updated QuickAddItemPage) instead of an unbounded
//     RadioListTile list. At 20+ destinations the old list was painful.
//   - Selected destination shown as a chip above the list.
//   - "Move Here" button disabled until a valid destination is selected.
//   - Raw ScaffoldMessenger SnackBars replaced with AppSnackBar.
//   - Error state shown properly instead of just Text(e.toString()).

import 'package:find_my_stuff/core/constants/app_colours.dart';
import 'package:find_my_stuff/core/constants/app_radius.dart';
import 'package:find_my_stuff/core/constants/app_spacing.dart';
import 'package:find_my_stuff/shared/entities/storage_node_entity.dart';
import 'package:find_my_stuff/shared/providers/storage_node_providers.dart';
import 'package:find_my_stuff/shared/widgets/custom_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MoveNodePage extends ConsumerStatefulWidget {
  final StorageNodeEntity node;

  const MoveNodePage({super.key, required this.node});

  @override
  ConsumerState<MoveNodePage> createState() => _MoveNodePageState();
}

class _MoveNodePageState extends ConsumerState<MoveNodePage> {
  StorageNodeEntity? _selectedDestination;
  final _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isMoving = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(
          () => setState(() => _searchQuery = _searchController.text.toLowerCase()),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _moveNode() async {
    if (_selectedDestination == null) {
      AppSnackBar.warning(context, 'Please select a destination');
      return;
    }

    final repo = ref.read(storageNodeRepositoryProvider);
    final canMove = repo.canMoveNode(
      widget.node.uuid,
      _selectedDestination!.uuid,
    );

    if (!canMove) {
      AppSnackBar.error(
        context,
        "Can't move here — a node cannot be moved into itself or its own descendants",
      );
      return;
    }

    setState(() => _isMoving = true);

    try {
      repo.moveNode(widget.node.uuid, _selectedDestination!.uuid);
      ref.read(storageRefreshProvider.notifier).state++;

      if (mounted) {
        AppSnackBar.success(
          context,
          '"${widget.node.name}" moved to "${_selectedDestination!.name}"',
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.error(context, "Couldn't move item. Please try again.");
      }
    } finally {
      if (mounted) setState(() => _isMoving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final destinationsAsync =
    ref.watch(moveDestinationsProvider(widget.node));

    return Scaffold(
      appBar: AppBar(title: Text('Move "${widget.node.name}"')),
      body: destinationsAsync.when(
        loading: () =>
        const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(RAppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 40),
                const SizedBox(height: RAppSpacing.sm),
                Text(
                  "Couldn't load destinations",
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: RAppSpacing.xs),
                Text(e.toString(), style: theme.textTheme.bodyMedium),
                const SizedBox(height: RAppSpacing.md),
                TextButton.icon(
                  onPressed: () =>
                      ref.invalidate(moveDestinationsProvider(widget.node)),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (destinations) {
          final repo = ref.read(storageNodeRepositoryProvider);

          if (destinations.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(RAppSpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.folder_off_outlined,
                      size: 48,
                      color: theme.colorScheme.outline,
                    ),
                    const SizedBox(height: RAppSpacing.sm),
                    Text(
                      'No valid destinations',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: RAppSpacing.xs),
                    Text(
                      'Add more locations or containers to move this item.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            );
          }

          final filtered = _searchQuery.isEmpty
              ? destinations
              : destinations.where((d) {
            final path = repo.buildPath(d).toLowerCase();
            return d.name.toLowerCase().contains(_searchQuery) ||
                path.contains(_searchQuery);
          }).toList();

          return Padding(
            padding: const EdgeInsets.all(RAppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Move to', style: theme.textTheme.titleLarge),
                const SizedBox(height: RAppSpacing.xs),
                Text(
                  'Choose the new location for this item',
                  style: theme.textTheme.bodyMedium,
                ),

                // Selected destination chip
                if (_selectedDestination != null) ...[
                  const SizedBox(height: RAppSpacing.sm),
                  Chip(
                    avatar: Icon(
                      Icons.check_circle,
                      size: 16,
                      color: RAppColors.success,
                    ),
                    label: Text(
                      _selectedDestination!.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () =>
                        setState(() => _selectedDestination = null),
                  ),
                ],

                const SizedBox(height: RAppSpacing.sm),

                // Fixed-height searchable list
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: RAppColors.border),
                      borderRadius: BorderRadius.circular(RAppRadius.md),
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(RAppSpacing.sm),
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Search locations...',
                              prefixIcon:
                              const Icon(Icons.search, size: 20),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                icon: const Icon(Icons.clear,
                                    size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                                  : null,
                              isDense: true,
                              contentPadding:
                              const EdgeInsets.symmetric(
                                horizontal: RAppSpacing.sm,
                                vertical: RAppSpacing.sm,
                              ),
                              border: OutlineInputBorder(
                                borderRadius:
                                BorderRadius.circular(RAppRadius.sm),
                              ),
                            ),
                          ),
                        ),
                        const Divider(height: 1),
                        Expanded(
                          child: filtered.isEmpty
                              ? Center(
                            child: Text(
                              'No matches for "$_searchQuery"',
                              style: theme.textTheme.bodyMedium
                                  ?.copyWith(
                                color: RAppColors.textSecondary,
                              ),
                            ),
                          )
                              : ListView.builder(
                            padding: EdgeInsets.zero,
                            itemCount: filtered.length,
                            itemBuilder: (_, index) {
                              final dest = filtered[index];
                              final path =
                              repo.buildPath(dest);
                              final isSelected =
                                  _selectedDestination?.uuid ==
                                      dest.uuid;

                              return InkWell(
                                onTap: () => setState(
                                      () => _selectedDestination =
                                      dest,
                                ),
                                child: Container(
                                  color: isSelected
                                      ? theme
                                      .colorScheme
                                      .primaryContainer
                                      .withOpacity(0.4)
                                      : null,
                                  padding:
                                  const EdgeInsets.symmetric(
                                    horizontal: RAppSpacing.md,
                                    vertical: RAppSpacing.sm,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        isSelected
                                            ? Icons
                                            .radio_button_checked
                                            : Icons
                                            .radio_button_unchecked,
                                        size: 20,
                                        color: isSelected
                                            ? theme.colorScheme
                                            .primary
                                            : RAppColors
                                            .textSecondary,
                                      ),
                                      const SizedBox(
                                        width: RAppSpacing.sm,
                                      ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                          CrossAxisAlignment
                                              .start,
                                          children: [
                                            Text(
                                              dest.name,
                                              style: theme
                                                  .textTheme
                                                  .bodyMedium
                                                  ?.copyWith(
                                                fontWeight:
                                                isSelected
                                                    ? FontWeight
                                                    .w600
                                                    : null,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow
                                                  .ellipsis,
                                            ),
                                            Text(
                                              path,
                                              style: theme
                                                  .textTheme
                                                  .labelMedium
                                                  ?.copyWith(
                                                color: RAppColors
                                                    .textSecondary,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow
                                                  .ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: RAppSpacing.md),

                // Move button
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed:
                    (_selectedDestination != null && !_isMoving)
                        ? _moveNode
                        : null,
                    icon: _isMoving
                        ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                        : const Icon(Icons.drive_file_move),
                    label: Text(_isMoving ? 'Moving...' : 'Move Here'),
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