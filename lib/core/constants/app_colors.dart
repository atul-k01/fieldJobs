import 'package:flutter/material.dart';

/// Centralized color palette for the FieldJobs application.
/// Primary theme: Sky Blue and Crisp White with high-contrast functional accents.
class AppColors {
  AppColors._();

  // Primary Sky Blue Palette
  static const Color primary = Color(0xFF0284C7); // Vibrant Sky Blue
  static const Color primaryLight = Color(0xFF38BDF8); // Light Sky
  static const Color primaryDark = Color(0xFF0369A1); // Deep Ocean Blue
  static const Color primarySurface = Color(0xFFE0F2FE); // Very light sky tint for chips & highlights

  // Secondary & Accents
  static const Color accent = Color(0xFF0EA5E9);
  static const Color accentDark = Color(0xFF0284C7);

  // Background & Surfaces (Crisp White and Subtle Off-Whites)
  static const Color background = Color(0xFFF8FAFC); // Crisp soft light grey-white
  static const Color surface = Color(0xFFFFFFFF); // Pure white card/sheet background
  static const Color cardColor = Color(0xFFFFFFFF);
  static const Color divider = Color(0xFFE2E8F0);
  static const Color border = Color(0xFFCBD5E1);

  // Typography & Neutrals
  static const Color textPrimary = Color(0xFF0F172A); // Dark slate for readable text
  static const Color textSecondary = Color(0xFF475569); // Muted slate
  static const Color textTertiary = Color(0xFF94A3B8); // Subtle helper text
  static const Color textInverse = Color(0xFFFFFFFF); // White text

  // Functional & Status Colors
  static const Color statusAssigned = Color(0xFF64748B); // Slate Grey
  static const Color statusTravelling = Color(0xFF0284C7); // Sky Blue
  static const Color statusOnSite = Color(0xFFF59E0B); // Amber / In Progress
  static const Color statusCompleted = Color(0xFF10B981); // Emerald Green
  static const Color statusCancelled = Color(0xFFEF4444); // Crimson Red
  static const Color statusCouldNotComplete = Color(0xFFDC2626); // Deep Red

  // Offline & Sync Indicators
  static const Color syncPending = Color(0xFFF59E0B); // Amber warning badge
  static const Color syncSuccess = Color(0xFF10B981); // Green synced checkmark
  static const Color syncConflict = Color(0xFFEF4444); // Red conflict icon
  static const Color offlineBannerBg = Color(0xFF334155); // Dark Slate banner
  static const Color offlineBannerText = Color(0xFFF8FAFC);

  // UI Feedback
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF0284C7);
}
