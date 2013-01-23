# background.js

enabled = !1

onBeforeSendHeaders = do (types=['application/rdf+xml','text/n3','text/turtle']) ->
    (d) ->
        return if not enabled
        setup = false
        for elt in d.requestHeaders when elt.name.toLowerCase() is 'accept'
            setup = true
            values = elt.value.split ','
            for j, i in values
                if j.indexOf(';') < 0
                    values[i] = values[i] + ';q=0.9'
            for j, i in types
                values.unshift j
            elt.value = values.join ','
            break
        if not setup and d.requestHeaders.push
            values = []
            for j in types
                values.unshift j
            d.requestHeaders.push({name: 'Accept', value: values.join ','})
        return {requestHeaders: d.requestHeaders}

requests = {}

init = (d) ->
    requests[d.requestId] = true
    return { cancel: true }

skinnable = (d) ->
    return requests[d.requestId] == true

skin = (d) ->
    delete requests[d.requestId]
    chrome.tabs.update(d.tabId, {
        url: chrome.extension.getURL 'skin.html?uri='+encodeURIComponent(d.url),
    })

onHeadersReceived = (d) ->
    return if not enabled
    for header in d.responseHeaders
        if header.name.match(/content-type/i) and header.value.match(/\/(n3|rdf|turtle)/)
            return init d

onErrorOccurred = (d) ->
    if skinnable d
        skin d

events = {
    'onBeforeSendHeaders': {
        callback: onBeforeSendHeaders,
        filter: {types: ["main_frame"], urls: ["<all_urls>"]},
        extras: ['requestHeaders', 'blocking'],
    },
    'onHeadersReceived': {
        callback: onHeadersReceived,
        filter: {types: ["main_frame"], urls: ["<all_urls>"]},
        extras: ['responseHeaders', 'blocking'],
    },
    'onErrorOccurred': {
        callback: onErrorOccurred,
        filter: {types: ["main_frame"], urls: ["<all_urls>"]},
    },
}

install = (api=chrome.webRequest) ->
    for event, meta of events
        console.log 'setup/addListener: ' + event
        if meta.extras
            api[event].addListener meta.callback, meta.filter, meta.extras
        else
            api[event].addListener meta.callback, meta.filter
    console.log 'setup: success!'

class Client
    constructor: (@port) ->
        @hooks = ({api, handler: handler.bind(@), extras} for {api, handler, extras} in Client.hooks)
        @id = port.sender.tab.id
        for {api, handler, extras} in @hooks
            if extras
                api.addListener handler, {urls: ['<all_urls>'], tabId: @id}, extras
            else
                api.addListener handler, {urls: ['<all_urls>'], tabId: @id}
    disconnect: ->
        for {api, handler} in @hooks
            api.removeListener handler
    onCompleted: (d) ->
        d.eventName = 'onCompleted'
        @port.postMessage d
    onHeadersReceived: (d) ->
        d.eventName = 'onHeadersReceived'
        d.statusCode = parseInt d.statusLine.split(' ')[1]
        if d.statusCode in [301, 302, 303, 307]
            @port.postMessage d
    onErrorOccurred: (d) ->
        d.eventName = 'onErrorOccurred'
        @port.postMessage d
    @hooks: [
        api: chrome.webRequest.onCompleted
        handler: @::onCompleted
        extras: ['responseHeaders']
    ,
        api: chrome.webRequest.onHeadersReceived
        handler: @::onHeadersReceived
        extras: ['responseHeaders']
    ,
        api: chrome.webRequest.onErrorOccurred
        handler: @::onErrorOccurred
    ]

class Server
    constructor: (@clientClass=Client) ->
        @clients = {}
        chrome.extension.onConnect.addListener @onConnect.bind @

    onConnect: (port) ->
        id = port.portId_
        port.onDisconnect.addListener @onDisconnect.bind @
        @clients[id] = new @clientClass port

    onDisconnect: (port) ->
        id = port.portId_
        if @clients[id]
            @clients[id].disconnect()
            delete @clients[id]

server = new Server

setEnabled = ->
    enabled = !enabled
    if enabled
        chrome.browserAction.setBadgeText
            text: ''
    else
        chrome.browserAction.setBadgeText
            text: 'OFF'

chrome.extension.onMessage.addListener (message, sender, respond) ->
    if message.method in ['disable', 'enable']
        do setEnabled
    respond
        enabled: enabled

do setEnabled
install()
