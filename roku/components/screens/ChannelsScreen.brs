sub init()
    m.titleLabel = m.top.findNode("titleLabel")
    m.countLabel = m.top.findNode("countLabel")
    m.channelGrid = m.top.findNode("channelGrid")

    m.channelGrid.observeField("itemSelected", "onChannelSelected")

    m.channelList = []

    m.top.observeField("title", "onTitleSet")
    m.top.observeField("groupName", "onGroupSet")
    m.top.observeField("section", "onSectionSet")
    m.top.observeField("restoreFocus", "onRestoreFocus")

    ' Check if already set
    if m.top.groupName <> invalid and m.top.groupName <> ""
        onGroupSet()
    else if m.top.section <> invalid and m.top.section <> ""
        onSectionSet()
    end if
end sub

sub onTitleSet()
    m.titleLabel.text = m.top.title
end sub

sub onGroupSet()
    groupName = m.top.groupName
    if groupName = invalid or groupName = "" then return

    m.titleLabel.text = m.top.title

    ' Filter channels from global by group name
    allChannels = m.global.channels
    if allChannels = invalid then return

    m.channelList = []
    for each ch in allChannels
        g = ch.groupTitle
        if g = invalid or g = "" then g = "Uncategorized"
        if g = groupName
            m.channelList.push(ch)
            if m.channelList.count() >= 500 then exit for
        end if
    end for

    buildGrid()
end sub

sub onSectionSet()
    section = m.top.section
    if section = invalid or section = "" then return

    m.titleLabel.text = m.top.title

    allChannels = m.global.channels
    if allChannels = invalid then return

    if section = "all"
        m.channelList = allChannels
    else
        ' Filter by section using classification
        classification = m.global.classification
        if classification = invalid then return

        sectionGroupNames = {}
        allCategories = m.global.categories
        if allCategories <> invalid
            for each cat in allCategories
                if cat.type = "group" and classification[cat.name] = section
                    sectionGroupNames[cat.name] = true
                end if
            end for
        end if

        m.channelList = []
        for each ch in allChannels
            g = ch.groupTitle
            if g = invalid or g = "" then g = "Uncategorized"
            if sectionGroupNames[g] = true
                m.channelList.push(ch)
                if m.channelList.count() >= 500 then exit for
            end if
        end for
    end if

    buildGrid()
end sub

sub buildGrid()
    m.countLabel.text = Str(m.channelList.count()).trim() + " channels"

    content = CreateObject("roSGNode", "ContentNode")

    limit = m.channelList.count()
    if limit > 500 then limit = 500

    for i = 0 to limit - 1
        ch = m.channelList[i]
        item = content.createChild("ContentNode")
        item.title = ch.title
        item.shortDescriptionLine1 = ch.title
        if ch.tvgLogo <> invalid and ch.tvgLogo <> ""
            item.hdPosterUrl = ch.tvgLogo
            item.sdPosterUrl = ch.tvgLogo
        end if
    end for

    m.channelGrid.content = content
    m.channelGrid.setFocus(true)
end sub

sub onChannelSelected()
    idx = m.channelGrid.itemSelected
    if idx < 0 or idx >= m.channelList.count() then return

    channel = m.channelList[idx]
    AddRecent(channel)

    m.top.action = { type: "playChannel", channels: m.channelList, startIndex: idx }
end sub

sub onRestoreFocus()
    m.channelGrid.setFocus(true)
end sub

function onKeyEvent(key as String, press as Boolean) as Boolean
    if not press then return false
    if key = "back"
        m.top.action = { type: "back" }
        return true
    else if key = "options"
        idx = m.channelGrid.itemFocused
        if idx >= 0 and idx < m.channelList.count()
            ToggleFavorite(m.channelList[idx])
        end if
        return true
    end if
    return false
end function
