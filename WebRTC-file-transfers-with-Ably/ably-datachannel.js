var messageList = {}
var membersList = []
var connections = {}
var currentChat
var apiKey = 'XXX_ABLY_API_KEY'
var clientId = 'client-' + Math.random().toString(36).substr(2, 16)
var realtime = new Ably.Realtime({ key: apiKey, clientId: clientId })
var AblyRealtime = realtime.channels.get('ChatChannel')
var audio = new Audio('https://notificationsounds.com/soundfiles/a86c450b76fb8c371afead6410d55534/file-sounds-1108-slow-spring-board.mp3');

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

function onReadAsDataURL(event, text, file) {
    var chunkLength = 1024;
    var data = {}; // data object to transmit over data channel
    data.name = file.name
    data.size = file.size
    if (event) {
        text = event.target.result; // on first invocationgettrue;we 
        data.stringSize = text.length
        messageList[currentChat][file.name] = {
            completed: true,
            sender: 'me',
            downloadLink: text,
            chunks: []
        }
        render()
    }
    if (text.length > chunkLength) {
        data.message = text.slice(0, chunkLength); // getting chunk using predefined chunk length
    } else {
        data.message = text;
        data.last = true;
    }
    data.sender = clientId
    connections[currentChat].send(JSON.stringify(data));
    var remainingDataURL = text.slice(data.message.length);
    if (remainingDataURL.length) {
        onReadAsDataURL(null, remainingDataURL, file); // continue transmitting
    }
}

function recieveMessage(client_id, data) {
    if (!messageList[client_id]) {
        messageList[client_id] = {}
    }
    data = JSON.parse(data)
    if (!messageList[client_id][data.name]) {
        audio.play()
        messageList[client_id][data.name] = {
            sender: data.sender,
            completed: false,
            downloadLink: '',
            stringSize: data.stringSize,
            chunks: []
        }
    }
    messageList[client_id][data.name].chunks.push(data.message)
    if (data.last) {
        var file = messageList[client_id][data.name].chunks.join('')
        messageList[client_id][data.name].downloadLink = file;
        messageList[client_id][data.name].completed = true;
        audio.play()
    }
    renderMembers()
    render()
}

function render() {
    if (!messageList[currentChat]) {
        return
    }
    var list = document.getElementById('list')
    var html = ''
    if (Object.keys(messageList[currentChat]).length === 0) {
        html += '<li>No files available here</li>'
        list.innerHTML = html
        return
    }
    Object.keys(messageList[currentChat]).forEach((key) => {
        var element = messageList[currentChat][key]
        var downloadPercent = (element.chunks.join('').length / element.stringSize) * 100
        var downloadLink = element.completed ? '<a target =_blank download=' + key + ' href=' + element.downloadLink + ' > download now </a>' : 'recieving ' + downloadPercent + '%'
        html += '<li><small> ' + element.sender + ' : ' + key + '</small> ' + downloadLink + ' </li>'
    });
    list.innerHTML = html
    renderMembers()
}