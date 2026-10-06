import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Supported languages
enum AppLanguage {
  en('English', 'en'),
  ar('العربية', 'ar'),
  fr('Français', 'fr'),
  es('Español', 'es'),
  de('Deutsch', 'de'),
  pt('Português', 'pt'),
  tr('Türkçe', 'tr'),
  ru('Русский', 'ru'),
  zh('中文', 'zh'),
  hi('हिन्दी', 'hi'),
  ja('日本語', 'ja'),
  ko('한국어', 'ko'),
  it('Italiano', 'it'),
  nl('Nederlands', 'nl'),
  sv('Svenska', 'sv');

  final String displayName;
  final String code;
  const AppLanguage(this.displayName, this.code);
}

// Language provider
final appLanguageProvider = StateNotifierProvider<AppLanguageNotifier, AppLanguage>((ref) {
  return AppLanguageNotifier();
});

class AppLanguageNotifier extends StateNotifier<AppLanguage> {
  AppLanguageNotifier() : super(AppLanguage.en) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString('app_language') ?? 'en';
    state = AppLanguage.values.firstWhere((l) => l.code == code, orElse: () => AppLanguage.en);
  }

  Future<void> setLanguage(AppLanguage lang) async {
    state = lang;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_language', lang.code);
  }
}

// All translatable strings
class S {
  // App
  static String appTitle(AppLanguage l) => _t(l, {
    'en': 'IPTV Player', 'ar': 'مشغل IPTV', 'fr': 'Lecteur IPTV', 'es': 'Reproductor IPTV',
    'de': 'IPTV Player', 'pt': 'Reprodutor IPTV', 'tr': 'IPTV Oynatıcı', 'ru': 'IPTV Плеер',
    'zh': 'IPTV 播放器', 'hi': 'IPTV प्लेयर', 'ja': 'IPTVプレーヤー', 'ko': 'IPTV 플레이어',
    'it': 'Lettore IPTV', 'nl': 'IPTV Speler', 'sv': 'IPTV Spelare',
  });

  // Home
  static String noPlaylists(AppLanguage l) => _t(l, {
    'en': 'No playlists added yet', 'ar': 'لم تتم إضافة قوائم تشغيل بعد', 'fr': 'Aucune playlist ajoutée',
    'es': 'No se han añadido listas', 'de': 'Noch keine Playlisten hinzugefügt', 'pt': 'Nenhuma playlist adicionada',
    'tr': 'Henüz oynatma listesi eklenmedi', 'ru': 'Плейлисты не добавлены', 'zh': '尚未添加播放列表',
    'hi': 'अभी तक कोई प्लेलिस्ट नहीं', 'ja': 'プレイリストがありません', 'ko': '재생목록이 없습니다',
    'it': 'Nessuna playlist aggiunta', 'nl': 'Geen afspeellijsten', 'sv': 'Inga spellistor tillagda',
  });
  static String addPlaylistHint(AppLanguage l) => _t(l, {
    'en': 'Tap + to add your own M3U playlist URL\nor Xtream Codes server',
    'ar': 'اضغط + لإضافة رابط قائمة M3U\nأو خادم Xtream Codes',
    'fr': 'Appuyez sur + pour ajouter une URL M3U\nou un serveur Xtream Codes',
    'es': 'Pulse + para añadir una URL M3U\no servidor Xtream Codes',
    'de': 'Tippe + um eine M3U URL\noder Xtream Codes Server hinzuzufügen',
    'pt': 'Toque + para adicionar URL M3U\nou servidor Xtream Codes',
    'tr': 'M3U oynatma listesi URL\'si\nveya Xtream Codes sunucusu eklemek için + düğmesine dokunun',
    'ru': 'Нажмите + чтобы добавить M3U\nили сервер Xtream Codes',
    'zh': '点击 + 添加 M3U 播放列表\n或 Xtream Codes 服务器',
    'hi': 'M3U प्लेलिस्ट URL जोड़ने के लिए + दबाएं', 'ja': '+ をタップしてM3Uプレイリストを追加',
    'ko': '+ 을 탭하여 M3U 재생목록 추가', 'it': 'Tocca + per aggiungere URL M3U',
    'nl': 'Tik + om M3U playlist toe te voegen', 'sv': 'Tryck + för att lägga till M3U-spellista',
  });

  // Drawer
  static String playlists(AppLanguage l) => _t(l, {
    'en': 'Playlists', 'ar': 'قوائم التشغيل', 'fr': 'Playlists', 'es': 'Listas', 'de': 'Playlisten',
    'pt': 'Playlists', 'tr': 'Oynatma Listeleri', 'ru': 'Плейлисты', 'zh': '播放列表',
    'hi': 'प्लेलिस्ट', 'ja': 'プレイリスト', 'ko': '재생목록', 'it': 'Playlist', 'nl': 'Afspeellijsten', 'sv': 'Spellistor',
  });
  static String favorites(AppLanguage l) => _t(l, {
    'en': 'Favorites', 'ar': 'المفضلة', 'fr': 'Favoris', 'es': 'Favoritos', 'de': 'Favoriten',
    'pt': 'Favoritos', 'tr': 'Favoriler', 'ru': 'Избранное', 'zh': '收藏',
    'hi': 'पसंदीदा', 'ja': 'お気に入り', 'ko': '즐겨찾기', 'it': 'Preferiti', 'nl': 'Favorieten', 'sv': 'Favoriter',
  });
  static String downloads(AppLanguage l) => _t(l, {
    'en': 'Downloads', 'ar': 'التنزيلات', 'fr': 'Téléchargements', 'es': 'Descargas', 'de': 'Downloads',
    'pt': 'Downloads', 'tr': 'İndirilenler', 'ru': 'Загрузки', 'zh': '下载',
    'hi': 'डाउनलोड', 'ja': 'ダウンロード', 'ko': '다운로드', 'it': 'Download', 'nl': 'Downloads', 'sv': 'Nedladdningar',
  });
  static String recordings(AppLanguage l) => _t(l, {
    'en': 'Recordings', 'ar': 'التسجيلات', 'fr': 'Enregistrements', 'es': 'Grabaciones', 'de': 'Aufnahmen',
    'pt': 'Gravações', 'tr': 'Kayıtlar', 'ru': 'Записи', 'zh': '录制',
    'hi': 'रिकॉर्डिंग', 'ja': '録画', 'ko': '녹화', 'it': 'Registrazioni', 'nl': 'Opnames', 'sv': 'Inspelningar',
  });
  static String settings(AppLanguage l) => _t(l, {
    'en': 'Settings', 'ar': 'الإعدادات', 'fr': 'Paramètres', 'es': 'Ajustes', 'de': 'Einstellungen',
    'pt': 'Configurações', 'tr': 'Ayarlar', 'ru': 'Настройки', 'zh': '设置',
    'hi': 'सेटिंग्स', 'ja': '設定', 'ko': '설정', 'it': 'Impostazioni', 'nl': 'Instellingen', 'sv': 'Inställningar',
  });

  // Groups
  static String groups(AppLanguage l) => _t(l, {
    'en': 'Groups', 'ar': 'المجموعات', 'fr': 'Groupes', 'es': 'Grupos', 'de': 'Gruppen',
    'pt': 'Grupos', 'tr': 'Gruplar', 'ru': 'Группы', 'zh': '分组',
    'hi': 'समूह', 'ja': 'グループ', 'ko': '그룹', 'it': 'Gruppi', 'nl': 'Groepen', 'sv': 'Grupper',
  });
  static String allChannels(AppLanguage l) => _t(l, {
    'en': 'All Channels', 'ar': 'جميع القنوات', 'fr': 'Toutes les chaînes', 'es': 'Todos los canales',
    'de': 'Alle Kanäle', 'pt': 'Todos os canais', 'tr': 'Tüm Kanallar', 'ru': 'Все каналы', 'zh': '所有频道',
    'hi': 'सभी चैनल', 'ja': '全チャンネル', 'ko': '모든 채널', 'it': 'Tutti i canali', 'nl': 'Alle kanalen', 'sv': 'Alla kanaler',
  });
  static String channels(AppLanguage l) => _t(l, {
    'en': 'Channels', 'ar': 'القنوات', 'fr': 'Chaînes', 'es': 'Canales', 'de': 'Kanäle',
    'pt': 'Canais', 'tr': 'Kanallar', 'ru': 'Каналы', 'zh': '频道',
    'hi': 'चैनल', 'ja': 'チャンネル', 'ko': '채널', 'it': 'Canali', 'nl': 'Kanalen', 'sv': 'Kanaler',
  });
  static String searchChannels(AppLanguage l) => _t(l, {
    'en': 'Search channels...', 'ar': 'بحث القنوات...', 'fr': 'Rechercher...', 'es': 'Buscar canales...',
    'de': 'Kanäle suchen...', 'pt': 'Pesquisar canais...', 'tr': 'Kanal ara...', 'ru': 'Поиск каналов...',
    'zh': '搜索频道...', 'hi': 'चैनल खोजें...', 'ja': 'チャンネル検索...', 'ko': '채널 검색...',
    'it': 'Cerca canali...', 'nl': 'Kanalen zoeken...', 'sv': 'Sök kanaler...',
  });
  static String refresh(AppLanguage l) => _t(l, {
    'en': 'Refresh', 'ar': 'تحديث', 'fr': 'Actualiser', 'es': 'Actualizar',
    'de': 'Aktualisieren', 'pt': 'Atualizar', 'tr': 'Yenile', 'ru': 'Обновить',
    'zh': '刷新', 'hi': 'रीफ़्रेश करें', 'ja': '更新', 'ko': '새로고침',
    'it': 'Aggiorna', 'nl': 'Vernieuwen', 'sv': 'Uppdatera',
  });
  static String reloadingChannels(AppLanguage l) => _t(l, {
    'en': 'Clearing cache & reloading channels…', 'ar': 'مسح الذاكرة المؤقتة وإعادة تحميل القنوات…',
    'fr': 'Vidage du cache et rechargement…', 'es': 'Borrando caché y recargando canales…',
    'de': 'Cache leeren & Kanäle neu laden…', 'pt': 'Limpando cache e recarregando canais…',
    'tr': 'Önbellek temizleniyor ve kanallar yenileniyor…', 'ru': 'Очистка кэша и перезагрузка каналов…',
    'zh': '正在清除缓存并重新加载频道…', 'hi': 'कैश साफ़ करके चैनल पुनः लोड हो रहे हैं…',
    'ja': 'キャッシュを消去してチャンネルを再読み込み中…', 'ko': '캐시 지우고 채널 다시 불러오는 중…',
    'it': 'Cancellazione cache e ricarica canali…', 'nl': 'Cache wissen & kanalen herladen…',
    'sv': 'Rensar cache & laddar om kanaler…',
  });
  static String noChannelsFound(AppLanguage l) => _t(l, {
    'en': 'No channels found.', 'ar': 'لم يتم العثور على قنوات.', 'fr': 'Aucune chaîne trouvée.',
    'es': 'No se encontraron canales.', 'de': 'Keine Kanäle gefunden.', 'pt': 'Nenhum canal encontrado.',
    'tr': 'Kanal bulunamadı.', 'ru': 'Каналы не найдены.', 'zh': '未找到频道。',
    'hi': 'कोई चैनल नहीं मिला।', 'ja': 'チャンネルが見つかりません。', 'ko': '채널을 찾을 수 없습니다.',
    'it': 'Nessun canale trovato.', 'nl': 'Geen kanalen gevonden.', 'sv': 'Inga kanaler hittades.',
  });
  static String noFavorites(AppLanguage l) => _t(l, {
    'en': 'No favorite channels yet', 'ar': 'لا توجد قنوات مفضلة بعد', 'fr': 'Pas de favoris',
    'es': 'Sin canales favoritos', 'de': 'Noch keine Favoriten', 'pt': 'Sem favoritos',
    'tr': 'Henüz favori kanal yok', 'ru': 'Нет избранных каналов', 'zh': '暂无收藏频道',
    'hi': 'अभी कोई पसंदीदा चैनल नहीं', 'ja': 'お気に入りチャンネルなし', 'ko': '즐겨찾기 채널 없음',
    'it': 'Nessun canale preferito', 'nl': 'Geen favorieten', 'sv': 'Inga favoriter ännu',
  });
  static String longPressToFavorite(AppLanguage l) => _t(l, {
    'en': 'Long press on a channel to add it to favorites',
    'ar': 'اضغط مطولاً على قناة لإضافتها إلى المفضلة',
    'fr': 'Appuyez longuement pour ajouter aux favoris',
    'es': 'Mantén presionado para añadir a favoritos',
    'de': 'Lange drücken um zu Favoriten hinzuzufügen',
    'pt': 'Pressione e segure para adicionar aos favoritos',
    'tr': 'Favorilere eklemek için uzun basın',
    'ru': 'Нажмите и удерживайте для добавления в избранное',
    'zh': '长按频道添加到收藏',
    'hi': 'पसंदीदा में जोड़ने के लिए लॉन्ग प्रेस करें',
    'ja': '長押しでお気に入りに追加', 'ko': '길게 눌러 즐겨찾기에 추가',
    'it': 'Premi a lungo per aggiungere ai preferiti',
    'nl': 'Houd ingedrukt om toe te voegen aan favorieten',
    'sv': 'Håll intryckt för att lägga till i favoriter',
  });

  // Add Playlist
  static String addPlaylist(AppLanguage l) => _t(l, {
    'en': 'Add Playlist', 'ar': 'إضافة قائمة', 'fr': 'Ajouter playlist', 'es': 'Añadir lista',
    'de': 'Playlist hinzufügen', 'pt': 'Adicionar playlist', 'tr': 'Oynatma Listesi Ekle',
    'ru': 'Добавить плейлист', 'zh': '添加播放列表', 'hi': 'प्लेलिस्ट जोड़ें',
    'ja': 'プレイリスト追加', 'ko': '재생목록 추가', 'it': 'Aggiungi playlist',
    'nl': 'Afspeellijst toevoegen', 'sv': 'Lägg till spellista',
  });
  static String name(AppLanguage l) => _t(l, {
    'en': 'Name', 'ar': 'الاسم', 'fr': 'Nom', 'es': 'Nombre', 'de': 'Name',
    'pt': 'Nome', 'tr': 'Ad', 'ru': 'Имя', 'zh': '名称', 'hi': 'नाम',
    'ja': '名前', 'ko': '이름', 'it': 'Nome', 'nl': 'Naam', 'sv': 'Namn',
  });
  static String testConnection(AppLanguage l) => _t(l, {
    'en': 'Test Connection', 'ar': 'اختبار الاتصال', 'fr': 'Tester la connexion', 'es': 'Probar conexión',
    'de': 'Verbindung testen', 'pt': 'Testar conexão', 'tr': 'Bağlantıyı Test Et',
    'ru': 'Тест соединения', 'zh': '测试连接', 'hi': 'कनेक्शन टेस्ट',
    'ja': '接続テスト', 'ko': '연결 테스트', 'it': 'Test connessione',
    'nl': 'Verbinding testen', 'sv': 'Testa anslutning',
  });
  static String cancel(AppLanguage l) => _t(l, {
    'en': 'Cancel', 'ar': 'إلغاء', 'fr': 'Annuler', 'es': 'Cancelar', 'de': 'Abbrechen',
    'pt': 'Cancelar', 'tr': 'İptal', 'ru': 'Отмена', 'zh': '取消', 'hi': 'रद्द करें',
    'ja': 'キャンセル', 'ko': '취소', 'it': 'Annulla', 'nl': 'Annuleren', 'sv': 'Avbryt',
  });
  static String add(AppLanguage l) => _t(l, {
    'en': 'Add', 'ar': 'إضافة', 'fr': 'Ajouter', 'es': 'Añadir', 'de': 'Hinzufügen',
    'pt': 'Adicionar', 'tr': 'Ekle', 'ru': 'Добавить', 'zh': '添加', 'hi': 'जोड़ें',
    'ja': '追加', 'ko': '추가', 'it': 'Aggiungi', 'nl': 'Toevoegen', 'sv': 'Lägg till',
  });
  static String active(AppLanguage l) => _t(l, {
    'en': 'Active', 'ar': 'نشط', 'fr': 'Actif', 'es': 'Activo', 'de': 'Aktiv',
    'pt': 'Ativo', 'tr': 'Aktif', 'ru': 'Активный', 'zh': '活跃', 'hi': 'सक्रिय',
    'ja': 'アクティブ', 'ko': '활성', 'it': 'Attivo', 'nl': 'Actief', 'sv': 'Aktiv',
  });
  static String setActive(AppLanguage l) => _t(l, {
    'en': 'Set Active', 'ar': 'تعيين كنشط', 'fr': 'Activer', 'es': 'Activar', 'de': 'Aktivieren',
    'pt': 'Ativar', 'tr': 'Aktif Yap', 'ru': 'Активировать', 'zh': '设为活跃',
    'hi': 'सक्रिय करें', 'ja': 'アクティブに設定', 'ko': '활성화',
    'it': 'Attiva', 'nl': 'Activeren', 'sv': 'Aktivera',
  });
  static String delete(AppLanguage l) => _t(l, {
    'en': 'Delete', 'ar': 'حذف', 'fr': 'Supprimer', 'es': 'Eliminar', 'de': 'Löschen',
    'pt': 'Excluir', 'tr': 'Sil', 'ru': 'Удалить', 'zh': '删除', 'hi': 'हटाएं',
    'ja': '削除', 'ko': '삭제', 'it': 'Elimina', 'nl': 'Verwijderen', 'sv': 'Radera',
  });

  // Settings
  static String playback(AppLanguage l) => _t(l, {
    'en': 'PLAYBACK', 'ar': 'التشغيل', 'fr': 'LECTURE', 'es': 'REPRODUCCIÓN', 'de': 'WIEDERGABE',
    'pt': 'REPRODUÇÃO', 'tr': 'OYNATMA', 'ru': 'ВОСПРОИЗВЕДЕНИЕ', 'zh': '播放',
    'hi': 'प्लेबैक', 'ja': '再生', 'ko': '재생', 'it': 'RIPRODUZIONE', 'nl': 'AFSPELEN', 'sv': 'UPPSPELNING',
  });
  static String recentChannels(AppLanguage l) => _t(l, {
    'en': 'Remember Recent Channels', 'ar': 'تذكر القنوات الأخيرة', 'fr': 'Mémoriser les chaînes récentes',
    'es': 'Recordar canales recientes', 'de': 'Letzte Kanäle merken', 'pt': 'Lembrar canais recentes',
    'tr': 'Son Kanalları Hatırla', 'ru': 'Запоминать недавние каналы', 'zh': '记住最近频道',
    'hi': 'हाल के चैनल याद रखें', 'ja': '最近のチャンネルを記憶', 'ko': '최근 채널 기억',
    'it': 'Ricorda canali recenti', 'nl': 'Recente kanalen onthouden', 'sv': 'Kom ihåg senaste kanaler',
  });
  static String clearHistory(AppLanguage l) => _t(l, {
    'en': 'Clear Watch History', 'ar': 'مسح سجل المشاهدة', 'fr': 'Effacer l\'historique',
    'es': 'Borrar historial', 'de': 'Verlauf löschen', 'pt': 'Limpar histórico',
    'tr': 'İzleme Geçmişini Temizle', 'ru': 'Очистить историю', 'zh': '清除观看历史',
    'hi': 'देखने का इतिहास साफ़ करें', 'ja': '視聴履歴を消去', 'ko': '시청 기록 삭제',
    'it': 'Cancella cronologia', 'nl': 'Kijkgeschiedenis wissen', 'sv': 'Rensa tittarhistorik',
  });
  static String aspectRatio(AppLanguage l) => _t(l, {
    'en': 'Default Aspect Ratio', 'ar': 'نسبة العرض الافتراضية', 'fr': 'Ratio par défaut',
    'es': 'Relación de aspecto', 'de': 'Standard-Seitenverhältnis', 'pt': 'Proporção padrão',
    'tr': 'Varsayılan En-Boy Oranı', 'ru': 'Соотношение сторон', 'zh': '默认宽高比',
    'hi': 'डिफ़ॉल्ट पहलू अनुपात', 'ja': 'デフォルトアスペクト比', 'ko': '기본 화면 비율',
    'it': 'Rapporto aspetto', 'nl': 'Standaard beeldverhouding', 'sv': 'Standard bildförhållande',
  });
  static String generalSettings(AppLanguage l) => _t(l, {
    'en': 'GENERAL SETTINGS', 'ar': 'الإعدادات العامة', 'fr': 'PARAMÈTRES GÉNÉRAUX', 'es': 'AJUSTES GENERALES',
    'de': 'ALLGEMEINE EINSTELLUNGEN', 'pt': 'CONFIGURAÇÕES GERAIS', 'tr': 'GENEL AYARLAR', 'ru': 'ОБЩИЕ НАСТРОЙКИ', 'zh': '常规设置',
    'hi': 'सामान्य सेटिंग्स', 'ja': '一般設定', 'ko': '일반 설정', 'it': 'IMPOSTAZIONI GENERALI', 'nl': 'ALGEMENE INSTELLINGEN', 'sv': 'ALLMÄNNA INSTÄLLNINGAR',
  });
  static String playerSettings(AppLanguage l) => _t(l, {
    'en': 'PLAYER SETTINGS', 'ar': 'إعدادات المشغل', 'fr': 'PARAMÈTRES DU LECTEUR', 'es': 'AJUSTES DEL REPRODUCTOR',
    'de': 'PLAYER-EINSTELLUNGEN', 'pt': 'CONFIGURAÇÕES DO PLAYER', 'tr': 'OYNATICI AYARLARI', 'ru': 'НАСТРОЙКИ ПЛЕЕРА', 'zh': '播放器设置',
    'hi': 'प्लेयर सेटिंग्स', 'ja': 'プレーヤー設定', 'ko': '플레이어 설정', 'it': 'IMPOSTAZIONI PLAYER', 'nl': 'SPELERINSTELLINGEN', 'sv': 'SPELARINSTÄLLNINGAR',
  });
  static String cacheSection(AppLanguage l) => _t(l, {
    'en': 'CACHE', 'ar': 'ذاكرة التخزين المؤقت', 'fr': 'CACHE', 'es': 'CACHÉ', 'de': 'CACHE', 'pt': 'CACHE', 'tr': 'ÖNBELLEK',
    'ru': 'КЭШ', 'zh': '缓存', 'hi': 'कैश', 'ja': 'キャッシュ', 'ko': '캐시', 'it': 'CACHE', 'nl': 'CACHE', 'sv': 'CACHE',
  });
  static String more(AppLanguage l) => _t(l, {
    'en': 'MORE', 'ar': 'المزيد', 'fr': 'PLUS', 'es': 'MÁS', 'de': 'MEHR', 'pt': 'MAIS', 'tr': 'DAHA FAZLA', 'ru': 'ЕЩЁ',
    'zh': '更多', 'hi': 'अधिक', 'ja': 'その他', 'ko': '더 보기', 'it': 'ALTRO', 'nl': 'MEER', 'sv': 'MER',
  });
  static String organizeByGroups(AppLanguage l) => _t(l, {
    'en': 'Organize by Groups', 'ar': 'التنظيم حسب المجموعات', 'fr': 'Organiser par groupes', 'es': 'Organizar por grupos',
    'de': 'Nach Gruppen ordnen', 'pt': 'Organizar por grupos', 'tr': 'Gruplara göre düzenle', 'ru': 'Группировать', 'zh': '按分组整理',
    'hi': 'समूहों द्वारा व्यवस्थित करें', 'ja': 'グループで整理', 'ko': '그룹별 정리', 'it': 'Organizza per gruppi', 'nl': 'Ordenen op groepen', 'sv': 'Ordna efter grupper',
  });
  static String clearRecentData(AppLanguage l) => _t(l, {
    'en': 'Clear Recent Data', 'ar': 'مسح البيانات الأخيرة', 'fr': 'Effacer les données récentes', 'es': 'Borrar datos recientes',
    'de': 'Letzte Daten löschen', 'pt': 'Limpar dados recentes', 'tr': 'Son verileri temizle', 'ru': 'Очистить недавние', 'zh': '清除最近数据',
    'hi': 'हाल का डेटा साफ़ करें', 'ja': '最近のデータを消去', 'ko': '최근 데이터 삭제', 'it': 'Cancella dati recenti', 'nl': 'Recente gegevens wissen', 'sv': 'Rensa senaste data',
  });
  static String epgSettings(AppLanguage l) => _t(l, {
    'en': 'EPG Settings', 'ar': 'إعدادات دليل البرامج', 'fr': 'Paramètres EPG', 'es': 'Ajustes de EPG', 'de': 'EPG-Einstellungen',
    'pt': 'Configurações de EPG', 'tr': 'EPG Ayarları', 'ru': 'Настройки EPG', 'zh': '节目指南设置', 'hi': 'EPG सेटिंग्स',
    'ja': 'EPG設定', 'ko': 'EPG 설정', 'it': 'Impostazioni EPG', 'nl': 'EPG-instellingen', 'sv': 'EPG-inställningar',
  });
  static String clearEpgCache(AppLanguage l) => _t(l, {
    'en': 'Clear EPG cache', 'ar': 'مسح ذاكرة دليل البرامج', 'fr': 'Vider le cache EPG', 'es': 'Borrar caché de EPG',
    'de': 'EPG-Cache leeren', 'pt': 'Limpar cache de EPG', 'tr': 'EPG önbelleğini temizle', 'ru': 'Очистить кэш EPG', 'zh': '清除节目指南缓存',
    'hi': 'EPG कैश साफ़ करें', 'ja': 'EPGキャッシュを消去', 'ko': 'EPG 캐시 삭제', 'it': 'Svuota cache EPG', 'nl': 'EPG-cache wissen', 'sv': 'Rensa EPG-cache',
  });
  static String customerSupport(AppLanguage l) => _t(l, {
    'en': 'Customer support', 'ar': 'دعم العملاء', 'fr': 'Assistance', 'es': 'Atención al cliente', 'de': 'Kundensupport',
    'pt': 'Suporte ao cliente', 'tr': 'Müşteri desteği', 'ru': 'Поддержка', 'zh': '客户支持', 'hi': 'ग्राहक सहायता',
    'ja': 'カスタマーサポート', 'ko': '고객 지원', 'it': 'Assistenza clienti', 'nl': 'Klantenservice', 'sv': 'Kundsupport',
  });
  static String channelList(AppLanguage l) => _t(l, {
    'en': 'CHANNEL LIST', 'ar': 'قائمة القنوات', 'fr': 'LISTE DES CHAÎNES', 'es': 'LISTA DE CANALES',
    'de': 'KANALLISTE', 'pt': 'LISTA DE CANAIS', 'tr': 'KANAL LİSTESİ', 'ru': 'СПИСОК КАНАЛОВ', 'zh': '频道列表',
    'hi': 'चैनल सूची', 'ja': 'チャンネルリスト', 'ko': '채널 목록', 'it': 'ELENCO CANALI', 'nl': 'KANALENLIJST', 'sv': 'KANALLISTA',
  });
  static String groupByCategories(AppLanguage l) => _t(l, {
    'en': 'Group by Categories', 'ar': 'تجميع حسب الفئات', 'fr': 'Grouper par catégories',
    'es': 'Agrupar por categorías', 'de': 'Nach Kategorien gruppieren', 'pt': 'Agrupar por categorias',
    'tr': 'Kategorilere Göre Grupla', 'ru': 'Группировать по категориям', 'zh': '按分类分组',
    'hi': 'श्रेणियों के अनुसार समूह', 'ja': 'カテゴリでグループ化', 'ko': '카테고리별 그룹화',
    'it': 'Raggruppa per categorie', 'nl': 'Groeperen op categorie', 'sv': 'Gruppera efter kategori',
  });
  static String appLanguage(AppLanguage l) => _t(l, {
    'en': 'App Language', 'ar': 'لغة التطبيق', 'fr': 'Langue', 'es': 'Idioma', 'de': 'Sprache',
    'pt': 'Idioma', 'tr': 'Uygulama Dili', 'ru': 'Язык приложения', 'zh': '应用语言',
    'hi': 'ऐप भाषा', 'ja': 'アプリの言語', 'ko': '앱 언어', 'it': 'Lingua', 'nl': 'Taal', 'sv': 'Appspråk',
  });
  static String security(AppLanguage l) => _t(l, {
    'en': 'SECURITY', 'ar': 'الأمان', 'fr': 'SÉCURITÉ', 'es': 'SEGURIDAD', 'de': 'SICHERHEIT',
    'pt': 'SEGURANÇA', 'tr': 'GÜVENLİK', 'ru': 'БЕЗОПАСНОСТЬ', 'zh': '安全',
    'hi': 'सुरक्षा', 'ja': 'セキュリティ', 'ko': '보안', 'it': 'SICUREZZA', 'nl': 'BEVEILIGING', 'sv': 'SÄKERHET',
  });
  static String parentalControl(AppLanguage l) => _t(l, {
    'en': 'Parental Control', 'ar': 'الرقابة الأبوية', 'fr': 'Contrôle parental', 'es': 'Control parental',
    'de': 'Kindersicherung', 'pt': 'Controle parental', 'tr': 'Ebeveyn Kontrolü',
    'ru': 'Родительский контроль', 'zh': '家长控制', 'hi': 'पैरेंटल कंट्रोल',
    'ja': 'ペアレンタルコントロール', 'ko': '보호자 설정', 'it': 'Controllo genitori',
    'nl': 'Ouderlijk toezicht', 'sv': 'Föräldrakontroll',
  });
  static String storage(AppLanguage l) => _t(l, {
    'en': 'STORAGE', 'ar': 'التخزين', 'fr': 'STOCKAGE', 'es': 'ALMACENAMIENTO', 'de': 'SPEICHER',
    'pt': 'ARMAZENAMENTO', 'tr': 'DEPOLAMA', 'ru': 'ХРАНИЛИЩЕ', 'zh': '存储',
    'hi': 'भंडारण', 'ja': 'ストレージ', 'ko': '저장소', 'it': 'ARCHIVIAZIONE', 'nl': 'OPSLAG', 'sv': 'LAGRING',
  });
  static String clearPlaylistsCache(AppLanguage l) => _t(l, {
    'en': 'Clear Playlists Cache', 'ar': 'مسح ذاكرة القوائم', 'fr': 'Vider le cache des playlists',
    'es': 'Borrar caché de listas', 'de': 'Playlist-Cache löschen', 'pt': 'Limpar cache de playlists',
    'tr': 'Oynatma Listesi Önbelleğini Temizle', 'ru': 'Очистить кэш плейлистов', 'zh': '清除播放列表缓存',
    'hi': 'प्लेलिस्ट कैश साफ़ करें', 'ja': 'プレイリストキャッシュを消去', 'ko': '재생목록 캐시 삭제',
    'it': 'Svuota cache playlist', 'nl': 'Playlist cache wissen', 'sv': 'Rensa spellistcache',
  });
  static String clearImagesCache(AppLanguage l) => _t(l, {
    'en': 'Clear Images Cache', 'ar': 'مسح ذاكرة الصور', 'fr': 'Vider le cache des images',
    'es': 'Borrar caché de imágenes', 'de': 'Bilder-Cache löschen', 'pt': 'Limpar cache de imagens',
    'tr': 'Görsel Önbelleğini Temizle', 'ru': 'Очистить кэш изображений', 'zh': '清除图片缓存',
    'hi': 'इमेज कैश साफ़ करें', 'ja': '画像キャッシュを消去', 'ko': '이미지 캐시 삭제',
    'it': 'Svuota cache immagini', 'nl': 'Afbeeldingscache wissen', 'sv': 'Rensa bildcache',
  });
  static String about(AppLanguage l) => _t(l, {
    'en': 'ABOUT', 'ar': 'حول', 'fr': 'À PROPOS', 'es': 'ACERCA DE', 'de': 'ÜBER',
    'pt': 'SOBRE', 'tr': 'HAKKINDA', 'ru': 'О ПРИЛОЖЕНИИ', 'zh': '关于',
    'hi': 'के बारे में', 'ja': 'アプリについて', 'ko': '정보', 'it': 'INFORMAZIONI', 'nl': 'OVER', 'sv': 'OM',
  });
  static String termsOfUse(AppLanguage l) => _t(l, {
    'en': 'Terms of Use', 'ar': 'شروط الاستخدام', 'fr': 'Conditions d\'utilisation', 'es': 'Términos de uso',
    'de': 'Nutzungsbedingungen', 'pt': 'Termos de uso', 'tr': 'Kullanım Şartları',
    'ru': 'Условия использования', 'zh': '使用条款', 'hi': 'उपयोग की शर्तें',
    'ja': '利用規約', 'ko': '이용약관', 'it': 'Termini di utilizzo', 'nl': 'Gebruiksvoorwaarden', 'sv': 'Användarvillkor',
  });
  static String privacyPolicy(AppLanguage l) => _t(l, {
    'en': 'Privacy Policy', 'ar': 'سياسة الخصوصية', 'fr': 'Politique de confidentialité',
    'es': 'Política de privacidad', 'de': 'Datenschutzrichtlinie', 'pt': 'Política de privacidade',
    'tr': 'Gizlilik Politikası', 'ru': 'Политика конфиденциальности', 'zh': '隐私政策',
    'hi': 'गोपनीयता नीति', 'ja': 'プライバシーポリシー', 'ko': '개인정보 처리방침',
    'it': 'Informativa privacy', 'nl': 'Privacybeleid', 'sv': 'Integritetspolicy',
  });
  static String comingSoon(AppLanguage l) => _t(l, {
    'en': 'Coming soon', 'ar': 'قريباً', 'fr': 'Bientôt disponible', 'es': 'Próximamente',
    'de': 'Kommt bald', 'pt': 'Em breve', 'tr': 'Yakında', 'ru': 'Скоро',
    'zh': '即将推出', 'hi': 'जल्द आ रहा है', 'ja': '近日公開', 'ko': '곧 출시',
    'it': 'In arrivo', 'nl': 'Binnenkort', 'sv': 'Kommer snart',
  });
  static String loadingChannels(AppLanguage l) => _t(l, {
    'en': 'Loading channels...', 'ar': 'جاري تحميل القنوات...', 'fr': 'Chargement des chaînes...',
    'es': 'Cargando canales...', 'de': 'Kanäle laden...', 'pt': 'Carregando canais...',
    'tr': 'Kanallar yükleniyor...', 'ru': 'Загрузка каналов...', 'zh': '正在加载频道...',
    'hi': 'चैनल लोड हो रहे हैं...', 'ja': 'チャンネルを読み込み中...', 'ko': '채널 로딩 중...',
    'it': 'Caricamento canali...', 'nl': 'Kanalen laden...', 'sv': 'Laddar kanaler...',
  });
  static String addedToFavorites(AppLanguage l, String ch) => _t(l, {
    'en': '$ch added to favorites', 'ar': 'تمت إضافة $ch إلى المفضلة', 'fr': '$ch ajouté aux favoris',
    'es': '$ch añadido a favoritos', 'de': '$ch zu Favoriten hinzugefügt', 'pt': '$ch adicionado aos favoritos',
    'tr': '$ch favorilere eklendi', 'ru': '$ch добавлен в избранное', 'zh': '$ch 已添加到收藏',
    'hi': '$ch पसंदीदा में जोड़ा गया', 'ja': '$ch をお気に入りに追加', 'ko': '$ch 즐겨찾기에 추가됨',
    'it': '$ch aggiunto ai preferiti', 'nl': '$ch toegevoegd aan favorieten', 'sv': '$ch tillagd i favoriter',
  });
  static String removedFromFavorites(AppLanguage l, String ch) => _t(l, {
    'en': '$ch removed from favorites', 'ar': 'تمت إزالة $ch من المفضلة', 'fr': '$ch retiré des favoris',
    'es': '$ch eliminado de favoritos', 'de': '$ch aus Favoriten entfernt', 'pt': '$ch removido dos favoritos',
    'tr': '$ch favorilerden çıkarıldı', 'ru': '$ch удалён из избранного', 'zh': '$ch 已从收藏中移除',
    'hi': '$ch पसंदीदा से हटाया गया', 'ja': '$ch をお気に入りから削除', 'ko': '$ch 즐겨찾기에서 제거됨',
    'it': '$ch rimosso dai preferiti', 'nl': '$ch verwijderd uit favorieten', 'sv': '$ch borttagen från favoriter',
  });

  // Helper
  static String _t(AppLanguage l, Map<String, String> map) {
    return map[l.code] ?? map['en'] ?? '';
  }
}
