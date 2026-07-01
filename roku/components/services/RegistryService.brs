' Registry Service — persistent storage using Roku registry (16KB per section)

function RegistryRead(section as String, key as String) as Dynamic
    sec = CreateObject("roRegistrySection", section)
    if sec.Exists(key)
        return sec.Read(key)
    end if
    return invalid
end function

sub RegistryWrite(section as String, key as String, value as String)
    sec = CreateObject("roRegistrySection", section)
    sec.Write(key, value)
    sec.Flush()
end sub

sub RegistryDelete(section as String, key as String)
    sec = CreateObject("roRegistrySection", section)
    if sec.Exists(key)
        sec.Delete(key)
        sec.Flush()
    end if
end sub

' Playlist sources
function LoadPlaylists() as Object
    raw = RegistryRead("playlists", "sources")
    if raw <> invalid and raw <> ""
        json = ParseJSON(raw)
        if json <> invalid then return json
    end if
    return []
end function

sub SavePlaylists(sources as Object)
    RegistryWrite("playlists", "sources", FormatJSON(sources))
end sub

function GetActivePlaylist() as Dynamic
    sources = LoadPlaylists()
    for each s in sources
        if s.isActive = true then return s
    end for
    if sources.count() > 0 then return sources[0]
    return invalid
end function

' Favorites
function LoadFavorites() as Object
    raw = RegistryRead("favorites", "list")
    if raw <> invalid and raw <> ""
        json = ParseJSON(raw)
        if json <> invalid then return json
    end if
    return []
end function

sub SaveFavorites(favorites as Object)
    RegistryWrite("favorites", "list", FormatJSON(favorites))
end sub

function IsFavorite(channel as Object) as Boolean
    favorites = LoadFavorites()
    for each fav in favorites
        if fav.url = channel.url then return true
    end for
    return false
end function

sub ToggleFavorite(channel as Object)
    favorites = LoadFavorites()
    found = false
    newFavs = []
    for each fav in favorites
        if fav.url = channel.url
            found = true
        else
            newFavs.push(fav)
        end if
    end for
    if not found
        entry = { title: channel.title, url: channel.url, groupTitle: channel.groupTitle, tvgLogo: channel.tvgLogo, duration: channel.duration }
        newFavs.push(entry)
    end if
    SaveFavorites(newFavs)
end sub

' Recent channels
function LoadRecent() as Object
    raw = RegistryRead("recent", "list")
    if raw <> invalid and raw <> ""
        json = ParseJSON(raw)
        if json <> invalid then return json
    end if
    return []
end function

sub AddRecent(channel as Object)
    recents = LoadRecent()
    ' Remove if already exists
    newList = []
    for each r in recents
        if r.url <> channel.url then newList.push(r)
    end for
    ' Add to front — insert at position 0
    entry = { title: channel.title, url: channel.url, groupTitle: channel.groupTitle, tvgLogo: channel.tvgLogo, duration: channel.duration }
    trimmed = [entry]
    for each item in newList
        if trimmed.count() < 30
            trimmed.push(item)
        end if
    end for
    newList = trimmed
    RegistryWrite("recent", "list", FormatJSON(newList))
end sub

sub ClearRecent()
    RegistryDelete("recent", "list")
end sub

' Settings helpers
function GetSetting(key as String, defaultValue = "" as String) as String
    val = RegistryRead("settings", key)
    if val <> invalid and val <> ""
        return val
    end if
    return defaultValue
end function

sub SetSetting(key as String, value as String)
    RegistryWrite("settings", key, value)
end sub
