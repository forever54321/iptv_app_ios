' Localization — 15 languages matching the iOS/tvOS app
' Usage: GetString("appTitle") uses the global appLanguage

function GetString(key as String) as String
    lang = "en"
    if m.global <> invalid and m.global.appLanguage <> invalid
        lang = m.global.appLanguage
    end if

    strings = GetAllStrings()
    if strings[key] <> invalid
        if strings[key][lang] <> invalid
            return strings[key][lang]
        end if
        if strings[key]["en"] <> invalid
            return strings[key]["en"]
        end if
    end if

    return key
end function

function GetAllStrings() as Object
    if m._strings <> invalid then return m._strings

    s = {}

    s["appTitle"] = { en: "IPTV Stream Player", ar: "مشغل IPTV", fr: "Lecteur IPTV", es: "Reproductor IPTV", de: "IPTV Player", pt: "Reprodutor IPTV", tr: "IPTV Oynatıcı", ru: "IPTV Плеер", zh: "IPTV 播放器", hi: "IPTV प्लेयर", ja: "IPTVプレーヤー", ko: "IPTV 플레이어", it: "Lettore IPTV", nl: "IPTV Speler", sv: "IPTV Spelare" }
    s["noPlaylists"] = { en: "No playlists added yet", ar: "لم تتم إضافة قوائم تشغيل بعد", fr: "Aucune playlist ajoutée", es: "No se han añadido listas", de: "Noch keine Playlisten hinzugefügt", pt: "Nenhuma playlist adicionada", tr: "Henüz oynatma listesi eklenmedi", ru: "Плейлисты не добавлены", zh: "尚未添加播放列表", hi: "अभी तक कोई प्लेलिस्ट नहीं", ja: "プレイリストがありません", ko: "재생목록이 없습니다", it: "Nessuna playlist aggiunta", nl: "Geen afspeellijsten", sv: "Inga spellistor tillagda" }
    s["addPlaylist"] = { en: "Add Playlist", ar: "إضافة قائمة", fr: "Ajouter playlist", es: "Añadir lista", de: "Playlist hinzufügen", pt: "Adicionar playlist", tr: "Oynatma Listesi Ekle", ru: "Добавить плейлист", zh: "添加播放列表", hi: "प्लेलिस्ट जोड़ें", ja: "プレイリスト追加", ko: "재생목록 추가", it: "Aggiungi playlist", nl: "Afspeellijst toevoegen", sv: "Lägg till spellista" }
    s["groups"] = { en: "Groups", ar: "المجموعات", fr: "Groupes", es: "Grupos", de: "Gruppen", pt: "Grupos", tr: "Gruplar", ru: "Группы", zh: "分组", hi: "समूह", ja: "グループ", ko: "그룹", it: "Gruppi", nl: "Groepen", sv: "Grupper" }
    s["allChannels"] = { en: "All Channels", ar: "جميع القنوات", fr: "Toutes les chaînes", es: "Todos los canales", de: "Alle Kanäle", pt: "Todos os canais", tr: "Tüm Kanallar", ru: "Все каналы", zh: "所有频道", hi: "सभी चैनल", ja: "全チャンネル", ko: "모든 채널", it: "Tutti i canali", nl: "Alle kanalen", sv: "Alla kanaler" }
    s["channels"] = { en: "Channels", ar: "القنوات", fr: "Chaînes", es: "Canales", de: "Kanäle", pt: "Canais", tr: "Kanallar", ru: "Каналы", zh: "频道", hi: "चैनल", ja: "チャンネル", ko: "채널", it: "Canali", nl: "Kanalen", sv: "Kanaler" }
    s["favorites"] = { en: "Favorites", ar: "المفضلة", fr: "Favoris", es: "Favoritos", de: "Favoriten", pt: "Favoritos", tr: "Favoriler", ru: "Избранное", zh: "收藏", hi: "पसंदीदा", ja: "お気に入り", ko: "즐겨찾기", it: "Preferiti", nl: "Favorieten", sv: "Favoriter" }
    s["settings"] = { en: "Settings", ar: "الإعدادات", fr: "Paramètres", es: "Ajustes", de: "Einstellungen", pt: "Configurações", tr: "Ayarlar", ru: "Настройки", zh: "设置", hi: "सेटिंग्स", ja: "設定", ko: "설정", it: "Impostazioni", nl: "Instellingen", sv: "Inställningar" }
    s["searchChannels"] = { en: "Search channels...", ar: "بحث القنوات...", fr: "Rechercher...", es: "Buscar canales...", de: "Kanäle suchen...", pt: "Pesquisar canais...", tr: "Kanal ara...", ru: "Поиск каналов...", zh: "搜索频道...", hi: "चैनल खोजें...", ja: "チャンネル検索...", ko: "채널 검색...", it: "Cerca canali...", nl: "Kanalen zoeken...", sv: "Sök kanaler..." }
    s["noChannelsFound"] = { en: "No channels found.", ar: "لم يتم العثور على قنوات.", fr: "Aucune chaîne trouvée.", es: "No se encontraron canales.", de: "Keine Kanäle gefunden.", pt: "Nenhum canal encontrado.", tr: "Kanal bulunamadı.", ru: "Каналы не найдены.", zh: "未找到频道。", hi: "कोई चैनल नहीं मिला।", ja: "チャンネルが見つかりません。", ko: "채널을 찾을 수 없습니다.", it: "Nessun canale trovato.", nl: "Geen kanalen gevonden.", sv: "Inga kanaler hittades." }
    s["noFavorites"] = { en: "No favorite channels yet", ar: "لا توجد قنوات مفضلة بعد", fr: "Pas de favoris", es: "Sin canales favoritos", de: "Noch keine Favoriten", pt: "Sem favoritos", tr: "Henüz favori kanal yok", ru: "Нет избранных каналов", zh: "暂无收藏频道", hi: "अभी कोई पसंदीदा चैनल नहीं", ja: "お気に入りチャンネルなし", ko: "즐겨찾기 채널 없음", it: "Nessun canale preferito", nl: "Geen favorieten", sv: "Inga favoriter ännu" }
    s["loadingChannels"] = { en: "Loading channels...", ar: "جاري تحميل القنوات...", fr: "Chargement des chaînes...", es: "Cargando canales...", de: "Kanäle laden...", pt: "Carregando canais...", tr: "Kanallar yükleniyor...", ru: "Загрузка каналов...", zh: "正在加载频道...", hi: "चैनल लोड हो रहे हैं...", ja: "チャンネルを読み込み中...", ko: "채널 로딩 중...", it: "Caricamento canali...", nl: "Kanalen laden...", sv: "Laddar kanaler..." }
    s["cancel"] = { en: "Cancel", ar: "إلغاء", fr: "Annuler", es: "Cancelar", de: "Abbrechen", pt: "Cancelar", tr: "İptal", ru: "Отмена", zh: "取消", hi: "रद्द करें", ja: "キャンセル", ko: "취소", it: "Annulla", nl: "Annuleren", sv: "Avbryt" }
    s["testConnection"] = { en: "Test Connection", ar: "اختبار الاتصال", fr: "Tester la connexion", es: "Probar conexión", de: "Verbindung testen", pt: "Testar conexão", tr: "Bağlantıyı Test Et", ru: "Тест соединения", zh: "测试连接", hi: "कनेक्शन टेस्ट", ja: "接続テスト", ko: "연결 테스트", it: "Test connessione", nl: "Verbinding testen", sv: "Testa anslutning" }
    s["active"] = { en: "Active", ar: "نشط", fr: "Actif", es: "Activo", de: "Aktiv", pt: "Ativo", tr: "Aktif", ru: "Активный", zh: "活跃", hi: "सक्रिय", ja: "アクティブ", ko: "활성", it: "Attivo", nl: "Actief", sv: "Aktiv" }
    s["delete"] = { en: "Delete", ar: "حذف", fr: "Supprimer", es: "Eliminar", de: "Löschen", pt: "Excluir", tr: "Sil", ru: "Удалить", zh: "删除", hi: "हटाएं", ja: "削除", ko: "삭제", it: "Elimina", nl: "Verwijderen", sv: "Radera" }

    m._strings = s
    return s
end function
