enum CategoryType { group, language }

class ChannelCategory {
  final String name;
  final CategoryType type;
  final int channelCount;

  const ChannelCategory({
    required this.name,
    required this.type,
    this.channelCount = 0,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChannelCategory &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          type == other.type;

  @override
  int get hashCode => name.hashCode ^ type.hashCode;
}
