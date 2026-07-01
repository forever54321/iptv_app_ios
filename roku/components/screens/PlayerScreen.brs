sub init()
    m.video = m.top.findNode("videoPlayer")
    m.video.observeField("state", "onVideoState")
    m.video.observeField("errorCode", "onVideoError")
    m.video.notificationInterval = 1

    m.channelList = []
    m.currentIndex = 0
    m.retryCount = 0

    m.top.observeField("startIndex", "onStartIndexSet")

    ' Read channels from global
    if m.global.playChannels <> invalid
        m.channelList = m.global.playChannels
    end if

    m.currentIndex = m.top.startIndex

    if m.channelList.count() > 0
        playCurrentChannel()
    end if
end sub

sub onStartIndexSet()
    m.currentIndex = m.top.startIndex
    m.retryCount = 0
    if m.channelList.count() > 0
        playCurrentChannel()
    end if
end sub

sub playCurrentChannel()
    if m.channelList.count() = 0 then return
    if m.currentIndex < 0 or m.currentIndex >= m.channelList.count() then return

    m.video.control = "stop"

    channel = m.channelList[m.currentIndex]
    url = channel.url

    if url = invalid or url = ""
        print "No URL for channel"
        return
    end if

    print "Playing: " + channel.title + " - " + url

    content = CreateObject("roSGNode", "ContentNode")
    content.title = channel.title
    content.url = url
    content.streamFormat = detectStreamFormat(url)

    ' Set HTTP headers
    content.httpHeaders = ["User-Agent: VLC/3.0.20 LibVLC/3.0.20"]

    ' For live streams, disable trick play
    content.live = true

    m.video.content = content
    m.video.enableTrickPlay = false
    m.video.control = "play"
    m.video.setFocus(true)

    ' Track as recent
    AddRecent(channel)
end sub

function detectStreamFormat(url as String) as String
    lower = LCase(url)
    if lower.inStr(".m3u8") >= 0 then return "hls"
    if lower.inStr(".mpd") >= 0 then return "dash"
    if lower.inStr(".mp4") >= 0 then return "mp4"
    if lower.inStr(".mkv") >= 0 then return "mkv"
    if lower.inStr(".m3u") >= 0 then return "hls"
    if lower.inStr("/live/") >= 0 then return "hls"
    if lower.inStr("type=m3u") >= 0 then return "hls"
    ' Default - let Roku auto-detect
    return ""
end function

sub onVideoState()
    state = m.video.state

    if state = "error"
        print "Video error, retry count: " + Str(m.retryCount)
        ' Retry with different format up to 2 times
        if m.retryCount < 2
            m.retryCount = m.retryCount + 1
            m.video.control = "stop"

            ' Try different formats
            content = m.video.content
            if content <> invalid
                currentFormat = content.streamFormat
                if currentFormat = "" or currentFormat = "hls"
                    content.streamFormat = "ts"
                else if currentFormat = "ts"
                    content.streamFormat = "mp4"
                else
                    content.streamFormat = ""
                end if
                print "Retrying with format: " + content.streamFormat
                m.video.content = content
                m.video.control = "play"
            end if
        end if
        ' Do NOT auto-advance to next channel on error
    else if state = "playing"
        m.retryCount = 0
    end if
    ' Do NOT auto-advance on "finished" for live TV
end sub

sub onVideoError()
    code = m.video.errorCode
    print "Video error code: " + Str(code)
end sub

sub nextChannel()
    if m.channelList.count() = 0 then return
    m.currentIndex = (m.currentIndex + 1) mod m.channelList.count()
    m.retryCount = 0
    playCurrentChannel()
end sub

sub previousChannel()
    if m.channelList.count() = 0 then return
    m.currentIndex = (m.currentIndex - 1 + m.channelList.count()) mod m.channelList.count()
    m.retryCount = 0
    playCurrentChannel()
end sub

function onKeyEvent(key as String, press as Boolean) as Boolean
    if not press then return false

    if key = "back"
        m.video.control = "stop"
        m.top.action = { type: "back" }
        return true
    else if key = "right" or key = "fastforward"
        nextChannel()
        return true
    else if key = "left" or key = "rewind"
        previousChannel()
        return true
    else if key = "play"
        if m.video.state = "playing"
            m.video.control = "pause"
        else
            m.video.control = "resume"
        end if
        return true
    end if

    return false
end function
