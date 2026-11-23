import 'package:flutter/material.dart';

class Pulse3DButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final Color backgroundColor;
  final Color shadowColor;
  final Color foregroundColor;
  final double depth;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final IconData? icon;
  final double? width;
  final double? height;
  final bool isLoading;
  final Border? border;

  const Pulse3DButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.backgroundColor = const Color(0xFF2563EB), // Bleu professionnel web
    this.shadowColor = const Color(0xFF1D4ED8),
    this.foregroundColor = Colors.white,
    this.depth = 0.0, // Plat professionnel
    this.borderRadius = 8.0, // Coins nets format web
    this.padding = const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
    this.icon,
    this.width,
    this.height,
    this.isLoading = false,
    this.border,
  });

  @override
  State<Pulse3DButton> createState() => _Pulse3DButtonState();
}

class _Pulse3DButtonState extends State<Pulse3DButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.onPressed != null;

    return MouseRegion(
      cursor: isEnabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: isEnabled
                ? (_isHovered ? widget.shadowColor : widget.backgroundColor)
                : const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: widget.border,
          ),
          padding: widget.padding,
          child: Row(
            mainAxisSize: widget.width != null ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.isLoading) ...[
                SizedBox(
                  width: 15,
                  height: 15,
                  child: CircularProgressIndicator(strokeWidth: 2, color: widget.foregroundColor),
                ),
                const SizedBox(width: 8),
              ] else if (widget.icon != null) ...[
                Icon(widget.icon, color: widget.foregroundColor, size: 16),
                const SizedBox(width: 8),
              ],
              DefaultTextStyle(
                style: TextStyle(
                  color: isEnabled ? widget.foregroundColor : const Color(0xFF94A3B8),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  letterSpacing: -0.1,
                ),
                child: widget.child,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
