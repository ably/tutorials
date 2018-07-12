var messageList = {}
var readStatus = {}
var membersList = []
var connections = {}
var currentChat
var apiKey = 'XXX_ABLY_API_KEY'
var clientId = 'client-' + Math.random().toString(36).substr(2, 16)
var realtime = new Ably.Realtime({ key: apiKey, clientId: clientId })
var audio = new Audio('https://notificationsounds.com/soundfiles/a86c450b76fb8c371afead6410d55534/file-sounds-1108-slow-spring-board.mp3');

var AblyRealtime = realtime.channels.get('ChatChannel')
AblyRealtime.presence.subscribe('enter', function(member) {
    AblyRealtime.presence.get((err, members) => {
        membersList = members
        renderMembers()
    })
})
AblyRealtime.presence.subscribe('leave', member => {
    delete(connections[member.client_id])
    if (member.client_id === currentChat) {
        currentChat = undefined
        document.getElementById('chat').style.display = 'none'
    }
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
            var newMessage = readStatus[element.clientId] ? '<span class="label label-info">New</span>' : ''
            html += '<li><small>' + element.clientId + ' <button class="btn btn-xs btn-success" onclick=chat("' + element.clientId + '")>chat now</button> ' + newMessage + ' </small></li>'
        }
    }
    list.innerHTML = html
}

function chat(client_id) {
    if (client_id === clientId) return
        // Create a new connection
    currentChat = client_id
    if (!connections[client_id]) {
        connections[client_id] = new Connection(client_id, AblyRealtime, true)
    }
    document.getElementById('chat').style.display = 'block'
    render()
}
AblyRealtime.subscribe(`ablywebrtc-signal/${clientId}`, msg => {
    if (!connections[msg.data.user]) {
        connections[msg.data.user] = new Connection(msg.data.user, AblyRealtime, false)
    }
    connections[msg.data.user].handleSignal(msg.data.signal)
})

function sendMessage() {
    var message = document.getElementById('message')
    connections[currentChat].send(JSON.stringify({ user: clientId, message: message.value }))
    if (!messageList[currentChat]) {
        messageList[currentChat] = []
    }
    messageList[currentChat].push({ user: 'Me', message: message.value })
    message.value = ''
    render()
}

function recieveMessage(client_id, data) {
    if (!messageList[client_id]) {
        messageList[client_id] = []
    }
    data = JSON.parse(data)
    readStatus[client_id] = true
    messageList[client_id].push({ user: client_id, message: data.message })
    audio.play()
    renderMembers()
    render()
}

function render() {
    if (!messageList[currentChat]) {
        return
    }
    var list = document.getElementById('list')
    var html = ''
    if (messageList[currentChat].length === 0) {
        html += '<li>No chat messages available</li>'
        list.innerHTML = html
        return
    }
    for (var index = 0; index < messageList[currentChat].length; index++) {
        var element = messageList[currentChat][index]
        readStatus[element.user] = false
        if (!element.user) {
            html += '<li><small>' + element.message + '</small></li>'
        } else {
            html += '<li>' + element.user + ': ' + element.message + '</li>'
        }
    }
    list.innerHTML = html
    renderMembers()
}