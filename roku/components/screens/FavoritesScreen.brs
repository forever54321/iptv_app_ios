sub init()
    m.favGrid = m.top.findNode("favGrid")
    m.emptyLabel = m.top.findNode("emptyLabel")
    m.favGrid.observeField("itemSelected", "onFavSelected")
    m.favorites = []
    refreshFavoriteList()
end sub

sub refreshFavoriteList()
    m.favorites = LoadFavorites()
    if m.favorites.count() = 0
        m.emptyLabel.visible = true
        m.favGrid.visible = false
        return
    end if
    m.emptyLabel.visible = false
    m.favGrid.visible = true
    content = CreateObject("roSGNode", "ContentNode")
    for each ch in m.favorites
        item = content.createChild("ContentNode")
        item.title = ch.title
        item.shortDescriptionLine1 = ch.title
        if ch.tvgLogo <> invalid and ch.tvgLogo <> ""
            item.hdPosterUrl = ch.tvgLogo
            item.sdPosterUrl = ch.tvgLogo
        end if
    end for
    m.favGrid.content = content
    m.favGrid.setFocus(true)
end sub

sub onFavSelected()
    idx = m.favGrid.itemSelected
    if idx < 0 or idx >= m.favorites.count() then return
    channel = m.favorites[idx]
    AddRecent(channel)
    m.top.action = { type: "playChannel", channels: m.favorites, startIndex: idx }
end sub

function onKeyEvent(key as String, press as Boolean) as Boolean
    if not press then return false
    if key = "back"
        m.top.action = { type: "back" }
        return true
    else if key = "options"
        idx = m.favGrid.itemFocused
        if idx >= 0 and idx < m.favorites.count()
            ToggleFavorite(m.favorites[idx])
            refreshFavoriteList()
        end if
        return true
    end if
    return false
end function
