// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'playlist_source.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PlaylistTypeAdapter extends TypeAdapter<PlaylistType> {
  @override
  final int typeId = 0;

  @override
  PlaylistType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return PlaylistType.direct;
      case 1:
        return PlaylistType.xtreamCodes;
      default:
        return PlaylistType.direct;
    }
  }

  @override
  void write(BinaryWriter writer, PlaylistType obj) {
    switch (obj) {
      case PlaylistType.direct:
        writer.writeByte(0);
        break;
      case PlaylistType.xtreamCodes:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlaylistTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PlaylistSourceAdapter extends TypeAdapter<PlaylistSource> {
  @override
  final int typeId = 1;

  @override
  PlaylistSource read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PlaylistSource(
      name: fields[0] as String,
      url: fields[1] as String,
      username: fields[2] as String?,
      password: fields[3] as String?,
      type: fields[4] as PlaylistType,
      isActive: fields[5] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, PlaylistSource obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.url)
      ..writeByte(2)
      ..write(obj.username)
      ..writeByte(3)
      ..write(obj.password)
      ..writeByte(4)
      ..write(obj.type)
      ..writeByte(5)
      ..write(obj.isActive);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlaylistSourceAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
