REM Thin wrapper around roUrlTransfer for the GET (fetch toggles) and POST
REM (metrics / register) calls the SDK makes. Runs on the Task thread and uses
REM an async transfer with a timeout so a hung request cannot block the loop.
REM Device only.

function UnleashHTTP(unleashParamMessagePort as Object) as Object
    return {
        private: {
            port: unleashParamMessagePort,

            prepare: function(unleashParamUrl as String, unleashParamHeaders as Object) as Object
                unleashLocalTransfer = createObject("roUrlTransfer")
                unleashLocalTransfer.setMessagePort(m.port)
                unleashLocalTransfer.setUrl(unleashParamUrl)
                unleashLocalTransfer.enableEncodings(true)
                unleashLocalTransfer.setCertificatesFile("common:/certs/ca-bundle.crt")
                unleashLocalTransfer.initClientCertificates()
                if unleashParamHeaders <> invalid then
                    unleashLocalTransfer.setHeaders(unleashParamHeaders)
                end if
                return unleashLocalTransfer
            end function,

            await: function(unleashParamTransfer as Object, unleashParamTimeoutMs as Integer) as Object
                unleashLocalId = unleashParamTransfer.getIdentity()

                while true
                    unleashLocalMsg = wait(unleashParamTimeoutMs, m.port)

                    if unleashLocalMsg = invalid then
                        unleashParamTransfer.asyncCancel()
                        return { ok: false, code: -1, body: "" }
                    end if

                    if type(unleashLocalMsg) = "roUrlEvent" AND unleashLocalMsg.getSourceIdentity() = unleashLocalId then
                        unleashLocalCode = unleashLocalMsg.getResponseCode()
                        return {
                            ok: (unleashLocalCode >= 200 AND unleashLocalCode < 300),
                            code: unleashLocalCode,
                            body: unleashLocalMsg.getString()
                        }
                    end if
                end while
            end function
        },

        get: function(unleashParamUrl as String, unleashParamHeaders as Object, unleashParamTimeoutMs = 10000 as Integer) as Object
            unleashLocalTransfer = m.private.prepare(unleashParamUrl, unleashParamHeaders)
            if NOT unleashLocalTransfer.asyncGetToString() then
                return { ok: false, code: -1, body: "" }
            end if
            return m.private.await(unleashLocalTransfer, unleashParamTimeoutMs)
        end function,

        post: function(unleashParamUrl as String, unleashParamHeaders as Object, unleashParamBody as String, unleashParamTimeoutMs = 10000 as Integer) as Object
            unleashLocalTransfer = m.private.prepare(unleashParamUrl, unleashParamHeaders)
            unleashLocalTransfer.setRequest("POST")
            if NOT unleashLocalTransfer.asyncPostFromString(unleashParamBody) then
                return { ok: false, code: -1, body: "" }
            end if
            return m.private.await(unleashLocalTransfer, unleashParamTimeoutMs)
        end function
    }
end function
