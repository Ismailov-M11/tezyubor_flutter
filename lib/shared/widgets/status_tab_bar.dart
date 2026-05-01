import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import 'status_badge.dart';

/// Scrollable pill-chip tab bar that tracks TabController.animation for
/// smooth, physics-driven transitions — slow drag = slow blend, fast swipe =
/// instant snap with color spring.
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
  int _lastScrolledIndex = 0;

  @override
  void initState() {
    super.initState();
    _keys = List.generate(widget.statuses.length, (_) => GlobalKey());
    _lastScrolledIndex = widget.controller.index;
    widget.controller.animation!.addListener(_onAnimChange);
  }

  @override
  void didUpdateWidget(StatusTabBar old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.animation!.removeListener(_onAnimChange);
      widget.controller.animation!.addListener(_onAnimChange);
    }
  }

  @override
  void dispose() {
    widget.controller.animation!.removeListener(_onAnimChange);
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onAnimChange() {
    final val = widget.controller.animation!.value;
    final idx = val.round().clamp(0, widget.statuses.length - 1);
    if (idx != _lastScrolledIndex) {
      _lastScrolledIndex = idx;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final ctx = _keys[idx].currentContext;
        if (ctx != null) {
          Scrollable.ensureVisible(ctx, alignment: 0.5, duration: Duration.zero);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: widget.controller.animation!,
      builder: (_, __) {
        final animValue = widget.controller.animation!.value;

        return SizedBox(
          height: 48,
          child: ListView.separated(
            controller: _scrollCtrl,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
            itemCount: widget.statuses.length,
            separatorBuilder: (_, __) => const SizedBox(width: 6),
            itemBuilder: (_, i) {
              final status = widget.statuses[i];
              final color = status == 'all'
                  ? AppColors.primary
                  : StatusBadge.colorFor(status);

              // Smooth selection: 1.0 = fully selected, 0.0 = unselected.
              final sel =
                  (1.0 - (animValue - i).abs()).clamp(0.0, 1.0);

              final bg = color.withValues(
                  alpha: (isDark ? 0.18 : 0.12) * sel);
              final borderColor = Color.lerp(
                theme.colorScheme.outline.withValues(alpha: 0.3),
                color,
                sel,
              )!;
              final textColor = Color.lerp(
                theme.colorScheme.onSurfaceVariant,
                color,
                sel,
              )!;

              return KeyedSubtree(
                key: _keys[i],
                child: GestureDetector(
                  onTap: () => widget.controller.animateTo(i),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: borderColor,
                        width: 1.0 + 0.5 * sel,
                      ),
                      boxShadow: sel > 0.01
                          ? [
                              BoxShadow(
                                color: color.withValues(alpha: 0.25 * sel),
                                blurRadius: 8 * sel,
                                offset: Offset(0, 2 * sel),
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        widget.getLabel(status),
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: sel > 0.5
                              ? FontWeight.w600
                              : FontWeight.w500,
                          color: textColor,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
