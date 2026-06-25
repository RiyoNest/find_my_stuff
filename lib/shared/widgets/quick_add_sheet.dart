// File: lib/shared/widgets/quick_add_sheet.dart
//
// Bottom sheet for adding a named entity (room, location, section, etc.)
// Replaces all AlertDialog-based "Add" flows with the pattern from the
// reference app: sheet slides up, keyboard opens, text field sits just
// above the keyboard. Much more natural on mobile than a dialog.
//
// KEY: showModalBottomSheet with isScrollControlled: true + padding
// for viewInsets.bottom makes the input float above the keyboard.
//
// For pages that need a node type (Section / Container / Item), pass
// showTypePicker: true to show the horizontal type chip row.
//
// Usage — simple (Room / Location):
//   final name = await QuickAddSheet.show(context, title: 'Add Room');
//   if (name != null) { ... }
//
// Usage — with type picker (StorageNode child):
//   final result = await QuickAddSheet.showWithType(context, title: 'Add to Kitchen');
//   if (result != null) { // result.name, result.nodeType }

import 'package:find_my_stuff/core/constants/app_colours.dart';
import 'package:find_my_stuff/core/constants/app_gradients.dart';
import 'package:find_my_stuff/core/constants/app_radius.dart';
import 'package:find_my_stuff/core/constants/app_spacing.dart';
import 'package:find_my_stuff/core/utils/validation_helpers.dart';
import 'package:find_my_stuff/shared/enums/node_type.dart';
import 'package:find_my_stuff/shared/models/add_child_node_result.dart';
import 'package:flutter/material.dart';

// ── Simple name result (for Room, Location) ─────────────────────────────────

class QuickAddSheet extends StatefulWidget {
  final String title;
  final String hint;

  const QuickAddSheet({
    super.key,
    required this.title,
    this.hint = 'Enter a name...',
  });

  /// Shows the sheet and returns the entered name, or null if cancelled.
  static Future<String?> show(
      BuildContext context, {
        required String title,
        String hint = 'Enter a name...',
      }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true, // allows sheet to resize with keyboard
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(RAppRadius.xl),
        ),
      ),
      builder: (ctx) => QuickAddSheet(title: title, hint: hint),
    );
  }

  @override
  State<QuickAddSheet> createState() => _QuickAddSheetState();
}

class _QuickAddSheetState extends State<QuickAddSheet> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String v) {
    setState(() => _error = ValidationHelpers.validateRoomName(v));
  }

  void _submit() {
    final error = ValidationHelpers.validateRoomName(_controller.text);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    Navigator.pop(context, ValidationHelpers.sanitize(_controller.text));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isValid = _error == null && _controller.text.trim().isNotEmpty;

    return Padding(
      // Makes the sheet rise with the keyboard
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: RAppSpacing.lg,
        right: RAppSpacing.lg,
        top: 0,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.title, style: theme.textTheme.titleMedium),
          const SizedBox(height: RAppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                  maxLength: ValidationHelpers.maxRoomNameLength,
                  decoration: InputDecoration(
                    hintText: widget.hint,
                    border: const OutlineInputBorder(),
                    errorText: _error,
                    counterText: '',
                  ),
                  onChanged: _onChanged,
                  onSubmitted: (_) => _submit(),
                ),
              ),
              const SizedBox(width: RAppSpacing.sm),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: FilledButton(
                  onPressed: isValid ? _submit : null,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(64, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(RAppRadius.md),
                    ),
                  ),
                  child: const Icon(Icons.arrow_forward_rounded),
                ),
              ),
            ],
          ),
          const SizedBox(height: RAppSpacing.md),
        ],
      ),
    );
  }
}

// ── With node type picker (Section / Container / Item) ──────────────────────

class QuickAddWithTypeSheet extends StatefulWidget {
  final String title;

  const QuickAddWithTypeSheet({super.key, required this.title});

  /// Shows the sheet and returns an [AddChildNodeResult], or null if cancelled.
  static Future<AddChildNodeResult?> show(
      BuildContext context, {
        required String title,
      }) {
    return showModalBottomSheet<AddChildNodeResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(RAppRadius.xl),
        ),
      ),
      builder: (ctx) => QuickAddWithTypeSheet(title: title),
    );
  }

  @override
  State<QuickAddWithTypeSheet> createState() => _QuickAddWithTypeSheetState();
}

class _QuickAddWithTypeSheetState extends State<QuickAddWithTypeSheet> {
  final _controller = TextEditingController();
  NodeType _selectedType = NodeType.item;
  String? _error;

  static const _typeConfig = [
    (NodeType.section,   Icons.view_agenda_outlined,  '📁', 'Section'),
    (NodeType.container, Icons.inventory_2_outlined,  '📦', 'Container'),
    (NodeType.item,      Icons.label_outline,         '🏷️', 'Item'),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String v) {
    setState(() => _error = ValidationHelpers.validateItemName(v));
  }

  void _submit() {
    final error = ValidationHelpers.validateItemName(_controller.text);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
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
    final isValid = _error == null && _controller.text.trim().isNotEmpty;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: RAppSpacing.lg,
        right: RAppSpacing.lg,
        top: 0,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.title, style: theme.textTheme.titleMedium),
          const SizedBox(height: RAppSpacing.md),

          // Horizontal type picker
          Row(
            children: _typeConfig.map((cfg) {
              final (type, icon, emoji, label) = cfg;
              final isSelected = _selectedType == type;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: type == NodeType.item ? 0 : RAppSpacing.sm,
                  ),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedType = type),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                        vertical: RAppSpacing.sm,
                        horizontal: RAppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        gradient: isSelected ? RAppGradients.items : null,
                        color: isSelected
                            ? null
                            : theme.colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(RAppRadius.sm),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(emoji, style: const TextStyle(fontSize: 18)),
                          const SizedBox(height: 2),
                          Text(
                            label,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: isSelected
                                  ? Colors.white
                                  : RAppColors.textSecondary,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: RAppSpacing.md),

          // Name field + submit
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  autofocus: true,
                  textCapitalization: TextCapitalization.sentences,
                  maxLength: ValidationHelpers.maxItemNameLength,
                  decoration: InputDecoration(
                    hintText: 'Enter a name...',
                    border: const OutlineInputBorder(),
                    errorText: _error,
                    counterText: '',
                  ),
                  onChanged: _onChanged,
                  onSubmitted: (_) => _submit(),
                ),
              ),
              const SizedBox(width: RAppSpacing.sm),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: FilledButton(
                  onPressed: isValid ? _submit : null,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(64, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(RAppRadius.md),
                    ),
                  ),
                  child: const Icon(Icons.arrow_forward_rounded),
                ),
              ),
            ],
          ),
          const SizedBox(height: RAppSpacing.md),
        ],
      ),
    );
  }
}