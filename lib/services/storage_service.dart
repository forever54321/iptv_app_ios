import 'package:hive/hive.dart';
import '../models/playlist_source.dart';

class StorageService {
  static const _boxName = 'playlists';

  static Future<Box<PlaylistSource>> get _box async =>
      Hive.box<PlaylistSource>(_boxName);

  static Future<void> init() async {
    Hive.registerAdapter(PlaylistTypeAdapter());
    Hive.registerAdapter(PlaylistSourceAdapter());
    await Hive.openBox<PlaylistSource>(_boxName);
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
