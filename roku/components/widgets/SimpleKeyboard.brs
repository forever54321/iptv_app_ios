sub init()
    m.textDisplay = m.top.findNode("textDisplay")
    m.keyList = m.top.findNode("keyList")
    m.keyList.observeField("itemSelected", "onKeySelected")

    ' When this Group gets focus, pass it to the keyList
    m.top.observeField("focusedChild", "onFocusChange")

    m.currentText = ""
    buildKeys()
    updateDisplay()
end sub

sub onFocusChange()
    if m.top.hasFocus()
        m.keyList.setFocus(true)
    end if
end sub

sub buildKeys()
    content = CreateObject("roSGNode", "ContentNode")

    ' Action keys
    item = content.createChild("ContentNode")
    item.title = ">> SEARCH <<"
    item.shortDescriptionLine1 = "submit"

    item = content.createChild("ContentNode")
    item.title = "<< BACKSPACE"
    item.shortDescriptionLine1 = "backspace"

    item = content.createChild("ContentNode")
    item.title = "CLEAR ALL"
    item.shortDescriptionLine1 = "clear"

    item = content.createChild("ContentNode")
    item.title = "[ SPACE ]"
    item.shortDescriptionLine1 = "space"

    ' Letters
    letters = "abcdefghijklmnopqrstuvwxyz"
    for i = 0 to Len(letters) - 1
        ch = Mid(letters, i + 1, 1)
        item = content.createChild("ContentNode")
        item.title = UCase(ch) + "  " + ch
        item.shortDescriptionLine1 = ch
    end for

    ' Numbers
    for i = 0 to 9
        num = Str(i).trim()
        item = content.createChild("ContentNode")
        item.title = num
        item.shortDescriptionLine1 = num
    end for

    ' Special chars
    specials = [".", "/", ":", "-", "_", "?", "=", "&", "@"]
    for each s in specials
        item = content.createChild("ContentNode")
        item.title = s
        item.shortDescriptionLine1 = s
    end for

    m.keyList.content = content
end sub

sub onKeySelected()
    idx = m.keyList.itemSelected
    content = m.keyList.content
    if idx < 0 or idx >= content.getChildCount() then return

    item = content.getChild(idx)
    key = item.shortDescriptionLine1

    if key = "submit"
        m.top.text = m.currentText
        m.top.submitted = true
    else if key = "backspace"
        if Len(m.currentText) > 0
            m.currentText = Left(m.currentText, Len(m.currentText) - 1)
        end if
        m.top.text = m.currentText
        updateDisplay()
    else if key = "clear"
        m.currentText = ""
        m.top.text = ""
        updateDisplay()
    else if key = "space"
        m.currentText = m.currentText + " "
        m.top.text = m.currentText
        updateDisplay()
    else
        m.currentText = m.currentText + key
        m.top.text = m.currentText
        updateDisplay()
    end if
end sub

sub updateDisplay()
    if m.currentText = ""
        m.textDisplay.text = "Type: _"
    else
        m.textDisplay.text = "Type: " + m.currentText + "_"
    end if
end sub

sub setText(newText as String)
    m.currentText = newText
    m.top.text = newText
    updateDisplay()
end sub
