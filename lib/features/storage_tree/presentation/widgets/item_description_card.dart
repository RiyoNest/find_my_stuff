import 'package:flutter/material.dart';
import 'package:find_my_stuff/shared/extensions/context_extensions.dart';

class ItemDescriptionCard extends StatefulWidget {
  final String? description;

  const ItemDescriptionCard({super.key, required this.description});

  @override
  State<ItemDescriptionCard> createState() => _ItemDescriptionCardState();
}

class _ItemDescriptionCardState extends State<ItemDescriptionCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasDescription = widget.description != null && widget.description!.trim().isNotEmpty;
    
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: context.borderRadiusL,
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: context.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Description',
              style: context.titleStyle.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 12),
            if (!hasDescription)
              Text(
                "Add notes like 'Top drawer beneath the manuals'.",
                style: context.bodyStyle.copyWith(
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                  fontStyle: FontStyle.italic,
                ),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.description!,
                    maxLines: _isExpanded ? null : 5,
                    overflow: _isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                    style: context.bodyStyle.copyWith(height: 1.5),
                  ),
                  if (widget.description!.length > 180) ...[
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          setState(() {
                            _isExpanded = !_isExpanded;
                          });
                        },
                        child: Text(_isExpanded ? 'Read less' : 'Read more'),
                      ),
                    ),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }
}
