sub init()
    m.titleLabel = m.top.findNode("titleLabel")
    m.keyboard = m.top.findNode("keyboard")
    m.resultCount = m.top.findNode("resultCount")
    m.resultsGrid = m.top.findNode("resultsGrid")
    m.noResults = m.top.findNode("noResults")

    m.keyboard.observeField("text", "onTextChanged")
    m.keyboard.observeField("submitted", "onSubmitted")
    m.resultsGrid.observeField("itemSelected", "onResultSelected")

    m.sectionChannels = []
    m.searchResults = []

    m.top.observeField("title", "onTitleSet")
    m.top.observeField("section", "onSectionSet")

    m.keyboard.setFocus(true)

    if m.top.section <> invalid and m.top.section <> ""
        onSectionSet()
    end if
end sub

sub onTitleSet()
    m.titleLabel.text = "Search - " + m.top.title
end sub

sub onSectionSet()
    section = m.top.section
    if section = invalid or section = "" then return

    allChannels = m.global.channels
    classification = m.global.classification
    allCategories = m.global.categories
    if allChannels = invalid then return

    sectionGroupNames = {}
    if allCategories <> invalid and classification <> invalid
        for each cat in allCategories
            if cat.type = "group" and classification[cat.name] = section
                sectionGroupNames[cat.name] = true
            end if
        end for
    end if

    m.sectionChannels = []
    for each ch in allChannels
        g = ch.groupTitle
        if g = invalid or g = "" then g = "Uncategorized"
        if sectionGroupNames[g] = true
            m.sectionChannels.push(ch)
        end if
    end for
end sub

sub onTextChanged()
    ' Live search as user types
    performSearch()
end sub

sub onSubmitted()
    ' Move focus to results when user presses SEARCH
    if m.searchResults.count() > 0
        m.resultsGrid.setFocus(true)
    end if
end sub

sub performSearch()
    query = LCase(m.keyboard.text)

    if query = "" or Len(query) < 2
        m.resultsGrid.content = CreateObject("roSGNode", "ContentNode")
        m.noResults.visible = false
        m.resultCount.text = ""
        return
    end if

    results = []
    for each ch in m.sectionChannels
        if LCase(ch.title).inStr(query) >= 0
            results.push(ch)
            if results.count() >= 100 then exit for
        end if
    end for

    m.searchResults = results
    m.resultCount.text = Str(results.count()).trim() + " results"

    content = CreateObject("roSGNode", "ContentNode")
    for each ch in results
        item = content.createChild("ContentNode")
        item.title = ch.title
        item.shortDescriptionLine1 = ch.title
        if ch.tvgLogo <> invalid and ch.tvgLogo <> ""
            item.hdPosterUrl = ch.tvgLogo
            item.sdPosterUrl = ch.tvgLogo
        end if
    end for

    m.resultsGrid.content = content
    m.noResults.visible = (results.count() = 0)
end sub

sub onResultSelected()
    idx = m.resultsGrid.itemSelected
    if idx < 0 or idx >= m.searchResults.count() then return
    channel = m.searchResults[idx]
    AddRecent(channel)
    m.top.action = { type: "playChannel", channels: m.searchResults, startIndex: idx }
end sub

function onKeyEvent(key as String, press as Boolean) as Boolean
    if not press then return false
    if key = "back"
        if m.resultsGrid.hasFocus()
            m.keyboard.setFocus(true)
            return true
        end if
        m.top.action = { type: "back" }
        return true
    end if

    if key = "right" and m.keyboard.hasFocus() and m.searchResults.count() > 0
        m.resultsGrid.setFocus(true)
        return true
    else if key = "left" and m.resultsGrid.hasFocus()
        m.keyboard.setFocus(true)
        return true
    end if

    return false
end function
