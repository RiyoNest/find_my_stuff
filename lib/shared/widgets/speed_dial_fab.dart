import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:find_my_stuff/shared/extensions/context_extensions.dart';

class SpeedDialItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const SpeedDialItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });
}

class SpeedDialFAB extends StatefulWidget {
  final List<SpeedDialItem> items;
  final IconData mainIcon;
  final String? tooltip;
  final bool isExtended;

  const SpeedDialFAB({
    super.key,
    required this.items,
    this.mainIcon = Icons.add,
    this.tooltip,
    this.isExtended = false,
  });

  @override
  State<SpeedDialFAB> createState() => _SpeedDialFABState();
}

class _SpeedDialFABState extends State<SpeedDialFAB> with SingleTickerProviderStateMixin {
  bool _isOpen = false;
  late AnimationController _controller;
  late Animation<double> _expandAnimation;
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      value: _isOpen ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.fastOutSlowIn,
    );
  }

  @override
  void dispose() {
    _close();
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    if (_isOpen) {
      _close();
    } else {
      _open();
    }
  }

  void _open() {
    setState(() {
      _isOpen = true;
    });
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    _controller.forward();
  }

  void _close() {
    if (!_isOpen) return;
    setState(() {
      _isOpen = false;
    });
    _controller.reverse().then((_) {
      _overlayEntry?.remove();
      _overlayEntry = null;
    });
  }

  Widget _buildItemRow(SpeedDialItem item, int index) {
    return Padding(
      padding: EdgeInsets.only(bottom: context.spacingS),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Option label
          Card(
            color: Theme.of(context).colorScheme.inverseSurface,
            shape: RoundedRectangleBorder(
              borderRadius: context.borderRadiusS,
            ),
            elevation: 2,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: context.spacingS,
                vertical: context.spacingXS,
              ),
              child: Text(
                item.label,
                style: context.bodySmallStyle.copyWith(
                  color: Theme.of(context).colorScheme.onInverseSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          SizedBox(width: context.spacingS),
          // Option FAB
          Semantics(
            label: item.label,
            button: true,
            child: Tooltip(
              message: item.label,
              child: FloatingActionButton.small(
                heroTag: 'sd_fab_$index',
                onPressed: () {
                  _close();
                  item.onTap();
                },
                backgroundColor: const Color(0xFFD10047),
                foregroundColor: Colors.white,
                child: Icon(item.icon, size: context.iconSmall + 2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  OverlayEntry _createOverlayEntry() {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    final items = List<SpeedDialItem>.from(widget.items);
    SpeedDialItem? addItem;
    final otherItems = <SpeedDialItem>[];
    for (final item in items) {
      if (item.label.toLowerCase().contains('item')) {
        addItem = item;
      } else {
        otherItems.add(item);
      }
    }

    otherItems.sort((a, b) {
      int getOrder(String label) {
        final l = label.toLowerCase();
        if (l.contains('room')) return 1;
        if (l.contains('location')) return 2;
        if (l.contains('section')) return 3;
        if (l.contains('container')) return 4;
        return 5;
      }
      return getOrder(a.label).compareTo(getOrder(b.label));
    });

    final dividerWidget = Padding(
      padding: EdgeInsets.only(
        right: 8.0,
        bottom: context.spacingS,
      ),
      child: Container(
        width: 160,
        height: 1.5,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(1),
        ),
      ),
    );

    final List<Widget> children = [];
    int index = 0;
    if (addItem != null) {
      children.add(_buildItemRow(addItem, index++));
      if (otherItems.isNotEmpty) {
        children.add(dividerWidget);
      }
    }
    for (final item in otherItems) {
      children.add(_buildItemRow(item, index++));
    }

    return OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            // Barrier
            GestureDetector(
              onTap: _close,
              child: AnimatedBuilder(
                animation: _expandAnimation,
                builder: (context, child) {
                  return Container(
                    color: Colors.black.withValues(alpha: _expandAnimation.value * 0.4),
                  );
                },
              ),
            ),
            // Floating options
            Positioned(
              right: MediaQuery.of(context).size.width - offset.dx - size.width,
              bottom: MediaQuery.of(context).size.height - offset.dy,
              child: Material(
                type: MaterialType.transparency,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    ScaleTransition(
                      scale: _expandAnimation,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: children,
                      ),
                    ),
                    SizedBox(height: context.spacingS),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.tooltip ?? 'Open action menu';
    return Semantics(
      label: label,
      button: true,
      child: FloatingActionButton.extended(
        isExtended: widget.isExtended && !_isOpen,
        heroTag: widget.tooltip ?? 'speed_dial_main',
        onPressed: _toggle,
        backgroundColor: const Color(0xFFD10047),
        foregroundColor: Colors.white,
        tooltip: widget.tooltip,
        icon: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.rotate(
              angle: _controller.value * math.pi / 4,
              child: const Icon(Icons.add),
            );
          },
        ),
        label: const Text('Add Item'),
      ),
    );
  }
}
