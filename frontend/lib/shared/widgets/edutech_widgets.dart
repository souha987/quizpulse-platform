import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'pulse_3d_button.dart';
import 'count_up_text.dart';
import 'fade_slide_in.dart';
import 'loading_skeleton.dart';
export 'fade_slide_in.dart';
export 'loading_skeleton.dart';
export 'count_up_text.dart';
export 'edu_mascot.dart';

/// Helper to get a subject emoji icon based on subject name
String getSubjectEmoji(String subjectName) {
  final lower = subjectName.toLowerCase();
  if (lower.contains('math')) return '📐';
  if (lower.contains('bio') || lower.contains('cellule') || lower.contains('svt')) return '🧬';
  if (lower.contains('hist') || lower.contains('géo') || lower.contains('geo')) return '🏛️';
  if (lower.contains('info') || lower.contains('tech') || lower.contains('code') || lower.contains('prog') || lower.contains('ordi') || lower.contains('cyber')) return '💻';
  return '📚';
}

/// 1. CARTE DE QUIZ PROFESSIONNELLE WEB (BLEU & BLANC)
class EdTechQuizCard extends StatelessWidget {
  final String title;
  final String? teacherName;
  final String subject;
  final Color accentColor;
  final int? questionCount;
  final int? durationMinutes;
  final String? status;
  final String? dueDate;
  final String? pinCode;
  final String buttonText;
  final VoidCallback onAction;
  final bool isFreePractice;

  const EdTechQuizCard({
    super.key,
    required this.title,
    this.teacherName,
    required this.subject,
    this.accentColor = const Color(0xFF2563EB),
    this.questionCount,
    this.durationMinutes,
    this.status,
    this.dueDate,
    this.pinCode,
    this.buttonText = 'Commencer le quiz',
    required this.onAction,
    this.isFreePractice = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Liseré bleu professionnel
            Container(
              width: 4,
              color: const Color(0xFF2563EB),
            ),
            // Contenu
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badge Matière + Statut
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFDBEAFE), width: 1),
                          ),
                          child: Text(
                            subject,
                            style: const TextStyle(
                              color: Color(0xFF1D4ED8),
                              fontWeight: FontWeight.w700,
                              fontSize: 11.5,
                            ),
                          ),
                        ),
                        if (status != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              status!,
                              style: const TextStyle(
                                color: Color(0xFF475569),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                        const Spacer(),
                        const Icon(Icons.more_horiz, color: Color(0xFF94A3B8), size: 18),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Titre avec icône/emoji de matière
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 1, right: 6),
                          child: Text(
                            getSubjectEmoji(subject),
                            style: const TextStyle(fontSize: 15),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 16.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                              letterSpacing: -0.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (teacherName != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        teacherName!,
                        style: const TextStyle(color: Color(0xFF64748B), fontSize: 12.5),
                      ),
                    ],
                    const SizedBox(height: 12),

                    // Métadonnées
                    Wrap(
                      spacing: 14,
                      runSpacing: 6,
                      children: [
                        if (questionCount != null)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.help_outline, size: 14, color: Color(0xFF64748B)),
                              const SizedBox(width: 4),
                              Text(
                                '$questionCount questions',
                                style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        if (durationMinutes != null)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.timer_outlined, size: 14, color: Color(0xFF64748B)),
                              const SizedBox(width: 4),
                              Text(
                                '$durationMinutes min',
                                style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        if (isFreePractice)
                          const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle_outline, size: 14, color: Color(0xFF2563EB)),
                              SizedBox(width: 4),
                              Text(
                                'Entraînement libre',
                                style: TextStyle(color: Color(0xFF2563EB), fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        if (pinCode != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Text(
                              'PIN : $pinCode',
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                                color: Color(0xFF334155),
                              ),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 14),
                    const Divider(height: 1, color: Color(0xFFF1F5F9)),
                    const SizedBox(height: 12),

                    // Footer : Échéance + Bouton Action
                    Row(
                      children: [
                        if (dueDate != null)
                          Row(
                            children: [
                              const Icon(Icons.schedule, size: 14, color: Color(0xFFE11D48)),
                              const SizedBox(width: 6),
                              Text(
                                dueDate!,
                                style: const TextStyle(
                                  color: Color(0xFFE11D48),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          )
                        else if (isFreePractice)
                          const Text(
                            'Accès immédiat',
                            style: TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                        const Spacer(),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            elevation: 0,
                          ),
                          onPressed: onAction,
                          icon: const Icon(Icons.arrow_forward_rounded, size: 14),
                          label: Text(buttonText, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                        ),
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

/// 2. STAT CARD MÉTRIQUE PROFESSIONNELLE WEB (BLANC & BLEU)
class EdTechStatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final Color? cardBgColor;
  final Color? borderColor;
  final String? variationText;
  final bool isVariationPositive;

  const EdTechStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    this.iconColor = const Color(0xFF2563EB),
    this.iconBgColor = const Color(0xFFEFF6FF),
    this.cardBgColor,
    this.borderColor,
    this.variationText,
    this.isVariationPositive = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF475569),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: const Color(0xFF2563EB), size: 18),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              CountUpText(
                value: value,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.8,
                ),
              ),
              if (variationText != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: isVariationPositive ? const Color(0xFFEFF6FF) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    variationText!,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isVariationPositive ? const Color(0xFF1D4ED8) : const Color(0xFF475569),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12.5,
              color: Color(0xFF334155),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// 3. BANNIÈRE HERO DASHBOARD PROFESSIONNELLE WEB (BLEU ROYAL & BLANC)
class EdTechHeroBanner extends StatelessWidget {
  final String tag;
  final String title;
  final String description;
  final String buttonText;
  final VoidCallback onAction;
  final String? secondaryButtonText;
  final VoidCallback? onSecondaryAction;
  final Gradient? gradient;

  const EdTechHeroBanner({
    super.key,
    required this.tag,
    required this.title,
    required this.description,
    required this.buttonText,
    required this.onAction,
    this.secondaryButtonText,
    this.onSecondaryAction,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: gradient ?? const LinearGradient(
          colors: [Color(0xFF1E40AF), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 22),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tag
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    tag.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 10.5,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: const TextStyle(
                    color: Color(0xFFDBEAFE),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF1E40AF),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        elevation: 0,
                      ),
                      onPressed: onAction,
                      icon: const Icon(Icons.add_rounded, size: 16, color: Color(0xFF1E40AF)),
                      label: Text(
                        buttonText,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1E40AF)),
                      ),
                    ),
                    if (secondaryButtonText != null && onSecondaryAction != null)
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF1E40AF),
                          backgroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          elevation: 0,
                        ),
                        onPressed: onSecondaryAction,
                        child: Text(
                          secondaryButtonText!,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1E40AF)),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 4. WIDGET SÉRIE D'APPRENTISSAGE
class StreakWidget extends StatelessWidget {
  final int streakDays;

  const StreakWidget({super.key, this.streakDays = 7});

  @override
  Widget build(BuildContext context) {
    const days = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.bolt_rounded, size: 18, color: Color(0xFF2563EB)),
              SizedBox(width: 8),
              Text(
                'Série d\'apprentissage',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Continuez votre rythme d\'entraînement hebdomadaire.',
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 14),

          // Cercles des jours L M M J V S D
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (index) {
              final isCompleted = index < 6;
              final isCurrent = index == 6;

              return Column(
                children: [
                  Text(
                    days[index],
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8)),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? const Color(0xFFEFF6FF)
                          : (isCurrent ? const Color(0xFF2563EB) : const Color(0xFFF8FAFC)),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isCompleted
                            ? const Color(0xFFBFDBFE)
                            : (isCurrent ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0)),
                      ),
                    ),
                    child: Center(
                      child: isCompleted
                          ? const Icon(Icons.check, size: 14, color: Color(0xFF2563EB))
                          : Text(
                              isCurrent ? '$streakDays' : '-',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isCurrent ? Colors.white : const Color(0xFF94A3B8),
                              ),
                            ),
                    ),
                  ),
                ],
              );
            }),
          ),
          const SizedBox(height: 14),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFDBEAFE)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 14, color: Color(0xFF2563EB)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '$streakDays jours consécutifs actifs. Plus qu\'un quiz pour valider la semaine.',
                    style: const TextStyle(color: Color(0xFF1D4ED8), fontSize: 11.5, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 5. WIDGET PROGRÈS PAR MATIÈRE
class SubjectProgressWidget extends StatelessWidget {
  final VoidCallback? onViewDetails;

  const SubjectProgressWidget({super.key, this.onViewDetails});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.trending_up, size: 18, color: Color(0xFF2563EB)),
              SizedBox(width: 8),
              Text(
                'Progression par matière',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Moyenne globale des évaluations.',
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 16),

          _buildProgressBar('Mathématiques', 0.85, '85%', const Color(0xFF2563EB)),
          const SizedBox(height: 12),
          _buildProgressBar('Biologie', 0.72, '72%', const Color(0xFF3B82F6)),
          const SizedBox(height: 12),
          _buildProgressBar('Histoire', 0.64, '64%', const Color(0xFF64748B)),

          const SizedBox(height: 14),
          InkWell(
            onTap: onViewDetails,
            child: const Row(
              children: [
                Text(
                  'Voir les analyses complètes',
                  style: TextStyle(color: Color(0xFF2563EB), fontSize: 12.5, fontWeight: FontWeight.w600),
                ),
                SizedBox(width: 4),
                Icon(Icons.arrow_forward, size: 14, color: Color(0xFF2563EB)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(String label, double value, String percentage, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
            Text(percentage, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value,
            backgroundColor: const Color(0xFFF1F5F9),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}

/// 6. WIDGET REJOINDRE UNE CLASSE
class JoinClassCardWidget extends StatelessWidget {
  final bool isTeacher;
  final VoidCallback onAction;

  const JoinClassCardWidget({
    super.key,
    this.isTeacher = false,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.people_outline, color: Color(0xFF2563EB), size: 16),
              ),
              const SizedBox(width: 8),
              Text(
                isTeacher ? 'Espaces de cours' : 'Rejoindre une classe',
                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            isTeacher
                ? 'Partagez vos quiz directement avec vos groupes d\'étudiants.'
                : 'Saisissez le code fourni par votre enseignant.',
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.35),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF0F172A),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              onPressed: onAction,
              icon: const Icon(Icons.add, size: 15, color: Color(0xFF2563EB)),
              label: Text(
                isTeacher ? 'Créer une classe' : 'Entrer un code classe',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 7. CARTE DE CLASSE PROFESSIONNELLE
class EdTechClassCard extends StatelessWidget {
  final String title;
  final String teacherName;
  final String classCode;
  final int studentCount;
  final String iconSymbol;
  final Color headerBgColor;
  final Color symbolColor;
  final VoidCallback onViewClass;
  final bool isDeleted;
  final String? deletedDateStr;

  const EdTechClassCard({
    super.key,
    required this.title,
    required this.teacherName,
    required this.classCode,
    required this.studentCount,
    required this.iconSymbol,
    this.headerBgColor = const Color(0xFFEFF6FF),
    this.symbolColor = const Color(0xFF2563EB),
    required this.onViewClass,
    this.isDeleted = false,
    this.deletedDateStr,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDeleted ? const Color(0xFFFFFDFD) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDeleted ? const Color(0xFFFCA5A5) : const Color(0xFFE2E8F0),
          width: isDeleted ? 1.4 : 1.0,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 70,
            width: double.infinity,
            color: isDeleted ? const Color(0xFFFEF2F2) : const Color(0xFFF8FAFC),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isDeleted ? const Color(0xFFFEE2E2) : const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(
                    child: Icon(
                      isDeleted ? Icons.delete_outline_rounded : Icons.school_outlined,
                      color: isDeleted ? const Color(0xFFDC2626) : const Color(0xFF2563EB),
                      size: 20,
                    ),
                  ),
                ),
                const Spacer(),
                if (isDeleted)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: const Color(0xFFFCA5A5)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.warning_amber_rounded, size: 12, color: Color(0xFFDC2626)),
                        SizedBox(width: 4),
                        Text(
                          'Supprimée par l\'enseignant',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFB91C1C),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Text(
                      '$studentCount élèves',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isDeleted ? const Color(0xFF64748B) : const Color(0xFF0F172A),
                          letterSpacing: -0.3,
                          decoration: isDeleted ? TextDecoration.lineThrough : null,
                          decorationColor: const Color(0xFFDC2626),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  teacherName,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF64748B),
                  ),
                ),
                if (isDeleted && deletedDateStr != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Clôturée le $deletedDateStr',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFDC2626),
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Code : $classCode',
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w700,
                        color: isDeleted ? const Color(0xFF94A3B8) : const Color(0xFF334155),
                      ),
                    ),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isDeleted ? const Color(0xFF64748B) : const Color(0xFF2563EB),
                        side: BorderSide(
                          color: isDeleted ? const Color(0xFFCBD5E1) : const Color(0xFFBFDBFE),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                      onPressed: onViewClass,
                      child: Text(
                        isDeleted ? 'Voir archive' : 'Ouvrir',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
