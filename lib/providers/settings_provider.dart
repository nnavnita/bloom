import 'package:bloom/services/perenual_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kApiKey = 'perenual_api_key';

class SettingsNotifier extends StateNotifier<String> {
  SettingsNotifier() : super('') {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getString(_kApiKey) ?? '';
  }

  Future<void> setApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kApiKey, key);
    state = key;
  }
}

final apiKeyProvider = StateNotifierProvider<SettingsNotifier, String>(
  (_) => SettingsNotifier(),
);

final perenualServiceProvider = Provider<PerenualService>((ref) {
  final key = ref.watch(apiKeyProvider);
  return PerenualService(apiKey: key.isEmpty ? null : key);
});
