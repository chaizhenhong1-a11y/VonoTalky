import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum VonoThemeColor {
  purple,
  pink,
  blue,
  green,
  orange;

  String get label => switch (this) {
    VonoThemeColor.purple => 'Purple',
    VonoThemeColor.pink => 'Pink',
    VonoThemeColor.blue => 'Blue',
    VonoThemeColor.green => 'Green',
    VonoThemeColor.orange => 'Orange',
  };

  Color get seed => switch (this) {
    VonoThemeColor.purple => const Color(0xFF7653A5),
    VonoThemeColor.pink => const Color(0xFFE93E86),
    VonoThemeColor.blue => const Color(0xFF3478F6),
    VonoThemeColor.green => const Color(0xFF32B789),
    VonoThemeColor.orange => const Color(0xFFFF8A32),
  };

  Color get secondary => switch (this) {
    VonoThemeColor.purple => const Color(0xFFB77AE4),
    VonoThemeColor.pink => const Color(0xFFFF73A7),
    VonoThemeColor.blue => const Color(0xFF5AA8FF),
    VonoThemeColor.green => const Color(0xFF57D4A7),
    VonoThemeColor.orange => const Color(0xFFFFB04D),
  };

  Color get authOverlay => switch (this) {
    VonoThemeColor.purple => const Color(0xFF5A19B8),
    VonoThemeColor.pink => const Color(0xFFD92370),
    VonoThemeColor.blue => const Color(0xFF0755B8),
    VonoThemeColor.green => const Color(0xFF087A65),
    VonoThemeColor.orange => const Color(0xFFD65B20),
  };

  String get authAssetPath => 'assets/images/auth_theme_$name.jpg';
}

@immutable
class VonoThemePreferences {
  const VonoThemePreferences({
    this.mode = ThemeMode.system,
    this.color = VonoThemeColor.purple,
  });

  final ThemeMode mode;
  final VonoThemeColor color;

  VonoThemePreferences copyWith({ThemeMode? mode, VonoThemeColor? color}) =>
      VonoThemePreferences(mode: mode ?? this.mode, color: color ?? this.color);
}

class VonoThemeController extends ValueNotifier<VonoThemePreferences> {
  VonoThemeController._() : super(const VonoThemePreferences());

  static final VonoThemeController instance = VonoThemeController._();

  static const _modeKey = 'vonotalky.theme.mode';
  static const _colorKey = 'vonotalky.theme.color';

  SharedPreferences? _preferences;

  Future<void> initialize() async {
    _preferences = await SharedPreferences.getInstance();
    final modeName = _preferences?.getString(_modeKey);
    final colorName = _preferences?.getString(_colorKey);

    value = VonoThemePreferences(
      mode:
          ThemeMode.values.where((item) => item.name == modeName).firstOrNull ??
          ThemeMode.system,
      color:
          VonoThemeColor.values
              .where((item) => item.name == colorName)
              .firstOrNull ??
          VonoThemeColor.purple,
    );
  }

  Future<void> setMode(ThemeMode mode) async {
    if (value.mode == mode) return;
    value = value.copyWith(mode: mode);
    await _preferences?.setString(_modeKey, mode.name);
  }

  Future<void> setColor(VonoThemeColor color) async {
    if (value.color == color) return;
    value = value.copyWith(color: color);
    await _preferences?.setString(_colorKey, color.name);
  }
}

extension FirstOrNullExtension<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    if (!iterator.moveNext()) return null;
    return iterator.current;
  }
}
