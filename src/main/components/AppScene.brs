REM Minimal demo scene showing how an application consumes the SDK. Edit the
REM clientKey / url / feature name below for your own Unleash instance, then
REM sideload the channel to a Roku device.

function onTogglesChange() as Void
    enabled = m.unleash.isEnabled(m.demoFeature)
    print "unleash demo: " m.demoFeature " => " enabled

    if enabled then
        m.featureStatus.text = m.demoFeature + " is ENABLED"
    else
        m.featureStatus.text = m.demoFeature + " is disabled"
    end if
end function

function onStatusChange() as Void
    status = m.unleashNode.status
    if status = UnleashStatus().ready then
        m.clientStatus.text = "status: ready"
    else if status = UnleashStatus().error then
        m.clientStatus.text = "status: error"
    else
        m.clientStatus.text = "status: not ready"
    end if
    onTogglesChange()
end function

function init() as Void
    m.demoFeature = "demo-feature"

    m.unleashNode = m.top.findNode("unleash")

    config = UnleashConfig("default:development.unleash-insecure-frontend-api-token", m.unleashNode)
    config.setUrl("https://app.unleash-hosted.com/api/frontend")
    config.setAppName("roku-demo")
    config.setRefreshIntervalSeconds(15)
    config.setLogLevel(UnleashLogLevels().debug)

    context = UnleashCreateContext({
        userId: "demo-user",
        properties: { region: "eu" }
    })

    UnleashInit(config, context)

    m.unleash = UnleashClientSG(m.unleashNode)

    m.featureStatus = m.top.findNode("featureStatus")
    m.featureStatus.font.size = 72
    m.featureStatus.color = "0x72D7EEFF"

    m.clientStatus = m.top.findNode("clientStatus")

    onStatusChange()

    m.unleashNode.observeField("toggles", "onTogglesChange")
    m.unleashNode.observeField("status", "onStatusChange")
end function
