sub init()
    m.titleLabel = m.top.findNode("titleLabel")
    m.groupList = m.top.findNode("groupList")
    m.searchButton = m.top.findNode("searchButton")

    m.groupList.observeField("itemSelected", "onGroupSelected")
    m.searchButton.observeField("buttonSelected", "onSearch")

    m.sectionGroups = []

    ' Load data from global when section is set
    m.top.observeField("section", "onSectionSet")
    m.top.observeField("title", "onTitleSet")
    m.top.observeField("restoreFocus", "onRestoreFocus")

    ' Check if already set
    if m.top.section <> invalid and m.top.section <> ""
        onSectionSet()
    end if
end sub

sub onTitleSet()
    m.titleLabel.text = m.top.title
end sub

sub onSectionSet()
    section = m.top.section
    if section = invalid or section = "" then return

    m.titleLabel.text = m.top.title

    ' Read from global — no large data copying
    allCategories = m.global.categories
    classification = m.global.classification

    if allCategories = invalid or classification = invalid then return

    ' Filter groups for this section
    m.sectionGroups = []
    for each cat in allCategories
        if cat.type = "group" and classification[cat.name] = section
            m.sectionGroups.push(cat)
        end if
    end for

    ' Build group list
    content = CreateObject("roSGNode", "ContentNode")
    for each group in m.sectionGroups
        item = content.createChild("ContentNode")
        item.title = group.name + "  (" + FormatCount(group.channelCount) + ")"
    end for
    m.groupList.content = content

    if m.sectionGroups.count() > 0
        m.groupList.setFocus(true)
    else
        m.searchButton.setFocus(true)
    end if
end sub

sub onGroupSelected()
    idx = m.groupList.itemSelected
    if idx < 0 or idx >= m.sectionGroups.count() then return

    group = m.sectionGroups[idx]

    ' Pass only the group name — ChannelsScreen will filter from global
    m.top.action = { type: "navigate", screen: "ChannelsScreen", params: { groupName: group.name, title: group.name } }
end sub

sub onSearch()
    m.top.action = { type: "navigate", screen: "SearchScreen", params: { section: m.top.section, title: m.top.title } }
end sub

sub onRestoreFocus()
    if m.groupList.content <> invalid and m.groupList.content.getChildCount() > 0
        m.groupList.setFocus(true)
    else
        m.searchButton.setFocus(true)
    end if
end sub

function onKeyEvent(key as String, press as Boolean) as Boolean
    if not press then return false

    if key = "back"
        m.top.action = { type: "back" }
        return true
    end if

    if m.searchButton.hasFocus()
        if key = "down"
            m.groupList.setFocus(true)
            return true
        end if
    else if m.groupList.hasFocus()
        if key = "up" and m.groupList.itemFocused = 0
            m.searchButton.setFocus(true)
            return true
        end if
    end if

    return false
end function
