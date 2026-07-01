import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/playlist_source.dart';

/// Persists playlists in a Hive box encrypted with AES. The 32-byte key is
/// generated once and kept in the platform secure store (iOS/macOS Keychain)
/// via `flutter_secure_storage`. If secure storage is unavailable the service
/// degrades to the original unencrypted box so the app never fails to start.
class StorageService {
  static const _legacyBoxName = 'playlists';
  static const _boxName = 'playlists_secure';
  static const _keyStorageKey = 'hive_encryption_key';
  static const _migrationFlag = 'hive_encrypted_migration_done';

  static late Box<PlaylistSource> _boxInstance;

  static Future<Box<PlaylistSource>> get _box async => _boxInstance;

  static Future<void> init() async {
    Hive.registerAdapter(PlaylistTypeAdapter());
    Hive.registerAdapter(PlaylistSourceAdapter());

    final key = await _getEncryptionKey();
    if (key == null) {
      // Secure storage unavailable — keep working with the unencrypted box.
      _boxInstance = await Hive.openBox<PlaylistSource>(_legacyBoxName);
      return;
    }

    final cipher = HiveAesCipher(key);
    final prefs = await SharedPreferences.getInstance();
    final migrationDone = prefs.getBool(_migrationFlag) ?? false;

    if (!migrationDone && await Hive.boxExists(_legacyBoxName)) {
      try {
        final oldBox = await Hive.openBox<PlaylistSource>(_legacyBoxName);
        final items = oldBox.values
            .map((e) => PlaylistSource(
                  name: e.name,
                  url: e.url,
                  username: e.username,
                  password: e.password,
                  type: e.type,
                  isActive: e.isActive,
                ))
            .toList();
        await oldBox.close();

        final newBox = await Hive.openBox<PlaylistSource>(
          _boxName,
          encryptionCipher: cipher,
        );
        await newBox.clear(); // idempotent if a prior migration was interrupted
        for (final item in items) {
          await newBox.add(item);
        }
        _boxInstance = newBox;

        // Only drop the legacy box once the encrypted copy is committed.
        await prefs.setBool(_migrationFlag, true);
        await Hive.deleteBoxFromDisk(_legacyBoxName);
        return;
      } catch (_) {
        // Migration failed — legacy box is untouched; fall through and retry
        // on the next launch.
      }
    }

    _boxInstance = await Hive.openBox<PlaylistSource>(
      _boxName,
      encryptionCipher: cipher,
    );
  }

  static Future<List<int>?> _getEncryptionKey() async {
    try {
      const storage = FlutterSecureStorage(
        aOptions: AndroidOptions(encryptedSharedPreferences: true),
      );
      final existing = await storage.read(key: _keyStorageKey);
      if (existing != null && existing.isNotEmpty) {
        return base64Decode(existing);
      }
      final key = Hive.generateSecureKey();
      await storage.write(key: _keyStorageKey, value: base64Encode(key));
      return key;
    } catch (_) {
      return null;
    }
  }

  static Future<List<PlaylistSource>> getAll() async {
    final box = await _box;
    return box.values.toList();
  }

  static Future<void> add(PlaylistSource source) async {
    final box = await _box;
    await box.add(source);
  }

  static Future<void> update(PlaylistSource source) async {
    await source.save();
  }

  static Future<void> delete(PlaylistSource source) async {
    await source.delete();
  }

  static Future<void> setActive(PlaylistSource source) async {
    final box = await _box;
    for (final item in box.values) {
      if (item.isActive) {
        item.isActive = false;
        await item.save();
      }
    }
    source.isActive = true;
    await source.save();
  }

  static Future<PlaylistSource?> getActive() async {
    final box = await _box;
    try {
      return box.values.firstWhere((s) => s.isActive);
    } catch (_) {
      return null;
    }
  }
}
