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
