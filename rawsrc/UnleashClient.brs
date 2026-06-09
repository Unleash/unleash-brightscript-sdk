REM Render-thread entry points. `UnleashInit` wires the config + context onto
REM the UnleashTask node, which starts the background polling thread.
REM `UnleashClientSG` returns the handle the application uses to evaluate
REM toggles; it reads the latest toggles from the node and posts evaluation
REM counts / commands back to the Task.

function UnleashStatus() as Object
    return {
        notReady: 0,
        ready: 1,
        error: 2
    }
end function

REM Start the background Task. Call once on the render thread.
function UnleashInit(unleashParamConfig as Object, unleashParamContext as Object) as Void
    unleashLocalNode = unleashParamConfig.private.sceneGraphNode
    unleashLocalNode.context = unleashParamContext
    unleashLocalNode.config = unleashParamConfig
end function

function UnleashClientSG(unleashParamNode as Object) as Object
    return {
        private: {
            node: unleashParamNode
        },

        REM Whether the named feature toggle is enabled. Also records the
        REM evaluation for metrics.
        isEnabled: function(unleashParamName as String) as Boolean
            unleashLocalResult = UnleashIsEnabled(m.private.node.toggles, unleashParamName)
            m.private.node.count = { kind: "enabled", name: unleashParamName, enabled: unleashLocalResult }
            return unleashLocalResult
        end function,

        REM Resolve the variant for the named feature toggle. Also records the
        REM evaluation for metrics.
        getVariant: function(unleashParamName as String) as Object
            unleashLocalVariant = UnleashGetVariant(m.private.node.toggles, unleashParamName)
            m.private.node.count = { kind: "variant", name: unleashParamName, variant: unleashLocalVariant.name }
            return unleashLocalVariant
        end function,

        REM The full toggle map currently held by the client.
        getAllToggles: function() as Object
            return m.private.node.toggles
        end function,

        getStatus: function() as Integer
            return m.private.node.status
        end function,

        isReady: function() as Boolean
            return (m.private.node.status = UnleashStatus().ready)
        end function,

        REM Replace the evaluation context and trigger an immediate refresh.
        updateContext: function(unleashParamContext as Object) as Void
            m.private.node.context = unleashParamContext
        end function,

        REM Force the pending metrics bucket to be sent.
        flushMetrics: function() as Void
            m.private.node.flush = true
        end function
    }
end function
