REM Tiny assertion helpers for the off-device test suite. Each returns "" on
REM success or a human-readable failure message, which the runner reports.

function uToStr(unleashParamValue as Dynamic) as String
    if unleashParamValue = invalid then
        return "invalid"
    end if
    unleashLocalType = type(unleashParamValue)
    if unleashLocalType = "String" OR unleashLocalType = "roString" then
        return """" + unleashParamValue + """"
    else if unleashLocalType = "Boolean" OR unleashLocalType = "roBoolean" then
        if unleashParamValue then
            return "true"
        else
            return "false"
        end if
    else
        return unleashParamValue.toStr()
    end if
end function

function uAssert(unleashParamCond as Dynamic, unleashParamMsg as String) as String
    if unleashParamCond = true then
        return ""
    end if
    return unleashParamMsg
end function

function uAssertEqual(unleashParamActual as Dynamic, unleashParamExpected as Dynamic, unleashParamMsg as String) as String
    if unleashParamActual = unleashParamExpected then
        return ""
    end if
    return unleashParamMsg + " (expected " + uToStr(unleashParamExpected) + " got " + uToStr(unleashParamActual) + ")"
end function

function uAssertInvalid(unleashParamValue as Dynamic, unleashParamMsg as String) as String
    if unleashParamValue = invalid then
        return ""
    end if
    return unleashParamMsg
end function
