sub init()
    m.settingsList = m.top.findNode("settingsList")
    m.settingsList.observeField("itemSelected", "onSettingSelected")

    m.languages = ["en", "ar", "fr", "es", "de", "pt", "tr", "ru", "zh", "hi", "ja", "ko", "it", "nl", "sv"]
    m.languageNames = ["English", "Arabic", "Francais", "Espanol", "Deutsch", "Portugues", "Turkce", "Russian", "Chinese", "Hindi", "Japanese", "Korean", "Italiano", "Nederlands", "Svenska"]
    m.aspectRatios = ["16:9", "4:3", "Fill", "Fit"]

    buildSettingsList()
    m.settingsList.setFocus(true)
end sub

sub buildSettingsList()
    currentLang = GetSetting("app_language", "en")
    currentLangName = "English"
    for i = 0 to m.languages.count() - 1
        if m.languages[i] = currentLang
            currentLangName = m.languageNames[i]
            exit for
        end if
    end for

    currentAspect = GetSetting("aspect_ratio", "16:9")
    recentEnabled = GetSetting("recent_channels", "true")

    content = CreateObject("roSGNode", "ContentNode")

    ' Language
    item = content.createChild("ContentNode")
    item.title = "Language: " + currentLangName
    item.shortDescriptionLine1 = "language"

    ' Aspect Ratio
    item = content.createChild("ContentNode")
    item.title = "Aspect Ratio: " + currentAspect
    item.shortDescriptionLine1 = "aspectRatio"

    ' Recent Channels
    item = content.createChild("ContentNode")
    if recentEnabled = "true"
        item.title = "Recent Channels: ON"
    else
        item.title = "Recent Channels: OFF"
    end if
    item.shortDescriptionLine1 = "recent"

    ' Clear History
    item = content.createChild("ContentNode")
    item.title = "Clear Watch History"
    item.shortDescriptionLine1 = "clearHistory"

    ' Clear Cache
    item = content.createChild("ContentNode")
    item.title = "Clear Image Cache"
    item.shortDescriptionLine1 = "clearCache"

    ' Version
    item = content.createChild("ContentNode")
    item.title = "Version 3.5.0"
    item.shortDescriptionLine1 = "version"

    ' Copyright
    item = content.createChild("ContentNode")
    item.title = "(c) 2026 IPTV App"
    item.shortDescriptionLine1 = "copyright"

    m.settingsList.content = content
end sub

sub onSettingSelected()
    idx = m.settingsList.itemSelected
    content = m.settingsList.content
    if idx < 0 or idx >= content.getChildCount() then return

    item = content.getChild(idx)
    setting = item.shortDescriptionLine1

    if setting = "language"
        cycleLanguage()
    else if setting = "aspectRatio"
        cycleAspectRatio()
    else if setting = "recent"
        toggleRecent()
    else if setting = "clearHistory"
        ClearRecent()
        showMessage("Watch history cleared")
    else if setting = "clearCache"
        DeleteDirectory("tmp:/")
        showMessage("Image cache cleared")
    end if
end sub

sub cycleLanguage()
    currentLang = GetSetting("app_language", "en")
    currentIdx = 0
    for i = 0 to m.languages.count() - 1
        if m.languages[i] = currentLang
            currentIdx = i
            exit for
        end if
    end for
    nextIdx = (currentIdx + 1) mod m.languages.count()
    SetSetting("app_language", m.languages[nextIdx])
    m.global.appLanguage = m.languages[nextIdx]
    buildSettingsList()
end sub

sub cycleAspectRatio()
    current = GetSetting("aspect_ratio", "16:9")
    currentIdx = 0
    for i = 0 to m.aspectRatios.count() - 1
        if m.aspectRatios[i] = current
            currentIdx = i
            exit for
        end if
    end for
    nextIdx = (currentIdx + 1) mod m.aspectRatios.count()
    SetSetting("aspect_ratio", m.aspectRatios[nextIdx])
    buildSettingsList()
end sub

sub toggleRecent()
    current = GetSetting("recent_channels", "true")
    if current = "true"
        SetSetting("recent_channels", "false")
    else
        SetSetting("recent_channels", "true")
    end if
    buildSettingsList()
end sub

sub showMessage(msg as String)
    dialog = CreateObject("roSGNode", "StandardMessageDialog")
    dialog.title = "Done"
    dialog.message = [msg]
    dialog.buttons = ["OK"]
    m.top.getScene().dialog = dialog
end sub

function onKeyEvent(key as String, press as Boolean) as Boolean
    if not press then return false
    if key = "back"
        m.top.action = { type: "back" }
        return true
    end if
    return false
end function
