REM Logging utilities.

function UnleashLogLevels() as Object
    return {
        none: 0,
        error: 1,
        warn: 2,
        info: 3,
        debug: 4
    }
end function

function unleashLogLevelName(unleashParamLevel as Integer) as String
    unleashLocalNames = {
        "1": "Error",
        "2": "Warn",
        "3": "Info",
        "4": "Debug"
    }
    unleashLocalName = unleashLocalNames[unleashParamLevel.toStr()]
    if unleashLocalName = invalid then
        return "Unknown"
    end if
    return unleashLocalName
end function

REM Forwards log records to a SceneGraph node field so the render thread can
REM print messages produced by the Task thread.
function UnleashLoggerSG(unleashParamNode as Object) as Object
    return {
        node: unleashParamNode,

        log: function(unleashParamLevel as Integer, unleashParamMessage as String) as Void
            m.node.log = {
                level: unleashParamLevel,
                message: unleashParamMessage
            }
        end function
    }
end function

REM Logger backend that prints directly to the console.
function UnleashLoggerPrint() as Object
    return {
        log: function(unleashParamLevel as Integer, unleashParamMessage as String) as Void
            print "[Unleash, " unleashLogLevelName(unleashParamLevel) ", " createObject("roDateTime").asSeconds() "] " unleashParamMessage
        end function
    }
end function

REM Level-filtering logger that delegates to a backend.
function UnleashLogger(unleashParamLogLevel as Integer, unleashParamBackend = invalid as Object) as Object
    return {
        logLevel: unleashParamLogLevel,
        backend: unleashParamBackend,

        error: function(unleashParamMessage as String) as Void
            m.write(UnleashLogLevels().error, unleashParamMessage)
        end function,

        warn: function(unleashParamMessage as String) as Void
            m.write(UnleashLogLevels().warn, unleashParamMessage)
        end function,

        info: function(unleashParamMessage as String) as Void
            m.write(UnleashLogLevels().info, unleashParamMessage)
        end function,

        debug: function(unleashParamMessage as String) as Void
            m.write(UnleashLogLevels().debug, unleashParamMessage)
        end function,

        write: function(unleashParamLevel as Integer, unleashParamMessage as String) as Void
            if m.backend = invalid then
                return
            end if
            if unleashParamLevel > m.logLevel then
                return
            end if
            m.backend.log(unleashParamLevel, unleashParamMessage)
        end function
    }
end function
