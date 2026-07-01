sub init()
    m.buttons = m.top.findNode("buttons")
    m.buttons.buttons = ["I Agree", "Decline"]
    m.buttons.observeField("buttonSelected", "onButtonSelected")
    m.buttons.setFocus(true)
end sub

sub onButtonSelected()
    idx = m.buttons.buttonSelected
    if idx = 0
        m.top.action = { type: "disclaimerAccepted" }
    else if idx = 1
        dialog = createObject("roSGNode", "Dialog")
        dialog.title = "Cannot Continue"
        dialog.message = "You must accept the disclaimer to use this app."
        dialog.buttons = ["OK"]
        dialog.observeField("buttonSelected", "onDialogClose")
        m.top.getScene().dialog = dialog
    end if
end sub

sub onDialogClose()
    m.top.getScene().dialog.close = true
    m.buttons.setFocus(true)
end sub

function onKeyEvent(key as String, press as Boolean) as Boolean
    return false
end function
