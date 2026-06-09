REM The Unleash context describes the current user/session and is sent with
REM every evaluation request. It is kept as a plain associative array (no
REM closures) so it can be passed across the SceneGraph thread boundary as a
REM node field.

function UnleashCreateContext(unleashParamProps = {} as Object) as Object
    unleashLocalContext = {
        properties: {}
    }

    unleashLocalStandardFields = ["userId", "sessionId", "remoteAddress", "currentTime"]
    for each unleashLocalField in unleashLocalStandardFields
        if unleashParamProps[unleashLocalField] <> invalid then
            unleashLocalContext[unleashLocalField] = unleashParamProps[unleashLocalField]
        end if
    end for

    if unleashParamProps.properties <> invalid then
        for each unleashLocalKey in unleashParamProps.properties
            unleashLocalContext.properties[unleashLocalKey] = unleashParamProps.properties[unleashLocalKey]
        end for
    end if

    return unleashLocalContext
end function

REM Build the URL query string (without a leading "?") that encodes the
REM application identity and context for a GET against /api/frontend.
REM
REM Pure function: takes a utility object for encoding so it can be tested
REM off-device. Output ordering is deterministic.
function UnleashBuildContextQuery(unleashParamAppName as String, unleashParamEnvironment as String, unleashParamContext as Object, unleashParamUtil as Object) as String
    unleashLocalPairs = []

    unleashLocalPairs.push("appName=" + unleashParamUtil.urlEncode(unleashParamAppName))
    unleashLocalPairs.push("environment=" + unleashParamUtil.urlEncode(unleashParamEnvironment))

    unleashLocalStandardFields = ["currentTime", "remoteAddress", "sessionId", "userId"]
    for each unleashLocalField in unleashLocalStandardFields
        if unleashParamContext[unleashLocalField] <> invalid then
            unleashLocalPairs.push(unleashLocalField + "=" + unleashParamUtil.urlEncode(unleashParamContext[unleashLocalField]))
        end if
    end for

    if unleashParamContext.properties <> invalid then
        for each unleashLocalKey in unleashParamUtil.sortedKeys(unleashParamContext.properties)
            unleashLocalValue = unleashParamContext.properties[unleashLocalKey]
            unleashLocalPairs.push("properties[" + unleashParamUtil.urlEncode(unleashLocalKey) + "]=" + unleashParamUtil.urlEncode(unleashLocalValue))
        end for
    end if

    unleashLocalResult = ""
    for unleashLocalIndex = 0 to unleashLocalPairs.count() - 1
        if unleashLocalIndex > 0 then
            unleashLocalResult = unleashLocalResult + "&"
        end if
        unleashLocalResult = unleashLocalResult + unleashLocalPairs[unleashLocalIndex]
    end for

    return unleashLocalResult
end function
