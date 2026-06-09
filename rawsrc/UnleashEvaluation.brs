REM Pure toggle parsing and evaluation. No SceneGraph / device dependencies, so
REM this is the bulk of what is unit tested off-device.

REM The variant returned when a feature is unknown or has no variant.
function UnleashDefaultVariant() as Object
    return {
        name: "disabled",
        enabled: false,
        feature_enabled: false
    }
end function

REM Convert the array of toggles from a frontend response into a map keyed by
REM toggle name for O(1) lookup.
function UnleashTogglesFromArray(unleashParamArray as Object) as Object
    unleashLocalMap = {}
    if unleashParamArray = invalid then
        return unleashLocalMap
    end if

    for each unleashLocalToggle in unleashParamArray
        if unleashLocalToggle <> invalid AND unleashLocalToggle.name <> invalid then
            unleashLocalMap[unleashLocalToggle.name] = unleashLocalToggle
        end if
    end for

    return unleashLocalMap
end function

REM Classify an HTTP response code from /api/frontend into an action:
REM   "ok"          - a 2xx with a fresh toggle body to apply
REM   "notModified" - a 304; the cached toggles are still valid, do nothing
REM   "error"       - anything else (including transport failures, code <= 0)
function UnleashClassifyResponse(unleashParamCode as Integer) as String
    if unleashParamCode = 304 then
        return "notModified"
    end if
    if unleashParamCode >= 200 AND unleashParamCode < 300 then
        return "ok"
    end if
    return "error"
end function

REM Case-insensitively read the ETag from a response header map. Returns
REM invalid when absent. The stored value is echoed back as If-None-Match on
REM the next request so the server can answer 304 when nothing changed.
function UnleashExtractEtag(unleashParamHeaders as Object) as Dynamic
    if unleashParamHeaders = invalid then
        return invalid
    end if
    for each unleashLocalKey in unleashParamHeaders
        if lCase(unleashLocalKey) = "etag" then
            return unleashParamHeaders[unleashLocalKey]
        end if
    end for
    return invalid
end function

REM Parse a raw /api/frontend JSON body into a toggle map.
REM Returns { ok: Boolean, toggles: Object }.
function UnleashParseToggles(unleashParamBody as Dynamic) as Object
    if unleashParamBody = invalid OR type(unleashParamBody) <> "String" AND type(unleashParamBody) <> "roString" then
        return { ok: false, toggles: {} }
    end if

    unleashLocalParsed = parseJSON(unleashParamBody)
    if unleashLocalParsed = invalid OR unleashLocalParsed.toggles = invalid then
        return { ok: false, toggles: {} }
    end if

    return { ok: true, toggles: UnleashTogglesFromArray(unleashLocalParsed.toggles) }
end function

REM Whether a feature toggle is enabled for the current context.
function UnleashIsEnabled(unleashParamToggles as Object, unleashParamName as String) as Boolean
    if unleashParamToggles = invalid then
        return false
    end if

    unleashLocalToggle = unleashParamToggles[unleashParamName]
    if unleashLocalToggle = invalid then
        return false
    end if

    return (unleashLocalToggle.enabled = true)
end function

REM Resolve the variant for a feature toggle, falling back to the disabled
REM variant. The returned variant always carries `feature_enabled` reflecting
REM whether the parent toggle is on.
function UnleashGetVariant(unleashParamToggles as Object, unleashParamName as String) as Object
    if unleashParamToggles = invalid then
        return UnleashDefaultVariant()
    end if

    unleashLocalToggle = unleashParamToggles[unleashParamName]
    if unleashLocalToggle = invalid then
        return UnleashDefaultVariant()
    end if

    if unleashLocalToggle.variant = invalid then
        unleashLocalVariant = UnleashDefaultVariant()
        unleashLocalVariant.feature_enabled = (unleashLocalToggle.enabled = true)
        return unleashLocalVariant
    end if

    unleashLocalVariant = unleashLocalToggle.variant
    if unleashLocalVariant.feature_enabled = invalid then
        unleashLocalVariant.feature_enabled = (unleashLocalToggle.enabled = true)
    end if

    return unleashLocalVariant
end function
