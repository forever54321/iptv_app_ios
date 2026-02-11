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
}
