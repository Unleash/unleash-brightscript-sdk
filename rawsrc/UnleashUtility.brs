REM General purpose helpers. The string/encoding helpers here are intentionally
REM free of SceneGraph / device dependencies so they can be unit tested
REM off-device with the `brs` interpreter.

function UnleashUtility() as Object
    return {
        REM Percent-encode a string per RFC 3986 (unreserved chars kept verbatim).
        REM Pure BrightScript so it is deterministic and testable off-device.
        urlEncode: function(unleashParamValue as Dynamic) as String
            if unleashParamValue = invalid then
                return ""
            end if

            unleashLocalString = m.toQueryString(unleashParamValue)

            unleashLocalHex = "0123456789ABCDEF"
            unleashLocalBytes = createObject("roByteArray")
            unleashLocalBytes.fromAsciiString(unleashLocalString)

            unleashLocalResult = ""
            for each unleashLocalByte in unleashLocalBytes
                if (unleashLocalByte >= 65 AND unleashLocalByte <= 90) OR (unleashLocalByte >= 97 AND unleashLocalByte <= 122) OR (unleashLocalByte >= 48 AND unleashLocalByte <= 57) OR unleashLocalByte = 45 OR unleashLocalByte = 95 OR unleashLocalByte = 46 OR unleashLocalByte = 126 then
                    unleashLocalResult = unleashLocalResult + chr(unleashLocalByte)
                else
                    unleashLocalHigh = mid(unleashLocalHex, (unleashLocalByte \ 16) + 1, 1)
                    unleashLocalLow = mid(unleashLocalHex, (unleashLocalByte MOD 16) + 1, 1)
                    unleashLocalResult = unleashLocalResult + "%" + unleashLocalHigh + unleashLocalLow
                end if
            end for

            return unleashLocalResult
        end function,

        REM Coerce a scalar (string / int / float / bool) into its string form for
        REM use as a query parameter value.
        toQueryString: function(unleashParamValue as Dynamic) as String
            unleashLocalType = type(unleashParamValue)

            if unleashLocalType = "String" OR unleashLocalType = "roString" then
                return unleashParamValue
            else if unleashLocalType = "Boolean" OR unleashLocalType = "roBoolean" then
                if unleashParamValue then
                    return "true"
                else
                    return "false"
                end if
            else if unleashParamValue = invalid then
                return ""
            else
                return unleashParamValue.toStr()
            end if
        end function,

        trimTrailingSlash: function(unleashParamValue as String) as String
            unleashLocalResult = unleashParamValue
            while len(unleashLocalResult) > 0 AND right(unleashLocalResult, 1) = "/"
                unleashLocalResult = left(unleashLocalResult, len(unleashLocalResult) - 1)
            end while
            return unleashLocalResult
        end function,

        REM Sorted list of keys for an associative array, for deterministic output.
        sortedKeys: function(unleashParamAA as Object) as Object
            unleashLocalKeys = []
            for each unleashLocalKey in unleashParamAA
                unleashLocalKeys.push(unleashLocalKey)
            end for
            unleashLocalKeys.sort()
            return unleashLocalKeys
        end function,

        REM Current time as an ISO-8601 UTC string. Device only.
        isoTimestamp: function() as String
            return createObject("roDateTime").toISOString()
        end function,

        REM A best-effort unique instance id for metrics. Device only.
        generateInstanceId: function() as String
            unleashLocalDeviceInfo = createObject("roDeviceInfo")
            if unleashLocalDeviceInfo <> invalid AND unleashLocalDeviceInfo.getRandomUUID <> invalid then
                return unleashLocalDeviceInfo.getRandomUUID()
            end if
            return "roku-" + createObject("roDateTime").asSeconds().toStr()
        end function
    }
end function
