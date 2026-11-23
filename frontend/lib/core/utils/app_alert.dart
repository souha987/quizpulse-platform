import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

enum AlertType { success, error, warning, info }

class AppAlert {
  static OverlayEntry? _currentEntry;
  static Timer? _dismissTimer;

  /// Affiche une alerte élégante tout en haut de l'écran
  static void show(
    BuildContext context, {
    required String message,
    String? title,
    AlertType type = AlertType.info,
    Duration duration = const Duration(seconds: 4),
  }) {
    if (!context.mounted) return;

    // Supprimer l'alerte précédente s'il y en a une
    dismiss();

    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    _currentEntry = OverlayEntry(
      builder: (ctx) => _TopAlertWidget(
        message: message,
        title: title,
        type: type,
        duration: duration,
        onDismiss: dismiss,
      ),
    );

    overlay.insert(_currentEntry!);
  }

  static void success(BuildContext context, String message, {String? title, Duration? duration}) {
    show(
      context,
      message: message,
      title: title,
      type: AlertType.success,
      duration: duration ?? const Duration(seconds: 4),
    );
  }

  static void error(BuildContext context, String message, {String? title, Duration? duration}) {
    show(
      context,
      message: message,
      title: title,
      type: AlertType.error,
      duration: duration ?? const Duration(seconds: 5),
    );
  }

  static void warning(BuildContext context, String message, {String? title, Duration? duration}) {
    show(
      context,
      message: message,
      title: title,
      type: AlertType.warning,
      duration: duration ?? const Duration(seconds: 4),
    );
  }

  static void info(BuildContext context, String message, {String? title, Duration? duration}) {
    show(
      context,
      message: message,
      title: title,
      type: AlertType.info,
      duration: duration ?? const Duration(seconds: 4),
    );
  }

  /// Adaptateur intelligent basé sur la couleur (pour remplacer les anciens SnackBar)
  static void fromColor(
    BuildContext context,
    String message, {
    Color? backgroundColor,
    String? title,
  }) {
    if (backgroundColor != null) {
      final v = backgroundColor.value;
      if (v == 0xFFEF4444 || v == 0xFFDC2626 || backgroundColor == AppTheme.danger) {
        error(context, message, title: title);
        return;
      }
      if (v == 0xFF10B981 || v == 0xFF059669 || backgroundColor == AppTheme.success) {
        success(context, message, title: title);
        return;
      }
      if (v == 0xFFF59E0B || v == 0xFFD97706 || backgroundColor == AppTheme.warning) {
        warning(context, message, title: title);
        return;
      }
    }
    info(context, message, title: title);
  }

  static void dismiss() {
    _dismissTimer?.cancel();
    _dismissTimer = null;
    _currentEntry?.remove();
    _currentEntry = null;
  }
}

class _TopAlertWidget extends StatefulWidget {
  final String message;
  final String? title;
  final AlertType type;
  final Duration duration;
  final VoidCallback onDismiss;

  const _TopAlertWidget({
    required this.message,
    this.title,
    required this.type,
    required this.duration,
    required this.onDismiss,
  });

  @override
  State<_TopAlertWidget> createState() => _TopAlertWidgetState();
}

class _TopAlertWidgetState extends State<_TopAlertWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.8),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _controller.forward();

    _timer = Timer(widget.duration, () {
      _close();
    });
  }

  void _close() {
    if (!mounted) return;
    _timer?.cancel();
    _controller.reverse().then((_) {
      widget.onDismiss();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Color get _accentColor {
    switch (widget.type) {
      case AlertType.success:
        return AppTheme.success;
      case AlertType.error:
        return AppTheme.danger;
      case AlertType.warning:
        return AppTheme.warning;
      case AlertType.info:
        return AppTheme.primary;
    }
  }

  Color get _bgTint {
    switch (widget.type) {
      case AlertType.success:
        return const Color(0xFFF0FDF4); // Soft Green
      case AlertType.error:
        return const Color(0xFFFEF2F2); // Soft Red
      case AlertType.warning:
        return const Color(0xFFFFFBEB); // Soft Amber
      case AlertType.info:
        return const Color(0xFFEFF6FF); // Soft Blue
    }
  }

  IconData get _icon {
    switch (widget.type) {
      case AlertType.success:
        return Icons.check_circle_rounded;
      case AlertType.error:
        return Icons.error_rounded;
      case AlertType.warning:
        return Icons.warning_amber_rounded;
      case AlertType.info:
        return Icons.info_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.only(top: 14, left: 16, right: 16),
          child: SlideTransition(
            position: _slideAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Dismissible(
                key: UniqueKey(),
                direction: DismissDirection.up,
                onDismissed: (_) => widget.onDismiss(),
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 580),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _accentColor.withOpacity(0.35), width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                        BoxShadow(
                          color: _accentColor.withOpacity(0.06),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border(
                            left: BorderSide(color: _accentColor, width: 4.5),
                          ),
                          color: _bgTint.withOpacity(0.4),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: _accentColor.withOpacity(0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(_icon, color: _accentColor, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (widget.title != null && widget.title!.isNotEmpty) ...[
                                    Text(
                                      widget.title!,
                                      style: GoogleFonts.inter(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.textMain,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                  ],
                                  Text(
                                    widget.message,
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: AppTheme.textSecondary,
                                      height: 1.35,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: _close,
                              borderRadius: BorderRadius.circular(20),
                              child: Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: Icon(
                                  Icons.close_rounded,
                                  size: 18,
                                  color: AppTheme.textMuted.withOpacity(0.7),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
