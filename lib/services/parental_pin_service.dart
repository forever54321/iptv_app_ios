import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Stores the parental-control PIN as a salted SHA-256 hash rather than
/// plaintext. A legacy plaintext PIN (key `parental_pin`) is migrated to a
/// hash on first access and the plaintext value is removed.
class ParentalPinService {
  static const _hashKey = 'parental_pin_hash';
  static const _saltKey = 'parental_pin_salt';
  static const _legacyKey = 'parental_pin';

  static String _hash(String pin, String salt) =>
      sha256.convert(utf8.encode('$salt:$pin')).toString();

  static String _newSalt() {
    final r = Random.secure();
    return base64Url.encode(List<int>.generate(16, (_) => r.nextInt(256)));
  }

  /// Returns true if a PIN is configured. Migrates a legacy plaintext PIN.
  static Future<bool> hasPin() async {
    final prefs = await SharedPreferences.getInstance();
    final legacy = prefs.getString(_legacyKey);
    if (legacy != null && legacy.isNotEmpty) {
      await setPin(legacy); // re-store as salted hash, clears legacy key
    }
    final hash = prefs.getString(_hashKey);
    return hash != null && hash.isNotEmpty;
  }

  static Future<void> setPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final salt = _newSalt();
    await prefs.setString(_saltKey, salt);
    await prefs.setString(_hashKey, _hash(pin, salt));
    await prefs.remove(_legacyKey);
  }

  static Future<bool> verifyPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final salt = prefs.getString(_saltKey);
    final hash = prefs.getString(_hashKey);
    if (salt == null || hash == null) return false;
    return _hash(pin, salt) == hash;
  }

  static Future<void> removePin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_hashKey);
    await prefs.remove(_saltKey);
    await prefs.remove(_legacyKey);
  }
}
