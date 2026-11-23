import 'package:flutter/material.dart';

/// Les différentes humeurs / états disponibles pour la mascotte EduTech.
enum MascotMood {
  happy,
  celebrate,
  thinking,
  encourage;

  /// Chemin de l'asset image correspondant à l'humeur.
  String get assetPath {
    switch (this) {
      case MascotMood.happy:
        return 'assets/mascotte/mascotte_happy.png';
      case MascotMood.celebrate:
        return 'assets/mascotte/mascotte_celebrate.png';
      case MascotMood.thinking:
        return 'assets/mascotte/mascotte_thinking.png';
      case MascotMood.encourage:
        return 'assets/mascotte/mascotte_encourage.png';
    }
  }

  /// Description sémantique accessible par défaut.
  String get defaultSemanticLabel {
    switch (this) {
      case MascotMood.happy:
        return 'Mascotte souriante et joyeuse';
      case MascotMood.celebrate:
        return 'Mascotte en fête qui célèbre';
      case MascotMood.thinking:
        return 'Mascotte pensive qui réfléchit';
      case MascotMood.encourage:
        return 'Mascotte encourageante qui soutient';
    }
  }

  /// Icône de secours si l'image ne peut pas être chargée.
  IconData get fallbackIcon {
    switch (this) {
      case MascotMood.happy:
        return Icons.sentiment_very_satisfied_rounded;
      case MascotMood.celebrate:
        return Icons.celebration_rounded;
      case MascotMood.thinking:
        return Icons.psychology_rounded;
      case MascotMood.encourage:
        return Icons.thumb_up_alt_rounded;
    }
  }
}

/// Widget réutilisable représentant la mascotte d'apprentissage EduTech.
///
/// Accepte un [mood] (humeur) et une [size] (taille), avec animation de flottaison
/// douce en boucle (6 px, cycle de 2.4 s) et un petit saut d'apparition pour
/// l'humeur [MascotMood.celebrate].
///
/// ```dart
/// EduMascot(mood: MascotMood.happy, size: 96)
/// // ou
/// EduMascot.celebrate(size: 120)
/// ```
class EduMascot extends StatefulWidget {
  final MascotMood mood;
  final double size;
  final double? width;
  final double? height;
  final BoxFit fit;
  final AlignmentGeometry alignment;
  final bool animate;
  final String? semanticLabel;

  const EduMascot({
    super.key,
    required this.mood,
    this.size = 100.0,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.animate = true,
    this.semanticLabel,
  });

  /// Constructeur de commodité pour l'humeur `happy` (joie/succès).
  const EduMascot.happy({
    Key? key,
    double size = 100.0,
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
    AlignmentGeometry alignment = Alignment.center,
    bool animate = true,
    String? semanticLabel,
  }) : this(
          key: key,
          mood: MascotMood.happy,
          size: size,
          width: width,
          height: height,
          fit: fit,
          alignment: alignment,
          animate: animate,
          semanticLabel: semanticLabel,
        );

  /// Constructeur de commodité pour l'humeur `celebrate` (victoire/score parfait).
  const EduMascot.celebrate({
    Key? key,
    double size = 100.0,
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
    AlignmentGeometry alignment = Alignment.center,
    bool animate = true,
    String? semanticLabel,
  }) : this(
          key: key,
          mood: MascotMood.celebrate,
          size: size,
          width: width,
          height: height,
          fit: fit,
          alignment: alignment,
          animate: animate,
          semanticLabel: semanticLabel,
        );

  /// Constructeur de commodité pour l'humeur `thinking` (réflexion/question difficile).
  const EduMascot.thinking({
    Key? key,
    double size = 100.0,
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
    AlignmentGeometry alignment = Alignment.center,
    bool animate = true,
    String? semanticLabel,
  }) : this(
          key: key,
          mood: MascotMood.thinking,
          size: size,
          width: width,
          height: height,
          fit: fit,
          alignment: alignment,
          animate: animate,
          semanticLabel: semanticLabel,
        );

  /// Constructeur de commodité pour l'humeur `encourage` (encouragement/aide).
  const EduMascot.encourage({
    Key? key,
    double size = 100.0,
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
    AlignmentGeometry alignment = Alignment.center,
    bool animate = true,
    String? semanticLabel,
  }) : this(
          key: key,
          mood: MascotMood.encourage,
          size: size,
          width: width,
          height: height,
          fit: fit,
          alignment: alignment,
          animate: animate,
          semanticLabel: semanticLabel,
        );

  @override
  State<EduMascot> createState() => _EduMascotState();
}

class _EduMascotState extends State<EduMascot> with TickerProviderStateMixin {
  AnimationController? _floatController;
  Animation<double>? _floatAnimation;

  AnimationController? _jumpController;
  Animation<double>? _jumpAnimation;
  Animation<double>? _jumpScaleAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    if (widget.animate) {
      // Flottaison lente : oscillation de 6 px avec un cycle complet (aller-retour) de 2.4 s
      _floatController = AnimationController(
        duration: const Duration(milliseconds: 1200),
        vsync: this,
      )..repeat(reverse: true);

      _floatAnimation = Tween<double>(begin: 0.0, end: -6.0).animate(
        CurvedAnimation(
          parent: _floatController!,
          curve: Curves.easeInOut,
        ),
      );

      // Petit saut initial à l'apparition pour l'humeur 'celebrate'
      if (widget.mood == MascotMood.celebrate) {
        _initJumpAnimation();
      }
    }
  }

  void _initJumpAnimation() {
    _jumpController = AnimationController(
      duration: const Duration(milliseconds: 650),
      vsync: this,
    );

    // Trajectoire du saut : monte rapidement de 16 px puis redescend avec rebond doux
    _jumpAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: -16.0)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 45,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: -16.0, end: 0.0)
            .chain(CurveTween(curve: Curves.bounceOut)),
        weight: 55,
      ),
    ]).animate(_jumpController!);

    // Légère élasticité d'échelle pendant le saut
    _jumpScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.08)
            .chain(CurveTween(curve: Curves.easeOutQuad)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.08, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInQuad)),
        weight: 60,
      ),
    ]).animate(_jumpController!);

    _jumpController!.forward();
  }

  @override
  void didUpdateWidget(covariant EduMascot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate && !oldWidget.animate) {
      _setupAnimations();
    } else if (!widget.animate && oldWidget.animate) {
      _floatController?.stop();
      _jumpController?.stop();
    }

    if (widget.animate &&
        widget.mood == MascotMood.celebrate &&
        oldWidget.mood != MascotMood.celebrate) {
      if (_jumpController == null) {
        _initJumpAnimation();
      } else {
        _jumpController!.reset();
        _jumpController!.forward();
      }
    }
  }

  @override
  void dispose() {
    _floatController?.dispose();
    _jumpController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double targetWidth = widget.width ?? widget.size;
    final double targetHeight = widget.height ?? widget.size;

    Widget imageWidget = Image.asset(
      widget.mood.assetPath,
      width: targetWidth,
      height: targetHeight,
      fit: widget.fit,
      alignment: widget.alignment,
      semanticLabel: widget.semanticLabel ?? widget.mood.defaultSemanticLabel,
      errorBuilder: (context, error, stackTrace) {
        // Fallback transparent sans cercle ni fond
        return SizedBox(
          width: targetWidth,
          height: targetHeight,
          child: Center(
            child: Icon(
              widget.mood.fallbackIcon,
              size: targetWidth * 0.5,
              color: const Color(0xFF2563EB),
            ),
          ),
        );
      },
    );

    if (!widget.animate) {
      return imageWidget;
    }

    // Combine animation de saut (celebrate) et flottaison continue
    return AnimatedBuilder(
      animation: Listenable.merge([
        if (_floatController != null) _floatController!,
        if (_jumpController != null) _jumpController!,
      ]),
      builder: (context, child) {
        final floatOffset = _floatAnimation?.value ?? 0.0;
        final jumpOffset = _jumpAnimation?.value ?? 0.0;
        final scale = _jumpScaleAnimation?.value ?? 1.0;

        return Transform.translate(
          offset: Offset(0, floatOffset + jumpOffset),
          child: Transform.scale(
            scale: scale,
            child: child,
          ),
        );
      },
      child: imageWidget,
    );
  }
}

/// Widget réutilisable pour afficher un état vide (listes sans données, analyses vides)
/// avec la mascotte en posture de réflexion (thinking, 120 px) au-dessus d'un court message.
class EduEmptyState extends StatelessWidget {
  final String message;
  final String? subtitle;
  final Widget? action;

  const EduEmptyState({
    super.key,
    required this.message,
    this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const EduMascot(
              mood: MascotMood.thinking,
              size: 120,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E293B),
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(
                subtitle!,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF64748B),
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 18),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
