REM Configuration object for the Unleash client. `clientKey` is a frontend
REM (client-side) API token. `sceneGraphNode` is the UnleashTask node used to
REM run networking on a background thread; it is optional so the config object
REM can be constructed and inspected in unit tests.

function UnleashConfig(unleashParamClientKey as String, unleashParamSceneGraphNode = invalid as Dynamic) as Object
    unleashLocalThis = {
        private: {
            util: UnleashUtility(),

            clientKey: unleashParamClientKey,
            url: "http://localhost:4242/api/frontend",
            appName: "unleash-brightscript",
            environment: "default",
            headerName: "Authorization",
            customHeaders: {},

            refreshIntervalSeconds: 30,
            metricsIntervalSeconds: 30,
            disableMetrics: false,
            disableRefresh: false,
            offline: false,

            logLevel: UnleashLogLevels().warn,

            sceneGraphNode: unleashParamSceneGraphNode,

            validateURI: function(unleashParamRawURI as String) as Boolean
                return left(unleashParamRawURI, 8) = "https://" OR left(unleashParamRawURI, 7) = "http://"
            end function
        },

        setUrl: function(unleashParamUrl as String) as Boolean
            if m.private.validateURI(unleashParamUrl) then
                m.private.url = m.private.util.trimTrailingSlash(unleashParamUrl)
                return true
            end if
            return false
        end function,

        setAppName: function(unleashParamAppName as String) as Void
            m.private.appName = unleashParamAppName
        end function,

        setEnvironment: function(unleashParamEnvironment as String) as Void
            m.private.environment = unleashParamEnvironment
        end function,

        REM Polling interval in seconds. 0 disables automatic refresh.
        setRefreshIntervalSeconds: function(unleashParamSeconds as Integer) as Void
            m.private.refreshIntervalSeconds = unleashParamSeconds
            m.private.disableRefresh = (unleashParamSeconds <= 0)
        end function,

        setMetricsIntervalSeconds: function(unleashParamSeconds as Integer) as Void
            m.private.metricsIntervalSeconds = unleashParamSeconds
        end function,

        setDisableMetrics: function(unleashParamDisable as Boolean) as Void
            m.private.disableMetrics = unleashParamDisable
        end function,

        setOffline: function(unleashParamOffline as Boolean) as Void
            m.private.offline = unleashParamOffline
        end function,

        setLogLevel: function(unleashParamLevel as Integer) as Void
            m.private.logLevel = unleashParamLevel
        end function,

        REM Override the authorization header name (defaults to "Authorization").
        setHeaderName: function(unleashParamName as String) as Void
            m.private.headerName = unleashParamName
        end function,

        REM Add an extra HTTP header sent with every request.
        addHeader: function(unleashParamName as String, unleashParamValue as String) as Void
            m.private.customHeaders[unleashParamName] = unleashParamValue
        end function,

        REM Build the complete header map for an outbound request.
        buildHeaders: function() as Object
            unleashLocalHeaders = {}
            for each unleashLocalKey in m.private.customHeaders
                unleashLocalHeaders[unleashLocalKey] = m.private.customHeaders[unleashLocalKey]
            end for
            unleashLocalHeaders[m.private.headerName] = m.private.clientKey
            unleashLocalHeaders["Content-Type"] = "application/json"
            unleashLocalHeaders["UNLEASH-APPNAME"] = m.private.appName
            unleashLocalHeaders["unleash-sdk"] = UnleashSdkName() + ":" + UnleashSdkVersion()
            return unleashLocalHeaders
        end function
    }

    return unleashLocalThis
end function
