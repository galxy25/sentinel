 // Show loading notice
var canvas = document.getElementById('canvas-video');
var ctx = canvas.getContext('2d');
ctx.fillStyle = '#333';
ctx.fillText('Loading...', canvas.width/2-30, canvas.height/3);
// Start the player
var client = new WebSocket('wss://' + document.domain + ':9002');
var player = new jsmpeg(client, { canvas:canvas });
