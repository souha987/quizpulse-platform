import 'package:flutter/material.dart';

/// Shimmer loader effect that wraps child widgets and applies an animated linear gradient shimmer.
class ShimmerLoading extends StatefulWidget {
  final Widget child;
  final Duration duration;

  const ShimmerLoading({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1400),
  });

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final slide = _controller.value;
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment(-2.0 + 4.0 * slide, -0.2),
              end: Alignment(-0.5 + 4.0 * slide, 0.2),
              colors: const [
                Color(0xFFE2E8F0),
                Color(0xFFF8FAFC),
                Color(0xFFCBD5E1),
                Color(0xFFF8FAFC),
                Color(0xFFE2E8F0),
              ],
              stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Base rounded skeleton placeholder box
class LoadingSkeleton extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const LoadingSkeleton({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// Shimmer skeleton card for the Teacher "Mes Quiz" screen
class QuizCardSkeleton extends StatelessWidget {
  const QuizCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left colored stripe skeleton
            Container(width: 5, color: const Color(0xFFCBD5E1)),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badge row
                    Row(
                      children: [
                        const LoadingSkeleton(width: 90, height: 24, borderRadius: 8),
                        const SizedBox(width: 8),
                        const LoadingSkeleton(width: 70, height: 24, borderRadius: 8),
                        const SizedBox(width: 8),
                        const LoadingSkeleton(width: 60, height: 24, borderRadius: 8),
                      ],
                    ),
                    const SizedBox(height: 14),
                    // Title skeleton
                    const LoadingSkeleton(width: 280, height: 20, borderRadius: 6),
                    const SizedBox(height: 10),
                    // Description skeleton
                    const LoadingSkeleton(width: 420, height: 14, borderRadius: 4),
                    const SizedBox(height: 18),
                    // Footer / stats & buttons skeleton
                    Row(
                      children: [
                        const LoadingSkeleton(width: 80, height: 14, borderRadius: 4),
                        const SizedBox(width: 16),
                        const LoadingSkeleton(width: 90, height: 14, borderRadius: 4),
                        const SizedBox(width: 16),
                        const LoadingSkeleton(width: 70, height: 14, borderRadius: 4),
                        const Spacer(),
                        const LoadingSkeleton(width: 90, height: 36, borderRadius: 10),
                        const SizedBox(width: 8),
                        const LoadingSkeleton(width: 100, height: 36, borderRadius: 10),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shimmer skeleton loader for the Quiz Preparation screen
class QuizPreparationSkeleton extends StatelessWidget {
  const QuizPreparationSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 720),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header: question counter & timer skeleton
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const LoadingSkeleton(width: 110, height: 20, borderRadius: 6),
                const LoadingSkeleton(width: 80, height: 20, borderRadius: 6),
              ],
            ),
            const SizedBox(height: 16),
            // Progress bar skeleton
            const LoadingSkeleton(width: double.infinity, height: 6, borderRadius: 99),
            const SizedBox(height: 20),
            // Question prompt skeleton
            const LoadingSkeleton(width: double.infinity, height: 22, borderRadius: 6),
            const SizedBox(height: 10),
            const LoadingSkeleton(width: 280, height: 18, borderRadius: 6),
            const SizedBox(height: 22),
            // Option 1
            _buildOptionSkeleton(),
            const SizedBox(height: 10),
            // Option 2
            _buildOptionSkeleton(),
            const SizedBox(height: 10),
            // Option 3
            _buildOptionSkeleton(),
            const SizedBox(height: 10),
            // Option 4
            _buildOptionSkeleton(),
            const SizedBox(height: 20),
            // Bottom button skeleton
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const LoadingSkeleton(width: 110, height: 40, borderRadius: 10),
                const LoadingSkeleton(width: 130, height: 40, borderRadius: 10),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionSkeleton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          const LoadingSkeleton(width: 28, height: 28, borderRadius: 6),
          const SizedBox(width: 14),
          const Expanded(
            child: LoadingSkeleton(width: double.infinity, height: 16, borderRadius: 4),
          ),
        ],
      ),
    );
  }
}
