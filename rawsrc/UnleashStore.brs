REM Persistence for the last-known toggle set, used to bootstrap evaluations
REM before the first network response (and while offline). Backed by the Roku
REM registry. Device only — exercised on-device / via the demo channel.

function UnleashStoreRegistry(unleashParamSectionName as String) as Object
    return {
        private: {
            section: createObject("roRegistrySection", unleashParamSectionName),
            key: "toggles"
        },

        REM Returns the persisted toggle map, or an empty map if none.
        getAll: function() as Object
            unleashLocalSerialized = m.private.section.read(m.private.key)
            if unleashLocalSerialized <> invalid AND unleashLocalSerialized <> "" then
                unleashLocalParsed = parseJSON(unleashLocalSerialized)
                if unleashLocalParsed <> invalid then
                    return unleashLocalParsed
                end if
            end if
            return {}
        end function,

        putAll: function(unleashParamToggles as Object) as Void
            m.private.section.write(m.private.key, formatJSON(unleashParamToggles))
            m.private.section.flush()
        end function
    }
end function
