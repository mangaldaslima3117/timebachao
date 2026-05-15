// user_provider.dart
import 'package:bookmyservice/models/role_model.dart';
import 'package:bookmyservice/services/shared_preferences_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final sharedPrefsServiceProvider = Provider<SharedPrefsService>((ref) {
  return SharedPrefsService();
});

final roleProvider =
    StateNotifierProvider<ServiceModelNotifier, RoleModel?>((ref) {
  final sharedPrefsService = ref.read(sharedPrefsServiceProvider);
  return ServiceModelNotifier(sharedPrefsService); // pass the argument here
});

class ServiceModelNotifier extends StateNotifier<RoleModel?> {
  final SharedPrefsService _prefsService;

  ServiceModelNotifier(this._prefsService) : super(null) {
    getRoleType();
  }

  Future<void> getRoleType() async {
    final role = await _prefsService.getRole(); // Fetch from SharedPreferences

    // Fallback to a default if null
    final roleValue = role ?? 'maid';

    state = RoleModel(
      canRead: false,
      canWrite: false,
      isSuperAdmin: false,
      roleType: roleValue,
    );
  }
}
