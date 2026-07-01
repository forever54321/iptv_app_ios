class M3uEntry {
  final String title;
  final String url;
  final String? groupTitle;
  final String? tvgName;
  final String? tvgLogo;
  final String? tvgId;
  final String? tvgLanguage;
  final int duration;

  const M3uEntry({
    required this.title,
    required this.url,
    this.groupTitle,
    this.tvgName,
    this.tvgLogo,
    this.tvgId,
    this.tvgLanguage,
    this.duration = -1,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'url': url,
        'groupTitle': groupTitle,
        'tvgName': tvgName,
        'tvgLogo': tvgLogo,
        'tvgId': tvgId,
        'tvgLanguage': tvgLanguage,
        'duration': duration,
      };

  factory M3uEntry.fromJson(Map<String, dynamic> json) => M3uEntry(
        title: json['title'] as String,
        url: json['url'] as String,
        groupTitle: json['groupTitle'] as String?,
        tvgName: json['tvgName'] as String?,
        tvgLogo: json['tvgLogo'] as String?,
        tvgId: json['tvgId'] as String?,
        tvgLanguage: json['tvgLanguage'] as String?,
        duration: json['duration'] as int? ?? -1,
      );
}
