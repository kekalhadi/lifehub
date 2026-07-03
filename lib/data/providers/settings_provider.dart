import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) async {
  return SharedPreferences.getInstance();
});

class SettingsState {
  final ThemeMode themeMode;
  final bool isLocked;
  final bool hasPinEnabled;
  final String currencySymbol;

  const SettingsState({
    this.themeMode = ThemeMode.system,
    this.isLocked = false,
    this.hasPinEnabled = false,
    this.currencySymbol = 'Rp',
  });

  SettingsState copyWith({
    ThemeMode? themeMode,
    bool? isLocked,
    bool? hasPinEnabled,
    String? currencySymbol,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      isLocked: isLocked ?? this.isLocked,
      hasPinEnabled: hasPinEnabled ?? this.hasPinEnabled,
      currencySymbol: currencySymbol ?? this.currencySymbol,
    );
  }
}

class SettingsNotifier extends AsyncNotifier<SettingsState> {
  static const _keyThemeMode = 'theme_mode';
  static const _keyHasPinEnabled = 'has_pin_enabled';
  static const _keyCurrencySymbol = 'currency_symbol';

  @override
  Future<SettingsState> build() async {
    final prefs = await ref.watch(sharedPreferencesProvider.future);
    final themeModeIndex = prefs.getInt(_keyThemeMode) ?? 0;
    final hasPinEnabled = prefs.getBool(_keyHasPinEnabled) ?? false;
    final currencySymbol = prefs.getString(_keyCurrencySymbol) ?? 'Rp';

    return SettingsState(
      themeMode: ThemeMode.values[themeModeIndex],
      hasPinEnabled: hasPinEnabled,
      currencySymbol: currencySymbol,
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.setInt(_keyThemeMode, mode.index);
    state = AsyncValue.data(state.value!.copyWith(themeMode: mode));
  }

  Future<void> setCurrencySymbol(String symbol) async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.setString(_keyCurrencySymbol, symbol);
    state = AsyncValue.data(state.value!.copyWith(currencySymbol: symbol));
  }
}

final settingsProvider = AsyncNotifierProvider<SettingsNotifier, SettingsState>(
  SettingsNotifier.new,
);

final themeModeProvider = Provider<ThemeMode>((ref) {
  return ref.watch(settingsProvider).maybeWhen(
    data: (settings) => settings.themeMode,
    orElse: () => ThemeMode.system,
  );
});