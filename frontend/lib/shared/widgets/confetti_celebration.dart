import 'dart:math';
import 'package:flutter/material.dart';

class ConfettiCelebration extends StatefulWidget {
  final Widget child;
  final bool isPlaying;
  final VoidCallback? onFinished;

  const ConfettiCelebration({
    super.key,
    required this.child,
    required this.isPlaying,
    this.onFinished,
  });

  @override
  State<ConfettiCelebration> createState() => _ConfettiCelebrationState();
}

class _ConfettiCelebrationState extends State<ConfettiCelebration>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_ConfettiParticle> _particles = [];
  final Random _rnd = Random();

  final List<Color> _colors = const [
    Color(0xFF2563EB), // Indigo
    Color(0xFF10B981), // Émeraude
    Color(0xFFF59E0B), // Ambre
    Color(0xFFF43F5E), // Corail
    Color(0xFF06B6D4), // Cyan
    Color(0xFF8B5CF6), // Violet
    Color(0xFFFBBF24), // Or
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..addListener(() {
        setState(() {
          for (var p in _particles) {
            p.update();
          }
        });
      });

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onFinished?.call();
      }
    });

    if (widget.isPlaying) {
      _startBurst();
    }
  }

  @override
  void didUpdateWidget(ConfettiCelebration oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying && !oldWidget.isPlaying) {
      _startBurst();
    }
  }

  void _startBurst() {
    _particles.clear();
    for (int i = 0; i < 90; i++) {
      final angle = _rnd.nextDouble() * pi * 2;
      final speed = 4.0 + _rnd.nextDouble() * 12.0;
      _particles.add(
        _ConfettiParticle(
          x: 0.5,
          y: 0.35,
          vx: cos(angle) * speed,
          vy: sin(angle) * speed - 6.0,
          color: _colors[_rnd.nextInt(_colors.length)],
          size: 6.0 + _rnd.nextDouble() * 8.0,
          rotation: _rnd.nextDouble() * pi * 2,
          rotationSpeed: (_rnd.nextDouble() - 0.5) * 0.4,
        ),
      );
    }
    _controller.forward(from: 0.0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_controller.isAnimating)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _ConfettiPainter(particles: _particles),
              ),
            ),
          ),
      ],
    );
  }
}

class _ConfettiParticle {
  double x;
  double y;
  double vx;
  double vy;
  Color color;
  double size;
  double rotation;
  double rotationSpeed;

  _ConfettiParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.color,
    required this.size,
    required this.rotation,
    required this.rotationSpeed,
  });

  void update() {
    x += vx * 0.002;
    y += vy * 0.002;
    vy += 0.35; // gravité
    rotation += rotationSpeed;
  }
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiParticle> particles;

  _ConfettiPainter({required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    for (var p in particles) {
      final cx = p.x * size.width;
      final cy = p.y * size.height;

      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(p.rotation);

      final paint = Paint()..color = p.color;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.6),
          const Radius.circular(2),
        ),
        paint,
      );

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) => true;
}

