sub main()
    screen = createObject("roSGScreen")
    messagePort = createObject("roMessagePort")
    screen.setMessagePort(messagePort)

    scene = screen.createScene("AppScene")
    screen.show()

    while true
        msg = wait(0, messagePort)
        if type(msg) = "roSGScreenEvent" then
            if msg.isScreenClosed() then
                return
            end if
        end if
    end while
end sub
