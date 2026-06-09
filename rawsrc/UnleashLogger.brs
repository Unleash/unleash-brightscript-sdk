REM Logging utilities.
REM
REM Adapted from the LaunchDarkly Roku SDK (Apache-2.0, (c) Catamorphic, Co.).
REM See NOTICE for attribution.

function UnleashLogLevels() as Object
    return {
        none: 0,
        error: 1,
        warn: 2,
        info: 3,
        debug: 4
    }
end function

REM Logger backend that forwards log records to a SceneGraph node field so the
REM render thread can print them. Used to ship logs off the Task thread.
function UnleashLoggerSG(unleashParamNode as Object) as Object
    return {
        private: {
            node: unleashParamNode
        },

        log: function(unleashParamLevel as Integer, unleashParamMessage as String) as Void
            m.private.node.log = {
                level: unleashParamLevel,
                message: unleashParamMessage
            }
        end function
    }
end function

REM Logger backend that prints directly to the console.
function UnleashLoggerPrint() as Object
    return {
        private: {
            levelToString: function(unleashParamLevel as Integer) as String
                if unleashParamLevel = 1 then
                    return "Error"
                else if unleashParamLevel = 2 then
                    return "Warn"
                else if unleashParamLevel = 3 then
                    return "Info"
                else if unleashParamLevel = 4 then
                    return "Debug"
                else
                    return "Unknown"
                end if
            end function
        },

        log: function(unleashParamLevel as Integer, unleashParamMessage as String) as Void
            unleashLocalNow = createObject("roDateTime").asSeconds()
            print "[Unleash, " m.private.levelToString(unleashParamLevel) ", " unleashLocalNow "] " unleashParamMessage
        end function
    }
end function

REM Level-filtering logger that delegates to a backend.
function UnleashLogger(unleashParamLogLevel as Integer, unleashParamBackend = invalid as Object) as Object
    return {
        private: {
            logLevel: unleashParamLogLevel,
            backend: unleashParamBackend,
            levels: UnleashLogLevels(),

            maybeLog: function(unleashParamLevel as Integer, unleashParamMessage as String) as Void
                if m.backend <> invalid AND unleashParamLevel <= m.logLevel then
                    m.backend.log(unleashParamLevel, unleashParamMessage)
                end if
            end function
        },

        error: function(unleashParamMessage as String) as Void
            m.private.maybeLog(m.private.levels.error, unleashParamMessage)
        end function,

        warn: function(unleashParamMessage as String) as Void
            m.private.maybeLog(m.private.levels.warn, unleashParamMessage)
        end function,

        info: function(unleashParamMessage as String) as Void
            m.private.maybeLog(m.private.levels.info, unleashParamMessage)
        end function,

        debug: function(unleashParamMessage as String) as Void
            m.private.maybeLog(m.private.levels.debug, unleashParamMessage)
        end function
    }
end function
