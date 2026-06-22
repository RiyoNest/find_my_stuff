// File: lib/features/storage_tree/presentation/widgets/add_child_node_dialog.dart
//
// CHANGES:
//   - Three RadioListTiles replaced with a segmented button row — takes
//     half the vertical space and looks intentional rather than default.
//   - Added short description under each type so users know the difference
//     between Section / Container / Item.
//   - Real name validation with inline error; Save disables on empty.
//   - Uses RAppRadius tokens to match CardTheme/DialogTheme shape.

import 'package:find_my_stuff/core/constants/app_colours.dart';
import 'package:find_my_stuff/core/constants/app_radius.dart';
import 'package:find_my_stuff/core/constants/app_spacing.dart';
import 'package:find_my_stuff/core/utils/validation_helpers.dart';
import 'package:find_my_stuff/shared/enums/node_type.dart';
import 'package:find_my_stuff/shared/models/add_child_node_result.dart';
import 'package:flutter/material.dart';

class AddChildNodeDialog extends StatefulWidget {
  const AddChildNodeDialog({super.key});

  @override
  State<AddChildNodeDialog> createState() => _AddChildNodeDialogState();
}

class _AddChildNodeDialogState extends State<AddChildNodeDialog> {
  final _controller = TextEditingController();
  NodeType _selectedType = NodeType.section;
  String? _errorText;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    setState(() => _errorText = ValidationHelpers.validateItemName(value));
  }

  void _save() {
    final error = ValidationHelpers.validateItemName(_controller.text);
    setState(() => _errorText = error);
    if (error != null) return;

    Navigator.pop(
      context,
      AddChildNodeResult(
        nodeType: _selectedType,
        name: ValidationHelpers.sanitize(_controller.text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isValid =
        ValidationHelpers.validateItemName(_controller.text) == null;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(RAppRadius.lg),
      ),
      title: const Text('Add Child'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Type selector
            Text('Type', style: theme.textTheme.labelMedium?.copyWith(
              color: RAppColors.textSecondary,
            )),
            const SizedBox(height: RAppSpacing.sm),
            _TypeSelector(
              selected: _selectedType,
              onChanged: (t) => setState(() => _selectedType = t),
            ),

            const SizedBox(height: RAppSpacing.md),

            // Type description
            _TypeHint(type: _selectedType),

            const SizedBox(height: RAppSpacing.md),

            // Name field
            TextField(
              controller: _controller,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              maxLength: ValidationHelpers.maxItemNameLength,
              decoration: InputDecoration(
                labelText: 'Name',
                border: const OutlineInputBorder(),
                errorText: _errorText,
              ),
              onChanged: _onChanged,
              onSubmitted: (_) => _save(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: isValid ? _save : null,
          child: const Text('Add'),
        ),
      ],
    );
  }
}

class _TypeSelector extends StatelessWidget {
  final NodeType selected;
  final ValueChanged<NodeType> onChanged;

  const _TypeSelector({required this.selected, required this.onChanged});

  static const _types = [
    (NodeType.section, Icons.view_agenda_outlined, 'Section'),
    (NodeType.container, Icons.inventory_2_outlined, 'Container'),
    (NodeType.item, Icons.label_outline, 'Item'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: _types.map((entry) {
        final (type, icon, label) = entry;
        final isSelected = selected == type;

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: type == NodeType.item ? 0 : RAppSpacing.xs,
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(RAppRadius.sm),
              onTap: () => onChanged(type),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  vertical: RAppSpacing.sm,
                  horizontal: RAppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primaryContainer
                      : theme.colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(RAppRadius.sm),
                  border: isSelected
                      ? Border.all(color: theme.colorScheme.primary, width: 1.5)
                      : null,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size: 20,
                      color: isSelected
                          ? theme.colorScheme.primary
                          : RAppColors.textSecondary,
                    ),
                    const SizedBox(height: RAppSpacing.xs),
                    Text(
                      label,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : RAppColors.textSecondary,
                        fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _TypeHint extends StatelessWidget {
  final NodeType type;

  const _TypeHint({required this.type});

  static const _hints = {
    NodeType.section: (
    Icons.view_agenda_outlined,
    'A logical grouping inside a location — e.g. "Top Shelf", "Left Side".',
    ),
    NodeType.container: (
    Icons.inventory_2_outlined,
    'A physical container — e.g. "Red Box", "Zip Pouch", "Drawer".',
    ),
    NodeType.item: (
    Icons.label_outline,
    'An individual item you want to track — e.g. "Passport", "Charger".',
    ),
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (icon, hint) = _hints[type]!;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: RAppColors.textSecondary),
        const SizedBox(width: RAppSpacing.xs),
        Expanded(
          child: Text(
            hint,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: RAppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}