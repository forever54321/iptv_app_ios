sub init()
    m.top.backgroundColor = "#0F0A23"
    m.top.backgroundURI = ""
    m.screenStack = []
    m.global.addFields({ appLanguage: "en", channels: [], categories: [], classification: {} })
    m.top.signalBeacon("AppLaunchComplete")

    ' Load saved language
    lang = RegistryRead("settings", "app_language")
    if lang <> invalid and lang <> ""
        m.global.appLanguage = lang
    end if

    ' Check legal disclaimer
    accepted = RegistryRead("settings", "legal_disclaimer_accepted")
    if accepted = "true"
        showHomeScreen()
    else
        showScreen("LegalDisclaimerScreen", invalid)
    end if

    m.top.observeField("deepLink", "onDeepLink")
end sub

sub showHomeScreen()
    showScreen("HomeScreen", invalid)
end sub

sub showScreen(screenName as String, params as Dynamic)
    screen = CreateObject("roSGNode", screenName)
    if screen = invalid
        print "ERROR: Could not create screen: " + screenName
        return
    end if

    if params <> invalid and type(params) = "roAssociativeArray"
        for each key in params
            if screen.hasField(key)
                screen.setField(key, params[key])
            end if
        end for
    end if

    screen.observeField("action", "onScreenAction")
    m.top.appendChild(screen)
    screen.setFocus(true)
    m.screenStack.push(screen)
end sub

sub popScreen()
    if m.screenStack.count() > 1
        screen = m.screenStack.pop()
        m.top.removeChild(screen)
        ' Focus previous screen
        if m.screenStack.count() > 0
            prevScreen = m.screenStack[m.screenStack.count() - 1]
            ' Trigger refresh
            if prevScreen.hasField("refresh")
                prevScreen.refresh = true
            end if
            ' Signal screen to restore focus to its main element
            if prevScreen.hasField("restoreFocus")
                prevScreen.restoreFocus = true
            end if
            prevScreen.setFocus(true)
        end if
    end if
end sub

sub onScreenAction(event as Dynamic)
    action = event.getData()
    if action = invalid then return

    actionType = ""
    if type(action) = "roAssociativeArray"
        actionType = action.type
    else if type(action) = "roString" or type(action) = "String"
        actionType = action
    end if

    if actionType = "disclaimerAccepted"
        RegistryWrite("settings", "legal_disclaimer_accepted", "true")
        popScreen()
        showHomeScreen()
    else if actionType = "navigate"
        showScreen(action.screen, action.params)
    else if actionType = "back"
        popScreen()
    else if actionType = "playChannel"
        m.global.addFields({ playChannels: action.channels })
        params = {}
        params.startIndex = action.startIndex
        showScreen("PlayerScreen", params)
    end if
end sub

sub onDeepLink()
end sub

function onKeyEvent(key as String, press as Boolean) as Boolean
    if not press then return false

    if key = "back"
        if m.screenStack.count() > 1
            popScreen()
            return true
        end if
    end if

    return false
end function
