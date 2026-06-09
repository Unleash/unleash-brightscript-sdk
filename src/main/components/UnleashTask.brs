REM Background thread for the Unleash SDK. Polls /api/frontend on an interval,
REM publishes the toggle map onto the `toggles` node field, persists it for
REM bootstrap, accumulates evaluation metrics, and periodically posts them.
REM
REM The threading model (Task node + observed fields + message port) is adapted
REM from the LaunchDarkly Roku SDK (Apache-2.0). See NOTICE.

function init() as Void
    m.messagePort = createObject("roMessagePort")
    m.top.toggles = {}

    m.top.observeField("count", m.messagePort)
    m.top.observeField("flush", m.messagePort)
    m.top.observeField("context", m.messagePort)
    m.top.observeField("config", "startThread")
end function

function startThread() as Void
    m.top.functionName = "mainThread"
    m.top.control = "RUN"
end function

function unleashNowSec() as Integer
    return createObject("roDateTime").asSeconds()
end function

function unleashHeaders() as Object
    unleashLocalCfg = m.unleash.config.private
    unleashLocalHeaders = {}
    if unleashLocalCfg.customHeaders <> invalid then
        for each unleashLocalKey in unleashLocalCfg.customHeaders
            unleashLocalHeaders[unleashLocalKey] = unleashLocalCfg.customHeaders[unleashLocalKey]
        end for
    end if
    unleashLocalHeaders[unleashLocalCfg.headerName] = unleashLocalCfg.clientKey
    unleashLocalHeaders["Content-Type"] = "application/json"
    unleashLocalHeaders["unleash-appname"] = unleashLocalCfg.appName
    unleashLocalHeaders["unleash-sdk"] = UnleashSdkName() + ":" + UnleashSdkVersion()
    return unleashLocalHeaders
end function

function unleashPoll() as Void
    unleashLocalU = m.unleash
    unleashLocalCfg = unleashLocalU.config.private

    if unleashLocalCfg.offline then
        return
    end if

    unleashLocalQuery = UnleashBuildContextQuery(unleashLocalCfg.appName, unleashLocalCfg.environment, unleashLocalU.context, unleashLocalU.util)
    unleashLocalUrl = unleashLocalCfg.url + "?" + unleashLocalQuery

    unleashLocalResp = unleashLocalU.http.get(unleashLocalUrl, unleashHeaders(), 15000)

    if unleashLocalResp.ok then
        unleashLocalParsed = UnleashParseToggles(unleashLocalResp.body)
        if unleashLocalParsed.ok then
            unleashLocalU.toggles = unleashLocalParsed.toggles
            m.top.toggles = unleashLocalParsed.toggles
            unleashLocalU.store.putAll(unleashLocalParsed.toggles)
            if m.top.status <> UnleashStatus().ready then
                m.top.status = UnleashStatus().ready
            end if
            unleashLocalU.logger.debug("unleash: refreshed " + unleashLocalParsed.toggles.count().toStr() + " toggles")
        else
            unleashLocalU.logger.error("unleash: could not parse toggle response")
        end if
    else
        unleashLocalU.logger.error("unleash: fetch failed with code " + unleashLocalResp.code.toStr())
        if m.top.status <> UnleashStatus().ready then
            m.top.status = UnleashStatus().error
        end if
    end if
end function

function unleashRegister() as Void
    unleashLocalU = m.unleash
    unleashLocalCfg = unleashLocalU.config.private

    if unleashLocalCfg.disableMetrics OR unleashLocalCfg.offline then
        return
    end if

    unleashLocalPayload = {
        appName: unleashLocalCfg.appName,
        instanceId: unleashLocalU.instanceId,
        sdkVersion: UnleashSdkName() + ":" + UnleashSdkVersion(),
        strategies: ["default"],
        started: unleashLocalU.util.isoTimestamp(),
        interval: unleashLocalCfg.metricsIntervalSeconds * 1000
    }

    unleashLocalU.http.post(unleashLocalCfg.url + "/client/register", unleashHeaders(), formatJSON(unleashLocalPayload), 15000)
end function

function unleashFlushMetrics() as Void
    unleashLocalU = m.unleash
    unleashLocalCfg = unleashLocalU.config.private

    if unleashLocalCfg.disableMetrics OR unleashLocalCfg.offline then
        return
    end if
    if unleashLocalU.metrics.isEmpty() then
        return
    end if

    unleashLocalStop = unleashLocalU.util.isoTimestamp()
    unleashLocalPayload = unleashLocalU.metrics.build(unleashLocalCfg.appName, unleashLocalU.instanceId, unleashLocalU.metricsStart, unleashLocalStop)

    unleashLocalU.http.post(unleashLocalCfg.url + "/client/metrics", unleashHeaders(), formatJSON(unleashLocalPayload), 15000)

    unleashLocalU.metrics.clear()
    unleashLocalU.metricsStart = unleashLocalStop
end function

function mainThread() as Void
    unleashLocalCfg = m.top.config.private

    m.unleash = {
        config: m.top.config,
        context: m.top.context,
        util: UnleashUtility(),
        logger: UnleashLogger(unleashLocalCfg.logLevel, UnleashLoggerPrint()),
        store: UnleashStoreRegistry("unleash_" + unleashLocalCfg.appName),
        metrics: UnleashMetricsBucket(),
        http: UnleashHTTP(m.messagePort),
        toggles: {},
        instanceId: "",
        metricsStart: ""
    }

    m.unleash.instanceId = m.unleash.util.generateInstanceId()
    m.unleash.metricsStart = m.unleash.util.isoTimestamp()

    REM Bootstrap from the last persisted toggle set so evaluations work before
    REM the first network response completes.
    unleashLocalBoot = m.unleash.store.getAll()
    if unleashLocalBoot.count() > 0 then
        m.unleash.toggles = unleashLocalBoot
        m.top.toggles = unleashLocalBoot
    end if

    unleashRegister()
    unleashPoll()

    unleashLocalLastPoll = unleashNowSec()
    unleashLocalLastMetrics = unleashNowSec()

    REM Wake at the finer of the two cadences so neither task is starved.
    unleashLocalWaitMs = unleashLocalCfg.refreshIntervalSeconds * 1000
    if unleashLocalWaitMs <= 0 then
        unleashLocalWaitMs = unleashLocalCfg.metricsIntervalSeconds * 1000
    end if
    if NOT unleashLocalCfg.disableMetrics AND unleashLocalCfg.metricsIntervalSeconds > 0 AND (unleashLocalCfg.metricsIntervalSeconds * 1000) < unleashLocalWaitMs then
        unleashLocalWaitMs = unleashLocalCfg.metricsIntervalSeconds * 1000
    end if
    if unleashLocalWaitMs <= 0 then
        unleashLocalWaitMs = 30000
    end if

    while true
        unleashLocalMsg = wait(unleashLocalWaitMs, m.messagePort)

        if type(unleashLocalMsg) = "roSGNodeEvent" then
            unleashLocalField = unleashLocalMsg.getField()
            if unleashLocalField = "count" then
                unleashLocalData = unleashLocalMsg.getData()
                if unleashLocalData <> invalid then
                    if unleashLocalData.kind = "enabled" then
                        m.unleash.metrics.count(unleashLocalData.name, unleashLocalData.enabled)
                    else if unleashLocalData.kind = "variant" then
                        m.unleash.metrics.countVariant(unleashLocalData.name, unleashLocalData.variant)
                    end if
                end if
            else if unleashLocalField = "context" then
                m.unleash.context = unleashLocalMsg.getData()
                unleashPoll()
                unleashLocalLastPoll = unleashNowSec()
            else if unleashLocalField = "flush" then
                unleashFlushMetrics()
                unleashLocalLastMetrics = unleashNowSec()
            end if
        end if

        unleashLocalNow = unleashNowSec()

        if unleashLocalCfg.refreshIntervalSeconds > 0 AND (unleashLocalNow - unleashLocalLastPoll) >= unleashLocalCfg.refreshIntervalSeconds then
            unleashPoll()
            unleashLocalLastPoll = unleashLocalNow
        end if

        if NOT unleashLocalCfg.disableMetrics AND unleashLocalCfg.metricsIntervalSeconds > 0 AND (unleashLocalNow - unleashLocalLastMetrics) >= unleashLocalCfg.metricsIntervalSeconds then
            unleashFlushMetrics()
            unleashLocalLastMetrics = unleashLocalNow
        end if
    end while
end function
