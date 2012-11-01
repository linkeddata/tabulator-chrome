# skin.js

port = null
connect = ->
    port = chrome.extension.connect()
    port.onMessage.addListener (data) ->
        {method, url, statusLine, responseHeaders} = data
        #console.log "#{method} <#{url}> #{statusLine}"
        #for {name, value} in data.responseHeaders when name is 'Location'
        #    console.log "#{name}: #{value}"
    port.onDisconnect.addListener ->
        setTimeout(connect, 1000)
connect()

load = (uri) ->
    window.document.title = uri
    kb = tabulator.kb
    subject = kb.sym(uri)
    tabulator.outline.GotoSubject(subject, true, undefined, true, undefined)

jQuery ->
    qs = do ->
        r = {}
        for elt in window.location.search.substr(1).split('&')
            p = elt.split '='
            unless p.length is 2
                continue
            r[p[0]] = decodeURIComponent(p[1].replace(/\+/g, " "))
        return r
    if qs.uri
        load qs.uri
