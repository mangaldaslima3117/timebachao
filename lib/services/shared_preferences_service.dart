// shared_prefs_service.dart
import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefsService {
  Future<String?> getMaidId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('maidId');
  }

  Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('roleType');
  }
}
