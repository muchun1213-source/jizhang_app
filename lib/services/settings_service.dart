import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const _keyThemeColor = 'theme_color';
  static const Color defaultColor = Color(0xFF4CAF50);

  static Future<Color> loadThemeColor() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final colorValue = prefs.getInt(_keyThemeColor);
      return colorValue != null ? Color(colorValue) : defaultColor;
    } catch (_) {
      return defaultColor;
    }
  }

  static Future<void> saveThemeColor(Color color) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyThemeColor, color.value);
  }
}

/// 预设主题色
const presetColors = [
  Color(0xFF4CAF50), // 绿
  Color(0xFF2196F3), // 蓝
  Color(0xFF9C27B0), // 紫
  Color(0xFFFF9800), // 橙
  Color(0xFFE91E63), // 粉
  Color(0xFF009688), // 青
  Color(0xFF795548), // 棕
  Color(0xFF607D8B), // 灰蓝
];
