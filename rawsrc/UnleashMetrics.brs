REM In-memory metrics bucket. Tracks how many times each toggle was evaluated
REM yes/no and which variants were seen, then serializes into the payload
REM expected by POST /api/frontend/client/metrics.
REM
REM Pure (no device dependencies) so bucketing logic is unit tested off-device.

function UnleashMetricsBucket() as Object
    return {
        private: {
            toggles: {},

            ensure: function(unleashParamName as String) as Object
                if m.toggles[unleashParamName] = invalid then
                    m.toggles[unleashParamName] = { yes: 0, no: 0, variants: {} }
                end if
                return m.toggles[unleashParamName]
            end function
        },

        REM Record an isEnabled evaluation.
        count: function(unleashParamName as String, unleashParamEnabled as Boolean) as Void
            unleashLocalEntry = m.private.ensure(unleashParamName)
            if unleashParamEnabled then
                unleashLocalEntry.yes = unleashLocalEntry.yes + 1
            else
                unleashLocalEntry.no = unleashLocalEntry.no + 1
            end if
        end function,

        REM Record a getVariant evaluation.
        countVariant: function(unleashParamName as String, unleashParamVariant as String) as Void
            unleashLocalEntry = m.private.ensure(unleashParamName)
            if unleashLocalEntry.variants[unleashParamVariant] = invalid then
                unleashLocalEntry.variants[unleashParamVariant] = 0
            end if
            unleashLocalEntry.variants[unleashParamVariant] = unleashLocalEntry.variants[unleashParamVariant] + 1
        end function,

        isEmpty: function() as Boolean
            return (m.private.toggles.count() = 0)
        end function,

        clear: function() as Void
            m.private.toggles = {}
        end function,

        REM Build the metrics payload for the given app identity and window.
        build: function(unleashParamAppName as String, unleashParamInstanceId as String, unleashParamStart as String, unleashParamStop as String) as Object
            return {
                appName: unleashParamAppName,
                instanceId: unleashParamInstanceId,
                bucket: {
                    start: unleashParamStart,
                    stop: unleashParamStop,
                    toggles: m.private.toggles
                }
            }
        end function
    }
end function
