import 'package:flutter/material.dart';

/// Shared page route with 300ms slide+fade transition.
/// Replaces all MaterialPageRoute calls for a polished feel.
class AppPageRoute<T> extends PageRouteBuilder<T> {
  AppPageRoute(Widget page)
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.03, 0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
                  child: child,
                ),
              ),
          transitionDuration: const Duration(milliseconds: 280),
          reverseTransitionDuration: const Duration(milliseconds: 200),
        );
}
