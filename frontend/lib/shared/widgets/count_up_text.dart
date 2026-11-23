import 'package:flutter/material.dart';

/// Animated counter text that animates numbers from 0 up to their target value over 600 ms.
/// Seamlessly handles integers ("4", "12"), percentages ("100%"), decimals/fractions ("14.5/20"),
/// and gracefully falls back to static text for non-numeric values ("N/A").
class CountUpText extends StatefulWidget {
  final String value;
  final TextStyle style;
  final Duration duration;

  const CountUpText({
    super.key,
    required this.value,
    required this.style,
    this.duration = const Duration(milliseconds: 600),
  });

  @override
  State<CountUpText> createState() => _CountUpTextState();
}

class _CountUpTextState extends State<CountUpText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _targetNumber = 0;
  String _prefix = '';
  String _suffix = '';
  int _decimalPlaces = 0;
  bool _isNumeric = false;

  @override
  void initState() {
    super.initState();
    _parseValue();

    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    if (_isNumeric) {
      _controller.forward();
    }
  }

  void _parseValue() {
    // Matches: [prefix][number (with optional decimal)][suffix]
    final regex = RegExp(r'^([^\d\.]*)(\d+(?:\.\d+)?)(.*)$');
    final match = regex.firstMatch(widget.value);
    if (match != null) {
      _prefix = match.group(1) ?? '';
      final numStr = match.group(2) ?? '';
      _suffix = match.group(3) ?? '';
      _targetNumber = double.tryParse(numStr) ?? 0;
      if (numStr.contains('.')) {
        _decimalPlaces = numStr.split('.')[1].length;
      } else {
        _decimalPlaces = 0;
      }
      _isNumeric = true;
    } else {
      _isNumeric = false;
    }
  }

  @override
  void didUpdateWidget(CountUpText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _parseValue();
      if (_isNumeric) {
        _controller.reset();
        _controller.forward();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isNumeric) {
      return Text(widget.value, style: widget.style);
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final current = _animation.value * _targetNumber;
        final formatted = _decimalPlaces > 0
            ? current.toStringAsFixed(_decimalPlaces)
            : current.round().toString();
        return Text('$_prefix$formatted$_suffix', style: widget.style);
      },
    );
  }
}
