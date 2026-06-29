import 'package:flutter/material.dart';
import 'package:find_my_stuff/shared/extensions/context_extensions.dart';

enum LoadingType { center, list, details, grid }

class LoadingStateWidget extends StatefulWidget {
  final LoadingType type;
  const LoadingStateWidget({super.key, this.type = LoadingType.center});

  @override
  State<LoadingStateWidget> createState() => _LoadingStateWidgetState();
}

class _LoadingStateWidgetState extends State<LoadingStateWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.5, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (widget.type == LoadingType.center) {
      return Center(
        child: CircularProgressIndicator(
          color: theme.colorScheme.primary,
        ),
      );
    }

    return FadeTransition(
      opacity: _animation,
      child: _buildSkeleton(context, theme),
    );
  }

  Widget _buildSkeleton(BuildContext context, ThemeData theme) {
    switch (widget.type) {
      case LoadingType.list:
        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: context.spacingM, vertical: context.spacingS),
          itemCount: 5,
          separatorBuilder: (_, _) => SizedBox(height: context.spacingS),
          itemBuilder: (_, _) => Card(
            margin: EdgeInsets.zero,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: context.borderRadiusM,
              side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
            ),
            child: ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: context.borderRadiusS,
                ),
              ),
              title: Container(
                width: 120,
                height: 14,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              subtitle: Container(
                width: 200,
                height: 10,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        );

      case LoadingType.grid:
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: context.spacingM, vertical: context.spacingS),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: context.columns,
            mainAxisSpacing: context.spacingS + 4,
            crossAxisSpacing: context.spacingS + 4,
            childAspectRatio: context.itemCardAspectRatio,
          ),
          itemCount: 6,
          itemBuilder: (_, _) => Card(
            margin: EdgeInsets.zero,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: context.borderRadiusM,
              side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
            ),
            child: Padding(
              padding: EdgeInsets.all(context.spacingS),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: context.borderRadiusS,
                      ),
                    ),
                  ),
                  SizedBox(height: context.spacingS),
                  Container(
                    width: 100,
                    height: 14,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  SizedBox(height: context.spacingXS),
                  Container(
                    width: 60,
                    height: 10,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

      case LoadingType.details:
        return SingleChildScrollView(
          padding: context.pagePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: context.borderRadiusL,
                ),
              ),
              SizedBox(height: context.spacingM),
              Container(
                width: 250,
                height: 20,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              SizedBox(height: context.spacingS),
              Container(
                width: 150,
                height: 14,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              SizedBox(height: context.spacingL),
              Container(
                width: double.infinity,
                height: 120,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: context.borderRadiusM,
                ),
              ),
            ],
          ),
        );

      default:
        return const Center(child: CircularProgressIndicator());
    }
  }
}
