factory = (method, callback) ->
    ->
        chrome.extension.sendMessage
            method: method,
            callback

getStatus = factory 'status', (r) ->
    if r.enabled
        $('#disable').show()
    else
        $('#enable').show()

jQuery ->
    buttons = document.querySelectorAll 'div.button'
    for elt in buttons
        elt.addEventListener 'click', (e) ->
            do factory e.target.id, ->
                do window.close
    do getStatus
