// background.js

onBeforeSendHeaders = (function factory(types) {
    return function(d) {
        var setup = false;
        for (var i in d.requestHeaders) {
            var name = d.requestHeaders[i].name.toLowerCase();
            if (name == 'accept') {
                setup = true;
                var values = d.requestHeaders[i].value.split(',');
                for (var j in values)
                    if (values[j].indexOf(';') < 0)
                        values[j] = values[j] + ';q=0.9';
                for (var j in types)
                    values.unshift(types[j]);
                d.requestHeaders[i].value = values.join(',');
                break;
            }
        }
        if (!setup && d.requestHeaders.push) {
            var values = [];
            for (var j in types)
                values.unshift(types[j]);
            d.requestHeaders.push({name: 'Accept', value: values.join(',')});
        }
        return {requestHeaders: d.requestHeaders};
    };
})(['application/rdf+xml','text/n3','text/turtle']);

var requests = {};

function init(d) {
    requests[d.requestId] = true;
    return { cancel: true };
}

function skinnable(d) {
    return requests[d.requestId] == true;
}

function skin(d) {
    delete requests[d.requestId];
    chrome.tabs.update(d.tabId, {
        url: chrome.extension.getURL('skin.html?uri='+encodeURIComponent(d.url)),
    });
}

function onHeadersReceived(d) {
    for (var i in d.responseHeaders) {
        var header = d.responseHeaders[i];
        if (header.name && header.name.match(/content-type/i)
                        && header.value.match(/\/(n3|rdf|turtle)/))
            return init(d);
    }
}

function onErrorOccurred(d) {
    if (skinnable(d))
        skin(d);
}

var events = {
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
};

(function setup(api) {
    for (j in events) {
        console.log('setup/addListener: ' + j);
        if (events[j].extras && api[j])
            api[j].addListener(events[j].callback, events[j].filter, events[j].extras);
        else if (api[j])
            api[j].addListener(events[j].callback, events[j].filter);
    }
    console.log('setup: success!');
})(chrome.webRequest);
