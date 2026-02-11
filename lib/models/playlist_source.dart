import 'package:hive/hive.dart';

part 'playlist_source.g.dart';

@HiveType(typeId: 0)
enum PlaylistType {
  @HiveField(0)
  direct,
  @HiveField(1)
  xtreamCodes,
}

@HiveType(typeId: 1)
class PlaylistSource extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  String url;

  @HiveField(2)
  String? username;

  @HiveField(3)
  String? password;

  @HiveField(4)
  PlaylistType type;

  @HiveField(5)
  bool isActive;

  PlaylistSource({
    required this.name,
    required this.url,
    this.username,
    this.password,
    this.type = PlaylistType.direct,
    this.isActive = false,
  });

  String get effectiveUrl {
    if (type == PlaylistType.xtreamCodes &&
        username != null &&
        password != null) {
      final base = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
      return '$base/get.php?username=$username&password=$password&type=m3u_plus&output=ts';
    }
    return url;
  }
}
