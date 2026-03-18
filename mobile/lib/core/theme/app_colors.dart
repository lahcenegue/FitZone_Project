import 'package:flutter/material.dart';

/// Base class for application colors to enforce consistency across themes.
abstract class AppColors {
  Color get primary;
  Color get background;
  Color get surface;
  Color get textPrimary;
  Color get textSecondary;
  Color get error;
  Color get shadow;
  Color get iconGrey;
  Color get markerGym;
  Color get markerRestaurant;
  Color get markerTrainer;
  Color get success;
  Color get warning;
  Color get star;
}

/// Light theme color palette.
class LightColors implements AppColors {
  @override
  Color get primary => const Color(0xFF2563EB);
  @override
  Color get background => const Color(0xFFF8FAFC);
  @override
  Color get surface => const Color(0xFFFFFFFF);
  @override
  Color get textPrimary => const Color(0xFF0F172A);
  @override
  Color get textSecondary => const Color(0xFF64748B);
  @override
  Color get error => const Color(0xFFEF4444);
  @override
  Color get shadow => const Color(0x1A000000); // 10% opacity black
  @override
  Color get iconGrey => const Color(0xFF94A3B8);
  @override
  Color get markerGym => const Color(0xFF3B82F6); // Premium Blue for Gyms
  @override
  Color get markerRestaurant => const Color(0xFFF59E0B); // Amber for Restaurants
  @override
  Color get markerTrainer => const Color(0xFF10B981); // Emerald Green for Trainers
  @override
  Color get success => const Color(0xFF10B981); // Emerald Green
  @override
  Color get warning => const Color(0xFFF59E0B); // Amber
  @override
  Color get star => const Color(0xFFFBBF24); // Star Yellow
}

/// Dark theme color palette.
class DarkColors implements AppColors {
  @override
  Color get primary => const Color(0xFF3B82F6);
  @override
  Color get background => const Color(0xFF0F172A);
  @override
  Color get surface => const Color(0xFF1E293B);
  @override
  Color get textPrimary => const Color(0xFFF8FAFC);
  @override
  Color get textSecondary => const Color(0xFF94A3B8);
  @override
  Color get error => const Color(0xFFF87171);
  @override
  Color get shadow => const Color(0x33000000); // 20% opacity black
  @override
  Color get iconGrey => const Color(0xFF64748B);
  @override
  Color get markerGym => const Color(0xFF3B82F6); // Premium Blue for Gyms
  @override
  Color get markerRestaurant => const Color(0xFFF59E0B); // Amber for Restaurants
  @override
  Color get markerTrainer => const Color(0xFF10B981); // Emerald Green for Trainers
  @override
  Color get success => const Color(0xFF34D399);
  @override
  Color get warning => const Color(0xFFFBBF24);
  @override
  Color get star => const Color(0xFFFCD34D);
}
