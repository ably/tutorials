var membersList = []
var connections = {}
var currentCall
var localStream
var constraints = { video: { mediaSource: 'screen' }, audio: false }
var apiKey = 'XXX_API_KEY'
var clientId = 'client-' + Math.random().toString(36).substr(2, 16)
var realtime = new Ably.Realtime({ key: apiKey, clientId: clientId })
var AblyRealtime = realtime.channels.get('ChatChannel')
AblyRealtime.presence.subscribe('enter', function(member) {
    AblyRealtime.presence.get((err, members) => {
        membersList = members
        renderMembers()
    })
})
AblyRealtime.presence.subscribe('leave', member => {
    AblyRealtime.presence.get((err, members) => {
        membersList = members
        renderMembers()
    })
})
AblyRealtime.presence.enter()

function renderMembers() {
    var list = document.getElementById('memberList')
    var online = document.getElementById('online')
    online.innerHTML = 'Users online (' + (membersList.length === 0 ? 0 : membersList.length - 1) + ')'
    var html = ''
    if (membersList.length === 1) {
        html += '<li> No member online </li>'
        list.innerHTML = html
        return
    }
    for (var index = 0; index < membersList.length; index++) {
        var element = membersList[index]
        if (element.clientId !== clientId) {
            html += '<li><small>' + element.clientId + ' <button class="btn btn-xs btn-success" onclick=call("' + element.clientId + '")>call now</button> </small></li>'
        }
    }
    list.innerHTML = html
}

function call(client_id) {
    if (client_id === clientId) return
    alert(`attempting to call ${client_id}`)
    AblyRealtime.publish(`incoming-call/${client_id}`, {
        user: clientId
    })
}
AblyRealtime.subscribe(`incoming-call/${clientId}`, call => {
    if (currentCall != undefined) {
        // user is on another call
        AblyRealtime.publish(`call-details/${call.data.user}`, {
            user: clientId,
            msg: 'User is on another call'
        })
        return
    }
    var isAccepted = confirm(`You have a call from ${call.data.user}, do you want to accept?`)
    if (!isAccepted) {
        // user rejected the call
        AblyRealtime.publish(`call-details/${call.data.user}`, {
            user: clientId,
            msg: 'User declined the call'
        })
        return
    }
    currentCall = call.data.user
    AblyRealtime.publish(`call-details/${call.data.user}`, {
        user: clientId,
        accepted: true
    })
})
AblyRealtime.subscribe(`call-details/${clientId}`, call => {
    if (call.data.accepted) {
        initiateCall(call.data.user)
    } else {
        alert(call.data.msg)
    }
})

function initiateCall(client_id) {
    AdapterJS.webRTCReady(function(isUsingPlugin) {
        // The WebRTC API is ready.
        navigator.mediaDevices.getUserMedia(constraints)
            .then(function(stream) {
                /* use the stream */
                localStream = stream
                var video = document.getElementById('local')
                attachMediaStream(video, stream);
                video.play()
                    // Create a new connection
                currentCall = client_id
                if (!connections[client_id]) {
                    connections[client_id] = new Connection(client_id, AblyRealtime, true, stream)
                }
                document.getElementById('call').style.display = 'block'
            })
            .catch(function(err) {
                /* handle the error */
                alert('Could not get video stream from source')
            })
    });
}
AblyRealtime.subscribe(`rtc-signal/${clientId}`, msg => {
    if (localStream === undefined) {
        AdapterJS.webRTCReady(function(isUsingPlugin) {
            navigator.mediaDevices.getUserMedia(constraints)
                .then(function(stream) {
                    /* use the stream */
                    console.log(stream)
                    localStream = stream
                    var video = document.getElementById('local')
                    attachMediaStream(video, stream);
                    video.play()
                    connect(msg.data, stream)
                })
                .catch(function(err) {
                    alert('error occured while trying to get stream')
                })
        })
    } else {
        connect(msg.data, localStream)
    }
})

function connect(data, stream) {
    if (!connections[data.user]) {
        connections[data.user] = new Connection(data.user, AblyRealtime, false, stream)
    }
    connections[data.user].handleSignal(data.signal)
    document.getElementById('call').style.display = 'block'
}

function recieveStream(client_id, stream) {
    var video = document.getElementById('remote')
    attachMediaStream(video, stream);
    video.play()
    renderMembers()
}