import 'package:flutter/material.dart';

class QuizPulseLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final Color textColor;
  final VoidCallback? onTap;

  const QuizPulseLogo({
    super.key,
    this.size = 32,
    this.showText = true,
    this.textColor = const Color(0xFF0F172A),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: onTap,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB),
                borderRadius: BorderRadius.circular(size * 0.25),
              ),
              child: Center(
                child: Icon(
                  Icons.school_rounded,
                  color: Colors.white,
                  size: size * 0.58,
                ),
              ),
            ),
            if (showText) ...[
              const SizedBox(width: 10),
              RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: size * 0.56,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                  ),
                  children: [
                    TextSpan(
                      text: 'Edu',
                      style: TextStyle(color: textColor),
                    ),
                    const TextSpan(
                      text: 'Quiz',
                      style: TextStyle(color: Color(0xFF2563EB)),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
