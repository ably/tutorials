window.onload=function() {
    canvas = document.getElementById("gc");
    ctx = canvas.getContext("2d");
    start();
    setInterval(game, 1000/10);
}
var headX = headY = 10;
var squareSize = gridSize = 20;
var appleX = appleY = 15;
var dirX = dirY = 0;
var trail = [];
var tail = 1;
var openMenu = true;

/* Ably Realtime */
var ably = new Ably.Realtime('REPLACE_WITH_YOUR_API_KEY');
var decoder = new TextDecoder();
var channel = ably.channels.get('input');
channel.subscribe(function(message) {
    var command = decoder.decode(message.data);
    if(!openMenu) {
        if(command == 'left') {
            dirX =- 1;
            dirY =  0;
        } else if(command == 'up') {
            dirX =  0;
            dirY =- 1; 
        } else if(command == 'right') {
            dirX = 1;
            dirY = 0;
        } else if(command == 'down') {
            dirX = 0;
            dirY = 1;
        }
    }
    if(command == 'return') {
            openMenu = false;
    }
});

/* Set up Canvas for a game of Snake */
function start() {
    ctx.textAlign="center";
    ctx.fillStyle="black";
    ctx.fillRect(0, 0, canvas.width, canvas.height);
    ctx.font = "30px Serif";
    ctx.fillStyle="orange";
    ctx.fillText("Snake with Ably", canvas.width / 2, canvas.height / 2 - 70);
    ctx.fillText("press Enter to start", canvas.width / 2, canvas.height / 2 - 40);
    ctx.fillRect(headX * squareSize, headY * squareSize, squareSize - 2, squareSize - 2);
}

function game() {
    if(!openMenu) {
        moveHead();
        drawGame();
     
        if((appleX == headX) && (appleY == headY)) {
            tail++;
            appleX = Math.floor(Math.random() * gridSize);
            appleY = Math.floor(Math.random() * gridSize);
        }
        ctx.fillStyle = "red";
        ctx.fillRect(appleX * squareSize, appleY * squareSize, squareSize - 2, squareSize - 2);
    }
}

function moveHead() {
    headX += dirX;
    headY += dirY;
    if(headX < 0) {
        headX = gridSize - 1;
    }
    if(headX > gridSize - 1) {
        headX = 0;
    }
    if(headY < 0) {
        headY = gridSize - 1;
    }
    if(headY > gridSize - 1) {
        headY = 0;
    }
}

function drawGame() {
    ctx.fillStyle = "black";
    ctx.fillRect(0, 0, canvas.width, canvas.height);
 
    ctx.fillStyle = "orange";
    for(var i = 0; i < trail.length; i++) {
        ctx.fillRect(trail[i].x * squareSize, trail[i].y * squareSize, squareSize - 2, squareSize - 2);
        if((trail[i].x == headX) && (trail[i].y == headY) && ((dirX != 0) || (dirY != 0))) {
            openMenu = true;
        }
    }
    if(openMenu) {
        gameOver();
    }
    trail.push({ x: headX, y: headY });
    while(trail.length > tail) {
        trail.shift();
    }
}

/* Reset states of the game and display Game Over */
function gameOver() {
    openMenu = true;
    ctx.font = "30px Arial";
    ctx.fillText("Game Over", canvas.width / 2, (canvas.height / 2) - 100);
    ctx.fillText("Final Score: " + tail, canvas.width / 2, (canvas.height / 2) - 70);
    headX = 10;
    headY = 10;
    dirX = 0;
    dirY = 0;
    trail = [];
    tail = 1;
}
