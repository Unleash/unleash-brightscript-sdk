REM Test runner entry point. Executes every registered test and prints a
REM TAP-ish line per test plus a summary the Node wrapper inspects for the
REM process exit code.

sub main()
    tests = [
        { name: "UrlEncode_Spaces", fn: Test_UrlEncode_Spaces }
        { name: "UrlEncode_Reserved", fn: Test_UrlEncode_Reserved }
        { name: "UrlEncode_Unreserved", fn: Test_UrlEncode_Unreserved }
        { name: "ToQueryString_Types", fn: Test_ToQueryString_Types }
        { name: "TrimTrailingSlash", fn: Test_TrimTrailingSlash }
        { name: "SortedKeys", fn: Test_SortedKeys }
        { name: "CreateContext_Normalizes", fn: Test_CreateContext_Normalizes }
        { name: "BuildContextQuery_Deterministic", fn: Test_BuildContextQuery_Deterministic }
        { name: "TogglesFromArray", fn: Test_TogglesFromArray }
        { name: "ParseToggles_Valid", fn: Test_ParseToggles_Valid }
        { name: "ParseToggles_InvalidJson", fn: Test_ParseToggles_InvalidJson }
        { name: "ParseToggles_MissingTogglesKey", fn: Test_ParseToggles_MissingTogglesKey }
        { name: "IsEnabled", fn: Test_IsEnabled }
        { name: "GetVariant_Present", fn: Test_GetVariant_Present }
        { name: "GetVariant_NoVariant", fn: Test_GetVariant_NoVariant }
        { name: "GetVariant_MissingToggle", fn: Test_GetVariant_MissingToggle }
        { name: "ClassifyResponse", fn: Test_ClassifyResponse }
        { name: "ExtractEtag_CaseInsensitive", fn: Test_ExtractEtag_CaseInsensitive }
        { name: "ExtractEtag_Missing", fn: Test_ExtractEtag_Missing }
        { name: "Metrics_Empty", fn: Test_Metrics_Empty }
        { name: "Metrics_Count", fn: Test_Metrics_Count }
        { name: "Metrics_CountVariant", fn: Test_Metrics_CountVariant }
        { name: "Metrics_BuildShape", fn: Test_Metrics_BuildShape }
        { name: "Metrics_Clear", fn: Test_Metrics_Clear }
        { name: "Config_Defaults", fn: Test_Config_Defaults }
        { name: "Config_SetUrl_Valid", fn: Test_Config_SetUrl_Valid }
        { name: "Config_SetUrl_Invalid", fn: Test_Config_SetUrl_Invalid }
        { name: "Config_DisableRefresh", fn: Test_Config_DisableRefresh }
        { name: "Config_BuildHeaders", fn: Test_Config_BuildHeaders }
        { name: "Config_CustomHeaderName", fn: Test_Config_CustomHeaderName }
        { name: "Parity_BaselinePresent", fn: Test_Parity_BaselinePresent }
        { name: "Parity_Evaluation", fn: Test_Parity_Evaluation }
    ]

    failures = 0
    index = 0
    for each t in tests
        index = index + 1
        result = t.fn()
        if result = "" then
            print "ok " index.toStr() " - " t.name
        else
            print "not ok " index.toStr() " - " t.name " : " result
            failures = failures + 1
        end if
    end for

    print "----"
    if failures > 0 then
        print "TEST FAILURE: " failures.toStr() " of " tests.count().toStr() " failed"
    else
        print "ALL TESTS PASSED (" tests.count().toStr() ")"
    end if
end sub
