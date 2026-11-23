import 'dart:async';
import 'package:flutter/material.dart';

/// Reusable animation widget that plays a fade-in and slight slide-up animation once.
/// Duration: 250 ms. Delay: 50 ms * index.
class FadeSlideIn extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration duration;
  final Duration? delay;
  final Offset beginOffset;
  final Curve curve;

  const FadeSlideIn({
    super.key,
    required this.child,
    this.index = 0,
    this.duration = const Duration(milliseconds: 250),
    this.delay,
    this.beginOffset = const Offset(0, 0.08),
    this.curve = Curves.easeOutCubic,
  });

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  Timer? _delayTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    final curved = CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(curved);
    _slideAnimation = Tween<Offset>(
      begin: widget.beginOffset,
      end: Offset.zero,
    ).animate(curved);

    final effectiveDelay = widget.delay ?? Duration(milliseconds: widget.index * 50);

    if (effectiveDelay == Duration.zero) {
      _controller.forward();
    } else {
      _delayTimer = Timer(effectiveDelay, () {
        if (mounted) {
          _controller.forward();
        }
      });
    }
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}
