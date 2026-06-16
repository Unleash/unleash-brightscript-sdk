REM Off-device unit tests for the SDK's pure logic. Each function returns ""
REM on success or a failure message.

' ---------- Utility ----------

function Test_UrlEncode_Spaces() as String
    u = UnleashUtility()
    return uAssertEqual(u.urlEncode("a b"), "a%20b", "space should encode")
end function

function Test_UrlEncode_Reserved() as String
    u = UnleashUtility()
    return uAssertEqual(u.urlEncode("a/b?c=d&e"), "a%2Fb%3Fc%3Dd%26e", "reserved chars should encode")
end function

function Test_UrlEncode_Unreserved() as String
    u = UnleashUtility()
    return uAssertEqual(u.urlEncode("Hello-world_1.0~"), "Hello-world_1.0~", "unreserved chars should pass through")
end function

function Test_ToQueryString_Types() as String
    u = UnleashUtility()
    r = uAssertEqual(u.toQueryString(true), "true", "bool true") : if r <> "" then return r
    r = uAssertEqual(u.toQueryString(false), "false", "bool false") : if r <> "" then return r
    return uAssertEqual(u.toQueryString(42), "42", "int")
end function

function Test_TrimTrailingSlash() as String
    u = UnleashUtility()
    r = uAssertEqual(u.trimTrailingSlash("http://x/"), "http://x", "single slash") : if r <> "" then return r
    return uAssertEqual(u.trimTrailingSlash("http://x///"), "http://x", "multiple slashes")
end function

function Test_SortedKeys() as String
    u = UnleashUtility()
    keys = u.sortedKeys({ banana: 1, apple: 2, cherry: 3 })
    r = uAssertEqual(keys.count(), 3, "three keys") : if r <> "" then return r
    r = uAssertEqual(keys[0], "apple", "first") : if r <> "" then return r
    r = uAssertEqual(keys[1], "banana", "second") : if r <> "" then return r
    return uAssertEqual(keys[2], "cherry", "third")
end function

' ---------- Context ----------

function Test_CreateContext_Normalizes() as String
    ctx = UnleashCreateContext({ userId: "u1", bogusField: "drop me", properties: { region: "eu" } })
    r = uAssertEqual(ctx.userId, "u1", "userId kept") : if r <> "" then return r
    r = uAssertInvalid(ctx.bogusField, "unknown top-level field dropped") : if r <> "" then return r
    return uAssertEqual(ctx.properties.region, "eu", "property kept")
end function

function Test_BuildContextQuery_Deterministic() as String
    u = UnleashUtility()
    ctx = UnleashCreateContext({ userId: "u1", properties: { region: "eu", "b c": "x y" } })
    query = UnleashBuildContextQuery("my-app", ctx, u)
    expected = "appName=my-app&userId=u1&properties[b%20c]=x%20y&properties[region]=eu"
    return uAssertEqual(query, expected, "query string")
end function

' ---------- Evaluation ----------

function Test_TogglesFromArray() as String
    map = UnleashTogglesFromArray([{ name: "f1", enabled: true }, { name: "f2", enabled: false }])
    r = uAssertEqual(map.count(), 2, "two toggles") : if r <> "" then return r
    return uAssertEqual(map.f1.enabled, true, "f1 enabled")
end function

function Test_ParseToggles_Valid() as String
    body = formatJSON({ toggles: [{ name: "f1", enabled: true }] })
    res = UnleashParseToggles(body)
    r = uAssert(res.ok, "should parse ok") : if r <> "" then return r
    return uAssertEqual(res.toggles.f1.enabled, true, "f1 enabled")
end function

function Test_ParseToggles_InvalidJson() as String
    res = UnleashParseToggles("{ not json")
    return uAssert(res.ok = false, "invalid json should not be ok")
end function

function Test_ParseToggles_MissingTogglesKey() as String
    res = UnleashParseToggles(formatJSON({ somethingElse: true }))
    return uAssert(res.ok = false, "missing toggles key should not be ok")
end function

function Test_IsEnabled() as String
    map = UnleashTogglesFromArray([{ name: "on", enabled: true }, { name: "off", enabled: false }])
    r = uAssertEqual(UnleashIsEnabled(map, "on"), true, "enabled toggle") : if r <> "" then return r
    r = uAssertEqual(UnleashIsEnabled(map, "off"), false, "disabled toggle") : if r <> "" then return r
    return uAssertEqual(UnleashIsEnabled(map, "missing"), false, "unknown toggle defaults false")
end function

function Test_GetVariant_Present() as String
    map = UnleashTogglesFromArray([{ name: "f1", enabled: true, variant: { name: "v1", enabled: true } }])
    v = UnleashGetVariant(map, "f1")
    r = uAssertEqual(v.name, "v1", "variant name") : if r <> "" then return r
    return uAssertEqual(v.feature_enabled, true, "feature_enabled backfilled from toggle")
end function

function Test_GetVariant_NoVariant() as String
    map = UnleashTogglesFromArray([{ name: "f1", enabled: true }])
    v = UnleashGetVariant(map, "f1")
    r = uAssertEqual(v.name, "disabled", "default variant name") : if r <> "" then return r
    return uAssertEqual(v.feature_enabled, true, "feature_enabled reflects enabled toggle")
end function

function Test_GetVariant_MissingToggle() as String
    map = {}
    v = UnleashGetVariant(map, "nope")
    r = uAssertEqual(v.name, "disabled", "default variant name") : if r <> "" then return r
    r = uAssertEqual(v.enabled, false, "default variant disabled") : if r <> "" then return r
    return uAssertEqual(v.feature_enabled, false, "feature disabled for unknown toggle")
end function

' ---------- Response classification / ETag ----------

function Test_ClassifyResponse() as String
    r = uAssertEqual(UnleashClassifyResponse(200), "ok", "200 is ok") : if r <> "" then return r
    r = uAssertEqual(UnleashClassifyResponse(204), "ok", "204 is ok") : if r <> "" then return r
    r = uAssertEqual(UnleashClassifyResponse(304), "notModified", "304 is notModified") : if r <> "" then return r
    r = uAssertEqual(UnleashClassifyResponse(404), "error", "404 is error") : if r <> "" then return r
    r = uAssertEqual(UnleashClassifyResponse(500), "error", "500 is error") : if r <> "" then return r
    return uAssertEqual(UnleashClassifyResponse(-1), "error", "transport failure is error")
end function

function Test_ExtractEtag_CaseInsensitive() as String
    r = uAssertEqual(UnleashExtractEtag({ "ETag": "abc-123" }), "abc-123", "ETag header") : if r <> "" then return r
    return uAssertEqual(UnleashExtractEtag({ "etag": "W/weak-tag" }), "W/weak-tag", "lower-case etag header")
end function

function Test_ExtractEtag_Missing() as String
    r = uAssertInvalid(UnleashExtractEtag({ "content-type": "application/json" }), "no etag present") : if r <> "" then return r
    return uAssertInvalid(UnleashExtractEtag(invalid), "invalid headers")
end function

' ---------- Metrics ----------

function Test_Metrics_Empty() as String
    b = UnleashMetricsBucket()
    return uAssert(b.isEmpty(), "new bucket is empty")
end function

function Test_Metrics_Count() as String
    b = UnleashMetricsBucket()
    b.count("f", true)
    b.count("f", false)
    b.count("f", true)
    payload = b.build("app", "inst", "start", "stop")
    entry = payload.bucket.toggles.f
    r = uAssert(b.isEmpty() = false, "bucket not empty after count") : if r <> "" then return r
    r = uAssertEqual(entry.yes, 2, "yes count") : if r <> "" then return r
    return uAssertEqual(entry.no, 1, "no count")
end function

function Test_Metrics_CountVariant() as String
    b = UnleashMetricsBucket()
    b.countVariant("f", "v1")
    b.countVariant("f", "v1")
    b.countVariant("f", "v2")
    payload = b.build("app", "inst", "start", "stop")
    variants = payload.bucket.toggles.f.variants
    r = uAssertEqual(variants.v1, 2, "v1 count") : if r <> "" then return r
    return uAssertEqual(variants.v2, 1, "v2 count")
end function

function Test_Metrics_BuildShape() as String
    b = UnleashMetricsBucket()
    b.count("f", true)
    payload = b.build("myApp", "myInst", "2024-01-01T00:00:00Z", "2024-01-01T00:00:30Z")
    r = uAssertEqual(payload.appName, "myApp", "appName") : if r <> "" then return r
    r = uAssertEqual(payload.instanceId, "myInst", "instanceId") : if r <> "" then return r
    r = uAssertEqual(payload.bucket.start, "2024-01-01T00:00:00Z", "start") : if r <> "" then return r
    return uAssertEqual(payload.bucket.stop, "2024-01-01T00:00:30Z", "stop")
end function

function Test_Metrics_Clear() as String
    b = UnleashMetricsBucket()
    b.count("f", true)
    b.clear()
    return uAssert(b.isEmpty(), "bucket empty after clear")
end function

' ---------- Config ----------

function Test_Config_Defaults() as String
    c = UnleashConfig("my-token")
    r = uAssertEqual(c.private.clientKey, "my-token", "clientKey") : if r <> "" then return r
    r = uAssertEqual(c.private.appName, "unleash-brightscript", "default appName") : if r <> "" then return r
    r = uAssertEqual(c.private.refreshIntervalSeconds, 30, "default refresh") : if r <> "" then return r
    return uAssertEqual(c.private.headerName, "Authorization", "default header name")
end function

function Test_Config_SetUrl_Valid() as String
    c = UnleashConfig("t")
    ok = c.setUrl("https://example.com/api/frontend/")
    r = uAssert(ok, "https url accepted") : if r <> "" then return r
    return uAssertEqual(c.private.url, "https://example.com/api/frontend", "trailing slash trimmed")
end function

function Test_Config_SetUrl_Invalid() as String
    c = UnleashConfig("t")
    ok = c.setUrl("ftp://example.com")
    r = uAssert(ok = false, "non-http url rejected") : if r <> "" then return r
    return uAssertEqual(c.private.url, "http://localhost:4242/api/frontend", "url unchanged after reject")
end function

function Test_Config_DisableRefresh() as String
    c = UnleashConfig("t")
    c.setRefreshIntervalSeconds(0)
    return uAssert(c.private.disableRefresh, "refresh disabled when interval is 0")
end function

function Test_Config_BuildHeaders() as String
    c = UnleashConfig("secret-token")
    c.setAppName("roku-app")
    c.addHeader("X-Custom", "val")
    h = c.buildHeaders()
    r = uAssertEqual(h.Authorization, "secret-token", "auth header is client key") : if r <> "" then return r
    r = uAssertEqual(h["X-Custom"], "val", "custom header present") : if r <> "" then return r
    r = uAssertEqual(h["Content-Type"], "application/json", "content type") : if r <> "" then return r
    return uAssertEqual(h["UNLEASH-APPNAME"], "roku-app", "appname header")
end function

function Test_Config_CustomHeaderName() as String
    c = UnleashConfig("tok")
    c.setHeaderName("X-API-Key")
    h = c.buildHeaders()
    r = uAssertEqual(h["X-API-Key"], "tok", "custom auth header name") : if r <> "" then return r
    return uAssertInvalid(h.Authorization, "default Authorization header absent")
end function

' ---------- Behavioral parity with unleash-js-sdk ----------
'
' These assert that the BrightScript SDK returns the SAME isEnabled / getVariant
' answers as the official Unleash JavaScript frontend SDK for an identical
' /api/frontend response. The baseline (test/fixtures/expected.json) is captured
' from `unleash-proxy-client` by scripts/capture-baseline.js and embedded into
' the test bundle by scripts/run-tests.js (ParityResponseBody / ParityExpected).

function Test_Parity_BaselinePresent() as String
    expected = parseJSON(ParityExpected())
    if expected = invalid OR expected.count() = 0 then
        return "no JS-SDK baseline embedded; run `make baseline` to capture expected.json"
    end if
    return ""
end function

function Test_Parity_Evaluation() as String
    parsed = UnleashParseToggles(ParityResponseBody())
    if parsed.ok <> true then
        return "fixture response failed to parse"
    end if

    expected = parseJSON(ParityExpected())
    if expected = invalid OR expected.count() = 0 then
        return "no JS-SDK baseline to compare against (run `make baseline`)"
    end if

    for each e in expected
        ie = UnleashIsEnabled(parsed.toggles, e.name)
        r = uAssertEqual(ie, (e.isEnabled = true), "isEnabled parity for " + e.name)
        if r <> "" then return r

        v = UnleashGetVariant(parsed.toggles, e.name)
        r = uAssertEqual(v.name, e.variant.name, "variant name parity for " + e.name)
        if r <> "" then return r
        r = uAssertEqual((v.enabled = true), (e.variant.enabled = true), "variant enabled parity for " + e.name)
        if r <> "" then return r
        r = uAssertEqual((v.feature_enabled = true), (e.variant.feature_enabled = true), "variant feature_enabled parity for " + e.name)
        if r <> "" then return r

        if e.variant.payload <> invalid then
            if v.payload = invalid then
                return "expected payload for " + e.name + " but BrightScript returned none"
            end if
            r = uAssertEqual(v.payload.type, e.variant.payload.type, "payload type parity for " + e.name)
            if r <> "" then return r
            r = uAssertEqual(v.payload.value, e.variant.payload.value, "payload value parity for " + e.name)
            if r <> "" then return r
        end if
    end for

    return ""
end function
