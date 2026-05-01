import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import 'status_badge.dart';

/// Scrollable pill-chip tab bar for order status filtering.
/// Auto-scrolls to keep the selected chip visible.
class StatusTabBar extends StatefulWidget implements PreferredSizeWidget {
  final List<String> statuses;
  final TabController controller;
  final String Function(String status) getLabel;

  const StatusTabBar({
    super.key,
    required this.statuses,
    required this.controller,
    required this.getLabel,
  });

  @override
  Size get preferredSize => const Size.fromHeight(48);

  @override
  State<StatusTabBar> createState() => _StatusTabBarState();
}

class _StatusTabBarState extends State<StatusTabBar> {
  late final List<GlobalKey> _keys;
  final _scrollCtrl = ScrollController();
  int _prevIndex = 0;

  @override
  void initState() {
    super.initState();
    _keys = List.generate(widget.statuses.length, (_) => GlobalKey());
    _prevIndex = widget.controller.index;
    widget.controller.addListener(_onTabChange);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTabChange);
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onTabChange() {
    final idx = widget.controller.index;
    if (idx == _prevIndex) return;
    _prevIndex = idx;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _keys[idx].currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          alignment: 0.5,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: widget.controller,
      builder: (_, __) => SizedBox(
        height: 48,
        child: ListView.separated(
          controller: _scrollCtrl,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
          itemCount: widget.statuses.length,
          separatorBuilder: (_, __) => const SizedBox(width: 6),
          itemBuilder: (_, i) {
            final isSelected = widget.controller.index == i;
            final status = widget.statuses[i];
            final color = status == 'all'
                ? AppColors.primary
                : StatusBadge.colorFor(status);

            return KeyedSubtree(
              key: _keys[i],
              child: GestureDetector(
                onTap: () => widget.controller.animateTo(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeInOut,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? color.withValues(alpha: isDark ? 0.18 : 0.12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? color
                          : theme.colorScheme.outline.withValues(alpha: 0.3),
                      width: isSelected ? 1.5 : 1.0,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: color.withValues(alpha: 0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      widget.getLabel(status),
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected
                            ? color
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
