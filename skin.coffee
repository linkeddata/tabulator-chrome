# skin.js

port = null
connect = ->
    port = chrome.extension.connect()
    port.onMessage.addListener (d) ->
        console.log "[#{d.eventName}] [#{d.statusCode}] <#{d.url}>"
        if d.responseHeaders
            for {name, value} in d.responseHeaders when name.toLowerCase() in ['content-location','link','location','updates-via']
                console.log Array(d.eventName.length+3).join(' '), "[#{name}] #{value}"
    port.onDisconnect.addListener ->
        setTimeout(connect, 1000)
connect()

setup = (api) ->
    api.sf.addCallback 'fail', (uri) ->
        console.log '[onFetcherFail]', "<#{uri}>", arguments
        true

load = (uri) ->
    window.document.title = uri
    setup tabulator
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
