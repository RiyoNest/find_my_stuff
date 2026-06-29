import 'package:flutter/material.dart';
import 'package:find_my_stuff/shared/entities/storage_node_entity.dart';
import 'package:find_my_stuff/shared/extensions/context_extensions.dart';
import 'package:find_my_stuff/shared/enums/node_type.dart';

class StorageDetailsCard extends StatefulWidget {
  final String? roomName;
  final List<StorageNodeEntity> path;
  final VoidCallback onMove;

  const StorageDetailsCard({
    super.key,
    required this.roomName,
    required this.path,
    required this.onMove,
  });

  @override
  State<StorageDetailsCard> createState() => StorageDetailsCardState();
}

class StorageDetailsCardState extends State<StorageDetailsCard> with SingleTickerProviderStateMixin {
  late AnimationController _highlightController;
  late Animation<Color?> _colorAnimation;
  late Animation<Color?> _borderColorAnimation;

  @override
  void initState() {
    super.initState();
    _highlightController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    
    _colorAnimation = ColorTween(
      begin: Colors.transparent,
      end: Colors.transparent,
    ).animate(_highlightController);

    _borderColorAnimation = ColorTween(
      begin: Colors.transparent,
      end: Colors.transparent,
    ).animate(_highlightController);
  }

  void highlight() {
    final theme = Theme.of(context);
    setState(() {
      _colorAnimation = ColorTween(
        begin: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
        end: Colors.transparent,
      ).animate(CurvedAnimation(
        parent: _highlightController,
        curve: Curves.easeOut,
      ));

      _borderColorAnimation = ColorTween(
        begin: theme.colorScheme.primary,
        end: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
      ).animate(CurvedAnimation(
        parent: _highlightController,
        curve: Curves.easeOut,
      ));
    });
    _highlightController.forward(from: 0.0);
  }

  @override
  void dispose() {
    _highlightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    String? locationName;
    String? sectionName;
    String? containerName;
    
    for (final entity in widget.path) {
      if (entity.nodeType == NodeType.storageLocation.name) {
        locationName = entity.name;
      } else if (entity.nodeType == NodeType.section.name) {
        sectionName = entity.name;
      } else if (entity.nodeType == NodeType.container.name) {
        containerName = entity.name;
      }
    }

    final List<Widget> rows = [];

    if (widget.roomName != null && widget.roomName!.isNotEmpty) {
      rows.add(_StorageRow(
        icon: Icons.meeting_room_outlined,
        label: 'Room',
        value: widget.roomName!,
      ));
    }
    if (locationName != null && locationName.isNotEmpty) {
      rows.add(_StorageRow(
        icon: Icons.door_sliding_outlined,
        label: 'Location',
        value: locationName,
      ));
    }
    if (sectionName != null && sectionName.isNotEmpty) {
      rows.add(_StorageRow(
        icon: Icons.layers_outlined,
        label: 'Section',
        value: sectionName,
      ));
    }
    if (containerName != null && containerName.isNotEmpty) {
      rows.add(_StorageRow(
        icon: Icons.inventory_2_outlined,
        label: 'Container',
        value: containerName,
      ));
    }

    return AnimatedBuilder(
      animation: _highlightController,
      builder: (context, child) {
        final highlightActive = _highlightController.isAnimating || _highlightController.value < 1.0 && _highlightController.value > 0.0;
        final decorationColor = highlightActive ? _colorAnimation.value : Colors.transparent;
        final borderOutlineColor = highlightActive 
            ? _borderColorAnimation.value 
            : theme.colorScheme.outlineVariant.withValues(alpha: 0.5);
        final borderWidth = highlightActive ? 2.0 : 1.0;

        return Card(
          elevation: 1,
          color: decorationColor,
          shape: RoundedRectangleBorder(
            borderRadius: context.borderRadiusL,
            side: BorderSide(
              color: borderOutlineColor ?? theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              width: borderWidth,
            ),
          ),
          child: child,
        );
      },
      child: Padding(
        padding: context.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Current Location",
              style: context.titleStyle.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 16),
            ...List.generate(rows.length, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: rows[index],
              );
            }),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: Semantics(
                label: 'Move item to another storage location',
                button: true,
                child: Tooltip(
                  message: 'Move Item',
                  child: OutlinedButton.icon(
                    onPressed: widget.onMove,
                    icon: const Icon(Icons.drive_file_move_outlined, size: 18),
                    label: const Text('Move Item'),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: context.spacingS + 2),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StorageRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StorageRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: 20,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: context.bodySmallStyle.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: context.bodyStyle.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
