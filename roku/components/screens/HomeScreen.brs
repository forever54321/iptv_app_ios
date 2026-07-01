sub init()
    m.playlistList = m.top.findNode("playlistList")
    m.emptyLabel1 = m.top.findNode("emptyLabel1")
    m.emptyLabel2 = m.top.findNode("emptyLabel2")
    m.favoritesButton = m.top.findNode("favoritesButton")
    m.settingsButton = m.top.findNode("settingsButton")
    m.addButton = m.top.findNode("addButton")

    m.favoritesButton.observeField("buttonSelected", "onFavorites")
    m.settingsButton.observeField("buttonSelected", "onSettings")
    m.addButton.observeField("buttonSelected", "onAdd")
    m.playlistList.observeField("itemSelected", "onPlaylistSelected")

    ' Track which toolbar button has focus (0=favorites, 1=settings, 2=add)
    m.toolbarButtons = [m.favoritesButton, m.settingsButton, m.addButton]
    m.toolbarIndex = 0

    m.top.observeField("refresh", "onRefresh")
    m.top.observeField("restoreFocus", "onRestoreFocus")
    refreshPlaylistList()
end sub

sub onRefresh()
    refreshPlaylistList()
end sub

sub onRestoreFocus()
    if m.playlistList.visible
        m.playlistList.setFocus(true)
    else
        m.addButton.setFocus(true)
    end if
end sub

sub refreshPlaylistList()
    m.playlists = LoadPlaylists()

    if m.playlists.count() = 0
        m.emptyLabel1.visible = true
        m.emptyLabel2.visible = true
        m.playlistList.visible = false
        m.addButton.setFocus(true)
    else
        m.emptyLabel1.visible = false
        m.emptyLabel2.visible = false
        m.playlistList.visible = true

        content = CreateObject("roSGNode", "ContentNode")
        for each source in m.playlists
            item = content.createChild("ContentNode")
            label = source.name
            if source.isActive = true
                label = label + "  [Active]"
            end if
            item.title = label
        end for
        m.playlistList.content = content
        m.playlistList.setFocus(true)
    end if
end sub

sub onPlaylistSelected()
    idx = m.playlistList.itemSelected
    if idx < 0 or idx >= m.playlists.count() then return

    ' Set active
    for i = 0 to m.playlists.count() - 1
        m.playlists[i].isActive = (i = idx)
    end for
    SavePlaylists(m.playlists)

    ' Navigate to groups
    m.top.action = { type: "navigate", screen: "GroupsScreen", params: { playlist: m.playlists[idx] } }
end sub

sub onFavorites()
    m.top.action = { type: "navigate", screen: "FavoritesScreen", params: {} }
end sub

sub onSettings()
    m.top.action = { type: "navigate", screen: "SettingsScreen", params: {} }
end sub

sub onAdd()
    m.top.action = { type: "navigate", screen: "AddPlaylistDialog", params: {} }
end sub

function onKeyEvent(key as String, press as Boolean) as Boolean
    if not press then return false

    ' Handle focus movement between toolbar and list
    if m.playlistList.hasFocus()
        if key = "up"
            ' If at top of list, move focus to toolbar
            if m.playlistList.itemFocused = 0
                m.toolbarIndex = 0
                m.toolbarButtons[m.toolbarIndex].setFocus(true)
                return true
            end if
        end if
    end if

    ' Handle toolbar navigation
    for i = 0 to m.toolbarButtons.count() - 1
        if m.toolbarButtons[i].hasFocus()
            if key = "right" and i < m.toolbarButtons.count() - 1
                m.toolbarIndex = i + 1
                m.toolbarButtons[m.toolbarIndex].setFocus(true)
                return true
            else if key = "left" and i > 0
                m.toolbarIndex = i - 1
                m.toolbarButtons[m.toolbarIndex].setFocus(true)
                return true
            else if key = "down"
                if m.playlistList.visible
                    m.playlistList.setFocus(true)
                end if
                return true
            end if
            exit for
        end if
    end for

    if key = "options"
        ' Show context menu for selected playlist
        return true
    end if

    return false
end function
