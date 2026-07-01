class EpgProgram {
  final String channelId;
  final DateTime start;
  final DateTime stop;
  final String title;
  final String? description;
  final String? category;

  const EpgProgram({
    required this.channelId,
    required this.start,
    required this.stop,
    required this.title,
    this.description,
    this.category,
  });

  bool get isNowPlaying {
    final now = DateTime.now();
    return now.isAfter(start) && now.isBefore(stop);
  }

  double get progress {
    final now = DateTime.now();
    if (now.isBefore(start)) return 0.0;
    if (now.isAfter(stop)) return 1.0;
    final total = stop.difference(start).inSeconds;
    if (total <= 0) return 0.0;
    final elapsed = now.difference(start).inSeconds;
    return elapsed / total;
  }

  String get timeRange {
    return '${_formatTime(start)} - ${_formatTime(stop)}';
  }

  static String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Map<String, dynamic> toJson() => {
        'channelId': channelId,
        'start': start.toIso8601String(),
        'stop': stop.toIso8601String(),
        'title': title,
        'description': description,
        'category': category,
      };

  factory EpgProgram.fromJson(Map<String, dynamic> json) => EpgProgram(
        channelId: json['channelId'] as String,
        start: DateTime.parse(json['start'] as String),
        stop: DateTime.parse(json['stop'] as String),
        title: json['title'] as String,
        description: json['description'] as String?,
        category: json['category'] as String?,
      );
}
