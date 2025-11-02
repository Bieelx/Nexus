import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class LocalUserId {
  static Future<String> getId() async {
    final prefs = await SharedPreferences.getInstance();
    String? id = prefs.getString('local_user_id');
    if (id == null) {
      id = const Uuid().v4();
      await prefs.setString('local_user_id', id);
    }
    return id;
  }
}