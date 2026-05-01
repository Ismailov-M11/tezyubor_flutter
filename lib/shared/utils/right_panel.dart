import 'package:flutter/material.dart';

/// Pushes [page] as a new route that slides in from the right.
/// Swipe left closes it via the back arrow or gesture.
Future<T?> pushRightPanel<T>(BuildContext context, Widget page) {
  return Navigator.of(context).push<T>(
    PageRouteBuilder<T>(
      pageBuilder: (_, __, ___) => page,
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 280),
      transitionsBuilder: (_, animation, __, child) => SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        )),
        child: child,
      ),
    ),
  );
}

/// Wraps [child] with a horizontal swipe-left gesture that pops the route.
class SwipeToDismiss extends StatelessWidget {
  final Widget child;
  const SwipeToDismiss({super.key, required this.child});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onHorizontalDragEnd: (d) {
          if ((d.primaryVelocity ?? 0) < -300) {
            Navigator.of(context).maybePop();
          }
        },
        child: child,
      );
}

/// Standard back button for right-panel pages.
class PanelBackButton extends StatelessWidget {
  const PanelBackButton({super.key});

  @override
  Widget build(BuildContext context) => IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        onPressed: () => Navigator.of(context).pop(),
      );
}
