import 'package:flutter/material.dart';
import 'package:find_my_stuff/shared/extensions/context_extensions.dart';

class ItemQuickActions extends StatelessWidget {
  final VoidCallback onEdit;
  final VoidCallback onMove;
  final VoidCallback onLocate;

  const ItemQuickActions({
    super.key,
    required this.onEdit,
    required this.onMove,
    required this.onLocate,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.spacingS),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              label: 'Edit item details',
              button: true,
              child: Tooltip(
                message: 'Edit details',
                child: FilledButton.tonalIcon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Edit'),
                  style: FilledButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: context.spacingS),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: context.spacingS),
          Expanded(
            child: Semantics(
              label: 'Move item location',
              button: true,
              child: Tooltip(
                message: 'Change location',
                child: FilledButton.tonalIcon(
                  onPressed: onMove,
                  icon: const Icon(Icons.drive_file_move_outlined, size: 18),
                  label: const Text('Move'),
                  style: FilledButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: context.spacingS),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: context.spacingS),
          Expanded(
            child: Semantics(
              label: 'Locate item storage card',
              button: true,
              child: Tooltip(
                message: 'Locate storage details',
                child: FilledButton.tonalIcon(
                  onPressed: onLocate,
                  icon: const Icon(Icons.gps_fixed_rounded, size: 18),
                  label: const Text('Locate'),
                  style: FilledButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: context.spacingS),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
