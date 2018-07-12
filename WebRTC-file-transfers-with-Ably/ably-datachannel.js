var messageList = {}
var membersList = []
var connections = {}
var currentChat
var apiKey = 'XXX_ABLY_API_KEY'
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
            html += '<li><small>' + element.clientId + ' <button class="btn btn-xs btn-success" onclick=prepareChat("' + element.clientId + '")>chat now</button></small></li>'
        }
    }
    list.innerHTML = html
}

function PrepareChat(client_id) {
    if (client_id === clientId) return
        // Create a new connection
    currentChat = client_id
    if (!connections[client_id]) {
        connections[client_id] = new Connection(client_id, AblyRealtime, true)
    }
    document.getElementById('chat').style.display = 'block'
    render()
}
AblyRealtime.subscribe(`rtc-signal/${clientId}`, msg => {
    if (!connections[msg.data.user]) {
        connections[msg.data.user] = new Connection(msg.data.user, AblyRealtime, false)
    }
    connections[msg.data.user].handleSignal(msg.data.signal)
})

function sendMessage() {
    if (!messageList[currentChat]) {
        messageList[currentChat] = {}
    }
    var MAX_FSIZE = 2.0
    var fileInput = document.getElementById('file')
    var file = fileInput.files[0];
    var fileReader = new FileReader();
    if (file) {
        var mbSize = file.size / (1024 * 1024);
        if (mbSize > MAX_FSIZE) {
            alert("Your file is too big, sorry.");
            // Reset file input
            return;
        }
        fileReader.onload = (e) => { onReadAsDataURL(e, null, file) }
        fileReader.readAsDataURL(file)
        render()
    }
}