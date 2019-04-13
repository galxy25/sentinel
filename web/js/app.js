 // Show loading notice
var canvas = document.getElementById('canvas-video');
var ctx = canvas.getContext('2d');
ctx.fillStyle = '#333';
ctx.fillText('Loading...', canvas.width/2-30, canvas.height/3);
// Prompt the viewer for the stream password
var password = prompt("Please enter the stream password", "");
let baseStreamURL = 'wss://' + document.domain + ':9002';
// Start the player
var client = new WebSocket(baseStreamURL+'?password='+password);
var player = new jsmpeg(client, { canvas:canvas });
