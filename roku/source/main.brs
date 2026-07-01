sub Main(args as Dynamic)
    screen = CreateObject("roSGScreen")
    m.port = CreateObject("roMessagePort")
    screen.setMessagePort(m.port)

    scene = screen.CreateScene("MainScene")
    screen.show()

    ' Handle deep link launch
    if args <> invalid
        if args.contentId <> invalid and args.mediaType <> invalid
            scene.deepLink = { contentId: args.contentId, mediaType: args.mediaType }
        end if
    end if

    while true
        msg = wait(0, m.port)
        msgType = type(msg)

        if msgType = "roSGScreenEvent"
            if msg.isScreenClosed()
                return
            end if
        end if
    end while
end sub
