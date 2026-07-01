sub init()
    m.categoryList = m.top.findNode("categoryList")
    m.loadingLabel = m.top.findNode("loadingLabel")
    m.debugLabel = m.top.findNode("debugLabel")

    m.categoryList.observeField("itemSelected", "onCategorySelected")
    m.top.observeField("playlist", "onPlaylistSet")
    m.top.observeField("restoreFocus", "onRestoreFocus")

    m.allChannels = []
    m.categories = []
    m.classification = {}
    m.loaded = false

    ' Check if playlist was already set before init
    if m.top.playlist <> invalid
        onPlaylistSet()
    end if
end sub

sub onPlaylistSet()
    if m.loaded then return
    playlist = m.top.playlist
    if playlist = invalid
        m.debugLabel.text = "Error: playlist is invalid"
        return
    end if

    url = playlist.url
    if url = invalid or url = ""
        m.debugLabel.text = "Error: URL is empty. Playlist name: " + toStr(playlist.name)
        return
    end if

    m.loaded = true
    m.loadingLabel.text = "Loading channels..."
    m.debugLabel.text = "Fetching: " + Left(url, 100) + "..."

    ' Fetch playlist content
    m.fetchTask = CreateObject("roSGNode", "PlaylistFetchTask")
    m.fetchTask.url = url
    m.fetchTask.observeField("status", "onFetchStatus")
    m.fetchTask.observeField("error", "onFetchError")
    m.fetchTask.control = "run"
end sub

function toStr(val as Dynamic) as String
    if val = invalid then return "(null)"
    if type(val) = "roString" or type(val) = "String" then return val
    return ""
end function

sub onFetchStatus()
    status = m.fetchTask.status
    if status = "success"
        contentLen = 0
        if m.fetchTask.content <> invalid
            contentLen = Len(m.fetchTask.content)
        end if
        m.debugLabel.text = "Fetched " + Str(contentLen) + " bytes. Parsing..."

        ' Parse the content
        m.parseTask = CreateObject("roSGNode", "M3uParseTask")
        m.parseTask.rawContent = m.fetchTask.content
        m.parseTask.observeField("status", "onParseStatus")
        m.parseTask.control = "run"
    else if status = "error"
        errMsg = ""
        if m.fetchTask.error <> invalid then errMsg = m.fetchTask.error
        m.loadingLabel.text = "Error loading playlist"
        m.debugLabel.text = "Fetch error: " + errMsg
        m.loaded = false
    else if status = "loading"
        m.debugLabel.text = "Connecting to server..."
    end if
end sub

sub onFetchError()
    ' Fallback - check if error field changed
    if m.fetchTask.error <> invalid and m.fetchTask.error <> ""
        m.debugLabel.text = "Error: " + m.fetchTask.error
        m.loadingLabel.text = "Failed to load"
        m.loaded = false
    end if
end sub

sub onParseStatus()
    status = m.parseTask.status
    if status = "success"
        parsed = m.parseTask.parsedEntries
        cats = m.parseTask.categories

        if parsed <> invalid and parsed.entries <> invalid
            m.allChannels = parsed.entries
        end if
        if cats <> invalid and cats.categories <> invalid
            m.categories = cats.categories
        end if

        m.debugLabel.text = "Parsed " + Str(m.allChannels.count()) + " channels, " + Str(m.categories.count()) + " categories"

        ' Store in global so other screens can access without copying
        m.global.channels = m.allChannels
        m.global.categories = m.categories

        ' Classify groups
        groupChannels = {}
        for each ch in m.allChannels
            g = ch.groupTitle
            if g = invalid or g = "" then g = "Uncategorized"
            if groupChannels[g] = invalid then groupChannels[g] = []
            groupChannels[g].push(ch)
        end for

        m.classification = {}
        groups = []
        for each cat in m.categories
            if cat.type = "group"
                groups.push(cat)
                channelsInGroup = groupChannels[cat.name]
                if channelsInGroup = invalid then channelsInGroup = []
                m.classification[cat.name] = ClassifyGroup(cat.name, channelsInGroup)
            end if
        end for

        ' Count per section
        liveCount = 0 : movieCount = 0 : showCount = 0
        liveGroups = 0 : movieGroups = 0 : showGroups = 0
        for each g in groups
            section = m.classification[g.name]
            if section = "live"
                liveCount = liveCount + g.channelCount
                liveGroups = liveGroups + 1
            else if section = "movies"
                movieCount = movieCount + g.channelCount
                movieGroups = movieGroups + 1
            else if section = "shows"
                showCount = showCount + g.channelCount
                showGroups = showGroups + 1
            end if
        end for

        ' Build category cards with poster images
        content = CreateObject("roSGNode", "ContentNode")

        item = content.createChild("ContentNode")
        item.title = Str(liveCount).trim() + " channels"
        item.shortDescriptionLine1 = "live"
        item.hdPosterUrl = "pkg:/images/cat_live.png"
        item.sdPosterUrl = "pkg:/images/cat_live.png"

        item = content.createChild("ContentNode")
        item.title = Str(movieCount).trim() + " items"
        item.shortDescriptionLine1 = "movies"
        item.hdPosterUrl = "pkg:/images/cat_movies.png"
        item.sdPosterUrl = "pkg:/images/cat_movies.png"

        item = content.createChild("ContentNode")
        item.title = Str(showCount).trim() + " items"
        item.shortDescriptionLine1 = "shows"
        item.hdPosterUrl = "pkg:/images/cat_shows.png"
        item.sdPosterUrl = "pkg:/images/cat_shows.png"

        item = content.createChild("ContentNode")
        item.title = Str(m.allChannels.count()).trim() + " total"
        item.shortDescriptionLine1 = "all"
        item.hdPosterUrl = "pkg:/images/cat_all.png"
        item.sdPosterUrl = "pkg:/images/cat_all.png"

        m.categoryList.content = content
        m.loadingLabel.visible = false
        m.debugLabel.visible = false
        m.categoryList.visible = true
        m.categoryList.setFocus(true)
    end if
end sub

sub onCategorySelected()
    idx = m.categoryList.itemSelected
    content = m.categoryList.content
    if idx < 0 or idx >= content.getChildCount() then return

    item = content.getChild(idx)
    section = item.shortDescriptionLine1

    ' Store classification in global
    m.global.classification = m.classification

    if section = "all"
        m.top.action = { type: "navigate", screen: "ChannelsScreen", params: { section: "all", title: "All Channels" } }
    else
        m.top.action = { type: "navigate", screen: "SectionGroupsScreen", params: { section: section, title: item.title } }
    end if
end sub

sub onRestoreFocus()
    if m.categoryList.visible
        m.categoryList.setFocus(true)
    end if
end sub

function onKeyEvent(key as String, press as Boolean) as Boolean
    if not press then return false
    if key = "back"
        m.top.action = { type: "back" }
        return true
    end if
    return false
end function
