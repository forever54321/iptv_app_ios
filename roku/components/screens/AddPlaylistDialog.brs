sub init()
    m.fieldList = m.top.findNode("fieldList")
    m.keyboard = m.top.findNode("keyboard")
    m.editLabel = m.top.findNode("editLabel")

    m.playlistType = "direct"
    m.activeField = ""
    m.fieldValues = {
        name: "",
        url: "",
        username: "",
        password: ""
    }

    m.fieldList.observeField("itemSelected", "onFieldSelected")
    m.keyboard.observeField("submitted", "onKeyboardSubmit")

    buildFieldList()
    m.fieldList.setFocus(true)
end sub

sub buildFieldList()
    content = CreateObject("roSGNode", "ContentNode")

    item = content.createChild("ContentNode")
    item.title = "Type: " + getTypeLabel() + " (OK to toggle)"
    item.shortDescriptionLine1 = "type"

    item = content.createChild("ContentNode")
    nameVal = m.fieldValues.name
    if nameVal = "" then nameVal = "(OK to edit)"
    item.title = "Name: " + nameVal
    item.shortDescriptionLine1 = "name"

    item = content.createChild("ContentNode")
    urlVal = m.fieldValues.url
    if urlVal = "" then urlVal = "(OK to edit)"
    item.title = "URL: " + urlVal
    item.shortDescriptionLine1 = "url"

    if m.playlistType = "xtreamCodes"
        item = content.createChild("ContentNode")
        userVal = m.fieldValues.username
        if userVal = "" then userVal = "(OK to edit)"
        item.title = "User: " + userVal
        item.shortDescriptionLine1 = "username"

        item = content.createChild("ContentNode")
        passVal = m.fieldValues.password
        if passVal = "" then passVal = "(OK to edit)"
        item.title = "Pass: " + passVal
        item.shortDescriptionLine1 = "password"
    end if

    item = content.createChild("ContentNode")
    item.title = ">> SAVE PLAYLIST <<"
    item.shortDescriptionLine1 = "save"

    item = content.createChild("ContentNode")
    item.title = ">> CANCEL <<"
    item.shortDescriptionLine1 = "cancel"

    m.fieldList.content = content
end sub

function getTypeLabel() as String
    if m.playlistType = "xtreamCodes" then return "Xtream Codes"
    return "M3U URL"
end function

sub onFieldSelected()
    idx = m.fieldList.itemSelected
    content = m.fieldList.content
    if idx < 0 or idx >= content.getChildCount() then return

    item = content.getChild(idx)
    field = item.shortDescriptionLine1

    if field = "type"
        if m.playlistType = "direct"
            m.playlistType = "xtreamCodes"
        else
            m.playlistType = "direct"
        end if
        buildFieldList()
    else if field = "save"
        onSave()
    else if field = "cancel"
        m.top.action = { type: "back" }
    else
        ' Show keyboard for this field
        m.activeField = field
        m.editLabel.text = "Editing: " + field
        m.keyboard.text = m.fieldValues[field]
        m.keyboard.visible = true
        m.keyboard.setFocus(true)
    end if
end sub

sub onKeyboardSubmit()
    ' Save typed text to field
    if m.activeField <> "" and m.activeField <> invalid
        m.fieldValues[m.activeField] = m.keyboard.text
    end if
    m.keyboard.visible = false
    m.editLabel.text = ""
    m.activeField = ""
    savedPos = m.fieldList.itemFocused
    buildFieldList()
    m.fieldList.jumpToItem = savedPos
    m.fieldList.setFocus(true)
end sub

sub onSave()
    url = m.fieldValues.url
    if url = "" then return

    name = m.fieldValues.name
    if name = "" then name = "Unnamed"

    source = {
        name: name,
        url: url,
        type: m.playlistType,
        isActive: false
    }

    if m.playlistType = "xtreamCodes"
        source.username = m.fieldValues.username
        source.password = m.fieldValues.password
        baseUrl = url
        if Right(baseUrl, 1) = "/" then baseUrl = Left(baseUrl, Len(baseUrl) - 1)
        source.url = baseUrl + "/get.php?username=" + source.username + "&password=" + source.password + "&type=m3u_plus&output=ts"
    end if

    playlists = LoadPlaylists()
    if playlists.count() = 0 then source.isActive = true
    playlists.push(source)
    SavePlaylists(playlists)

    m.top.action = { type: "back" }
end sub

function onKeyEvent(key as String, press as Boolean) as Boolean
    if not press then return false

    if key = "back"
        if m.keyboard.visible and m.keyboard.hasFocus()
            ' Save and go back to field list
            if m.activeField <> "" and m.activeField <> invalid
                m.fieldValues[m.activeField] = m.keyboard.text
            end if
            m.keyboard.visible = false
            m.editLabel.text = ""
            m.activeField = ""
            buildFieldList()
            m.fieldList.setFocus(true)
            return true
        end if
        m.top.action = { type: "back" }
        return true
    end if

    return false
end function
