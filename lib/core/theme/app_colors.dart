import 'package:flutter/material.dart';

/// Central palette for Tickr. Use via [Theme.of(context).colorScheme] where possible,
/// and reference these for one-off accents that are not mapped in [ColorScheme].
class AppColors {
  AppColors._();

  //---------Green and Brown Combination
  // —— Brand ——
  static const Color primary = Color(0xFF1E4D48);
  static const Color primaryBright = Color(0xFF2D6B64);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color accent = Color(0xFFE07A5F);
  static const Color onAccent = Color(0xFFFFFFFF);

  // —— Surfaces ——
  static const Color background = Color(0xFFF3F1EC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceElevated = Color(0xFFFDFCFA);
  static const Color surfaceMuted = Color(0xFFE8E6E1);

  // —— Text ——
  static const Color textPrimary = Color(0xFF1C1B18);
  static const Color textSecondary = Color(0xFF57534E);
  static const Color textTertiary = Color(0xFF78716C);

  // —— Lines & chrome ——
  static const Color outline = Color(0xFFD6D3CD);
  static const Color outlineVariant = Color(0xFFECEAE5);
  static const Color divider = Color(0xFFDDD9D2);

  // —— Accents for lists & badges ——
  static const Color recurring = Color(0xFF3D6B62);
  static const Color todayHighlight = Color(0xFFFFF4E6);
  static const Color calendarMarker = Color(0xFFC17F59);

  // —— Semantic ——
  static const Color error = Color(0xFFB3261E);
  static const Color errorContainer = Color(0xFFF9DEDC);

  // —— Shadows / overlays ——
  static const Color shadow = Color(0x1A1C1B18);

  // ===== Purple-Pink-Blue =====
  // static const Color primary = Color(0xFF4F46E5);
  // static const Color primaryBright = Color(0xFF6366F1);
  // static const Color onPrimary = Color(0xFFFFFFFF);
  // static const Color accent = Color(0xFFEC4899);
  // static const Color onAccent = Color(0xFFFFFFFF);
  //
  // static const Color background = Color(0xFFF9FAFB);
  // static const Color surface = Color(0xFFFFFFFF);
  // static const Color surfaceElevated = Color(0xFFF3F4F6);
  // static const Color surfaceMuted = Color(0xFFE5E7EB);
  //
  // static const Color textPrimary = Color(0xFF111827);
  // static const Color textSecondary = Color(0xFF4B5563);
  // static const Color textTertiary = Color(0xFF9CA3AF);
  //
  // static const Color outline = Color(0xFFE5E7EB);
  // static const Color outlineVariant = Color(0xFFF3F4F6);
  // static const Color divider = Color(0xFFE5E7EB);
  //
  // static const Color recurring = Color(0xFF6366F1);
  // static const Color todayHighlight = Color(0xFFFDF2F8);
  // static const Color calendarMarker = Color(0xFFEC4899);
  //
  // static const Color error = Color(0xFFDC2626);
  // static const Color errorContainer = Color(0xFFFEE2E2);
  //
  // static const Color shadow = Color(0x1A111827);

// ===== THEME: Modern Dark Teal =====
//   static const Color primary = Color(0xFF0F172A);
//   static const Color primaryBright = Color(0xFF1E293B);
//   static const Color onPrimary = Color(0xFFFFFFFF);
//   static const Color accent = Color(0xFF22C55E);
//   static const Color onAccent = Color(0xFF052E16);
//
//   static const Color background = Color(0xFFF8FAFC);
//   static const Color surface = Color(0xFFFFFFFF);
//   static const Color surfaceElevated = Color(0xFFF1F5F9);
//   static const Color surfaceMuted = Color(0xFFE2E8F0);
//
//   static const Color textPrimary = Color(0xFF020617);
//   static const Color textSecondary = Color(0xFF475569);
//   static const Color textTertiary = Color(0xFF94A3B8);
//
//   static const Color outline = Color(0xFFE2E8F0);
//   static const Color outlineVariant = Color(0xFFF1F5F9);
//   static const Color divider = Color(0xFFE5E7EB);
//
//   static const Color recurring = Color(0xFF0EA5E9);
//   static const Color todayHighlight = Color(0xFFECFDF5);
//   static const Color calendarMarker = Color(0xFF22C55E);
//
//   static const Color error = Color(0xFFDC2626);
//   static const Color errorContainer = Color(0xFFFEE2E2);
//
//   static const Color shadow = Color(0x1A020617);


// ===== THEME: Warm Minimal =====
//   static const Color primary = Color(0xFF7C5C3B);
//   static const Color primaryBright = Color(0xFFA47551);
//   static const Color onPrimary = Color(0xFFFFFFFF);
//   static const Color accent = Color(0xFFD97706);
//   static const Color onAccent = Color(0xFFFFFFFF);
//
//   static const Color background = Color(0xFFFAF7F2);
//   static const Color surface = Color(0xFFFFFFFF);
//   static const Color surfaceElevated = Color(0xFFF5EFE6);
//   static const Color surfaceMuted = Color(0xFFE7DCCB);
//
//   static const Color textPrimary = Color(0xFF2B2118);
//   static const Color textSecondary = Color(0xFF6B5E55);
//   static const Color textTertiary = Color(0xFF9A8F87);
//
//   static const Color outline = Color(0xFFE5D9C8);
//   static const Color outlineVariant = Color(0xFFF1E8DC);
//   static const Color divider = Color(0xFFEADFCF);
//
//   static const Color recurring = Color(0xFF8B5E34);
//   static const Color todayHighlight = Color(0xFFFFF7ED);
//   static const Color calendarMarker = Color(0xFFD97706);
//
//   static const Color error = Color(0xFFB91C1C);
//   static const Color errorContainer = Color(0xFFFEE2E2);
//
//   static const Color shadow = Color(0x1A2B2118);

// ===== THEME: Dark Mode =====
//   static const Color primary = Color(0xFF22C55E);
//   static const Color primaryBright = Color(0xFF4ADE80);
//   static const Color onPrimary = Color(0xFF022C22);
//   static const Color accent = Color(0xFF60A5FA);
//   static const Color onAccent = Color(0xFF0B132B);
//
//   static const Color background = Color(0xFF020617);
//   static const Color surface = Color(0xFF020617);
//   static const Color surfaceElevated = Color(0xFF0F172A);
//   static const Color surfaceMuted = Color(0xFF1E293B);
//
//   static const Color textPrimary = Color(0xFFFFFFFF);
//   static const Color textSecondary = Color(0xFFCBD5F5);
//   static const Color textTertiary = Color(0xFF64748B);
//
//   static const Color outline = Color(0xFF1E293B);
//   static const Color outlineVariant = Color(0xFF0F172A);
//   static const Color divider = Color(0xFF1E293B);
//
//   static const Color recurring = Color(0xFF38BDF8);
//   static const Color todayHighlight = Color(0xFF052E2B);
//   static const Color calendarMarker = Color(0xFF60A5FA);
//
//   static const Color error = Color(0xFFEF4444);
//   static const Color errorContainer = Color(0xFF7F1D1D);
//
//   static const Color shadow = Color(0x66000000);
}
