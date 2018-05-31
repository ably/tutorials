var avatars = {};
var VRchannel;
var myId;

var ably = new Ably.Realtime({ 
  authUrl: '/auth',
  echoMessages: false
});
ably.connection.once('connected', function () {
    myId = ably.auth.tokenDetails.clientId;
    startApp(myId)
})

function startApp(userId) {
    var x = Math.random() * (20 - (-20)) + (-20);
    var y = 0;
    var z = 0;
    var initialPosition = { x: x, y: y, z: z };
    VRchannel = ably.channels.get('vr-channel');
    VRchannel.presence.enter()
    var currentUser = {
        type: 'a-box',
        attr: {
            position: initialPosition,
            rotation: "0 0 0",
            color: "#373737",
            depth: "1",
            height: "1",
            width: "1"
        }
    };
    //publish initial data
    VRchannel.publish('attr-change', currentUser);
    var camera = document.getElementById('user-cam');
    function networkTick() {
        var latestPosition = camera.getAttribute('position');
        var latestRotation = camera.getAttribute('rotation');
        currentUser.attr = {
            position: latestPosition,
            rotation: latestRotation,
            color: "#373737"
        };
        //publish updating data
        VRchannel.publish('attr-change', currentUser);
    };
    setInterval(networkTick, 100);
    //get a list of already existing avatars
    VRchannel.presence.get(function (err, members) {
        for (var i in members) {
            console.log('Found existing avatar')
            console.log(members[i].clientId)
            subscribeToAvatarChanges(members[i].clientId)
        }
    });
    //subscribe to new user entries
    VRchannel.presence.subscribe('enter', function (member) {
        var memberData = JSON.stringify(member);
        var memberJSON = JSON.parse(memberData);
        subscribeToAvatarChanges(memberJSON.clientId);
    })
    //subscribe to existing users leaving
    VRchannel.presence.subscribe('leave', function (member) {
        removeAvatar(JSON.stringify(member.clientId));
    })
}
//remove avatar when a user leaves
function removeAvatar(id) {
    var idToRemove = eval(id).toString();
    var scene = document.getElementById('scene');
    scene.removeChild(avatars[idToRemove]);
}

//add Avatar when user enters
function createAvatar(id, avatarJSON) {
    var attr = JSON.stringify(avatarJSON.data.attr);
    var new_attr = JSON.parse(attr);
    var type = JSON.stringify(avatarJSON.data.type);
    var newBox = document.createElement(eval(type));
    for (var key in new_attr) {
        newBox.setAttribute(key, new_attr[key]);
    }
    //creating eyes
    var leye = document.createElement('a-entity');
    leye.setAttribute('mixin', 'eye');
    var reye = document.createElement('a-entity');
    reye.setAttribute('mixin', 'eye');
    //creating pupils
    var lpupil = document.createElement('a-entity');
    lpupil.setAttribute('mixin', 'pupil');
    var rpupil = document.createElement('a-entity');
    rpupil.setAttribute('mixin', 'pupil');
    //Creating arms
    var larm = document.createElement('a-entity');
    larm.setAttribute('mixin', 'arm');
    var rarm = document.createElement('a-entity');
    rarm.setAttribute('mixin', 'arm');

    var x = Number(JSON.stringify(avatarJSON.data.attr.position.x));
    var y = Number(JSON.stringify(avatarJSON.data.attr.position.y));
    var z = Number(JSON.stringify(avatarJSON.data.attr.position.z));
    var leyex = x + 0.25;
    var leyey = y + 0.20;
    var leyez = z - 0.6;
    var reyex = x - 0.25;
    var reyey = y + 0.20;
    var reyez = z - 0.6;
    var lpx = x + 0.25;
    var lpy = y + 0.20;
    var lpz = z - 0.8;
    var rpx = x - 0.25;
    var rpy = y + 0.20;
    var rpz = z - 0.8;
  
    leye.setAttribute('position', leyex + " " + leyey + " " + leyez);
    reye.setAttribute('position', reyex + " " + reyey + " " + reyez);
    lpupil.setAttribute('position', lpx + " " + lpy + " " + lpz);
    rpupil.setAttribute('position', rpx + " " + rpy + " " + rpz);

    var larmx = x - 0.5;
    var larmy = y - 1.8;
    var larmz = z;
    var rarmx = x + 0.5;
    var rarmy = y - 1.8;
    var rarmz = z;
    larm.setAttribute('position', larmx + " " + larmy + " " + larmz);
    larm.setAttribute('rotation', '0 0 -10');
    rarm.setAttribute('position', rarmx + " " + rarmy + " " + rarmz);
    rarm.setAttribute('rotation', '0 0 10');

    //wrapping the individual avatar entities inside a single entity
    var avatarRoot = document.createElement('a-entity');
    avatarRoot.appendChild(newBox);
    avatarRoot.appendChild(leye);
    avatarRoot.appendChild(reye);
    avatarRoot.appendChild(lpupil);
    avatarRoot.appendChild(rpupil);
    avatarRoot.appendChild(larm);
    avatarRoot.appendChild(rarm);
    avatarRoot.setAttribute('id', id);
    avatarRoot.setAttribute('position', { x: x, y: y, z: z });

    var scene = document.getElementById('scene');
    scene.appendChild(avatarRoot);
    avatars[id] = avatarRoot;
}

//subscribe to changes in attributes
function subscribeToAvatarChanges(id) {
    VRchannel.subscribe('attr-change', function (data) {
        var avatarData = JSON.stringify(data);
        var avatarJSON = JSON.parse(avatarData);
        if (avatarExists(avatarJSON.clientId)) {
            updateAvatar(avatarJSON.clientId, avatarJSON);
        } else {
            if (avatarJSON.clientId != myId)
                createAvatar(avatarJSON.clientId, avatarJSON);
        }
    })
}
//check if avatar needs to be created or updated
function avatarExists(id) {
    return avatars.hasOwnProperty(id);
}
//update Avatar according to changing attributes
function updateAvatar(id, avatarJSON) {
    var avatar = avatars[id];
    var position = JSON.stringify(avatarJSON.data.attr.position);
    var rotation = JSON.stringify(avatarJSON.data.attr.rotation);
    avatar.setAttribute('position', JSON.parse(position));
    avatar.setAttribute('rotation', JSON.parse(rotation));
}