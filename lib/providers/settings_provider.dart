import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/settings_service.dart';

/// 主题色 Provider
final themeColorProvider = StateProvider<Color>((ref) {
  return SettingsService.defaultColor;
});
