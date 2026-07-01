sub init()
    m.top.functionName = "fetchPlaylist"
end sub

sub fetchPlaylist()
    url = m.top.url

    if url = invalid or url = ""
        m.top.error = "No URL provided"
        m.top.status = "error"
        return
    end if

    m.top.status = "loading"

    http = CreateObject("roUrlTransfer")
    port = CreateObject("roMessagePort")

    http.setPort(port)
    http.setCertificatesFile("common:/certs/ca-bundle.crt")
    http.setCertificatesDepth(10)
    http.initClientCertificates()
    http.enableHostVerification(false)
    http.enablePeerVerification(false)
    http.enableEncodings(true)
    http.enableFreshConnection(true)
    http.setUrl(url)
    http.addHeader("User-Agent", "VLC/3.0.20 LibVLC/3.0.20")
    http.addHeader("Accept", "*/*")

    ' Use async with message port loop
    started = http.asyncGetToString()

    if not started
        m.top.error = "Could not start request"
        m.top.status = "error"
        return
    end if

    ' Wait for response with 120 second timeout (large playlists need time)
    timeout = 120000
    startTime = CreateObject("roDateTime")
    startMs = startTime.asSeconds() * 1000

    while true
        msg = port.getMessage()

        if msg <> invalid
            if type(msg) = "roUrlEvent"
                code = msg.getResponseCode()
                if code = 200
                    body = msg.getString()
                    if body <> invalid and Len(body) > 0
                        m.top.content = body
                        m.top.status = "success"
                    else
                        m.top.error = "Empty response body"
                        m.top.status = "error"
                    end if
                else
                    reason = msg.getFailureReason()
                    m.top.error = "HTTP " + Str(code) + ": " + reason
                    m.top.status = "error"
                end if
                return
            end if
        end if

        ' Check timeout
        nowTime = CreateObject("roDateTime")
        nowMs = nowTime.asSeconds() * 1000
        if (nowMs - startMs) > timeout
            http.asyncCancel()
            m.top.error = "Timeout after 120 seconds"
            m.top.status = "error"
            return
        end if

        ' Small sleep to not burn CPU
        sleep(100)
    end while
end sub
