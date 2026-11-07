// lib/presentation/widgets/modern_course_card.dart

import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_styles.dart';
import '../../domain/entities/course_entity.dart';

class ModernCourseCard extends StatelessWidget {
  final CourseEntity course;
  final VoidCallback? onTap;
  final bool showProgress;
  final double? progress;
  final bool isEnrolled;
  final bool showBadge;

  const ModernCourseCard({
    super.key,
    required this.course,
    this.onTap,
    this.showProgress = false,
    this.progress,
    this.isEnrolled = false,
    this.showBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 4,
      shadowColor:
          isDark
              ? Colors.black.withOpacity(0.3)
              : Colors.black.withOpacity(0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppStyles.radiusL),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppStyles.radiusL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Course Thumbnail
            Stack(
              children: [
                Container(
                  height: 160,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppStyles.radiusL),
                    ),
                    gradient: AppColors.primaryGradient,
                  ),
                  child: _buildPlaceholderThumbnail(),
                ),

                // Progress Overlay
                if (showProgress && progress != null)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(AppStyles.radiusL),
                        ),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: progress!.clamp(0.0, 1.0),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: AppColors.accentGradient,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(AppStyles.radiusL),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                // Badge
                if (showBadge)
                  Positioned(
                    top: AppStyles.spacingS,
                    right: AppStyles.spacingS,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppStyles.spacingS,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accentOrange,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Nuevo',
                        style: AppStyles.labelSmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                // Play Button Overlay
                if (isEnrolled)
                  Positioned.fill(
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(AppStyles.spacingM),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            // Course Content
            Padding(
              padding: const EdgeInsets.all(AppStyles.spacingM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Course Title
                  Text(
                    course.title,
                    style: AppStyles.titleLarge.copyWith(
                      color: AppColors.getTextPrimaryColor(isDark),
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: AppStyles.spacingS),

                  // Course Description
                  if (course.description.isNotEmpty)
                    Text(
                      course.description,
                      style: AppStyles.bodyMedium.copyWith(
                        color: AppColors.getTextSecondaryColor(isDark),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                  const SizedBox(height: AppStyles.spacingM),

                  // Course Metadata
                  Row(
                    children: [
                      // Lessons Count
                      Icon(
                        Icons.play_lesson_outlined,
                        size: 16,
                        color: AppColors.getTextMutedColor(isDark),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Microformación',
                        style: AppStyles.caption.copyWith(
                          color: AppColors.getTextMutedColor(isDark),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppStyles.spacingM),

                  // Action Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onTap,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            isEnrolled
                                ? AppColors.accentGreen
                                : AppColors.primaryBlue,
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppStyles.radiusM,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: AppStyles.spacingM,
                        ),
                      ),
                      child: Text(
                        isEnrolled ? 'Continuar' : 'Comenzar',
                        style: AppStyles.ctaButton.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderThumbnail() {
    Widget imageWidget;
    imageWidget = _buildDefaultThumbnail();

    // Wrap the image with a column to add the course name below
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        imageWidget,
        // Course name container with padding and styling
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppStyles.spacingM,
            vertical: AppStyles.spacingS,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(AppStyles.radiusL),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            course.title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildDefaultThumbnail() {
    return Container(
      height: 140, // Match the height of the network image
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppStyles.radiusL),
        ),
        gradient: AppColors.primaryGradient,
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.play_circle_filled, color: Colors.white, size: 48),
            SizedBox(height: 8),
            Text(
              'Ver video',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
