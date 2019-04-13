// tightly based on https://gist.github.com/mharsch/5188206
// loosely based on https://gist.github.com/bnerd/2011232
// requires node.js >= v0.10.0
// assumes that HLS segmenter filename base is 'master'
// and that the HLS playlist and .ts files are in the current directory
// point Safari browser to http://<hostname>:PORT/player.html
/*jslint node: true */
"use strict";

var http = require('http');
var fs = require('fs');
var url = require('url');
var path = require('path');
var zlib = require('zlib');

var PORT = 8000;
// Run hls manifest directory and player webserver listening at $PORT
http.createServer(function (req, res) {
    var uri = url.parse(req.url).pathname,
        local_ip_address = process.env.HOST_IP,
        server_address = 'http://' + local_ip_address + ':' + PORT;

    console.log("Request from: " + local_ip_address);
    console.log("Request uri: " + uri);

    if (uri === '/player.html') {
        var currentDir = './',
            manifests = [];

        fs.readdir(currentDir, function (err, files) {
            manifests = files.filter(function (file) {
                return file.includes('.m3u8') && !file.includes('out');
            });
            res.writeHead(200, { 'Content-Type': 'text/html' });
            res.write('<html><head><title>Sentinel Door Levi' +
                '</title></head><body>');
            // Reverse to have the most recent segments on top.
            manifests = manifests.reverse();
            var first_four = manifests.slice(0, 4),
                remaining = manifests.slice(4);
            first_four.forEach(function (manifest) {
                var start_time = manifest.split('.m3u8')[0];
                res.write('<div>');
                res.write('<p>' + start_time + '</p>');
                res.write('<video src="' + server_address + '/' + manifest + '" controls>');
                res.write('</div>');
            });
            remaining.forEach(function (manifest) {
                var start_time = manifest.split('.m3u8')[0];
                res.write('<div>');
                res.write('<a target ="_blank" href="' + server_address + '/playAt=' + start_time + '">' + start_time + '</a>');
                res.write('</div>');
            });
            res.write('</body></html>');
            res.end();
            return;
        });
    } else if (uri.includes("playAt=")) {
        var manifest_to_play = uri.split('playAt=')[1];
        res.writeHead(200, { 'Content-Type': 'text/html' });
        res.write('<html><head><title>Sentinel Door Levi' +
                '</title></head><body>');
        res.write('<div>');
        res.write('<p>' + manifest_to_play + '</p>');
        res.write('<video src="' + server_address + '/' + manifest_to_play + '.m3u8" controls>');
        res.write('</div>');
        res.write('</body></html>');
        res.end();
        return;
    }

    var filename = path.join("./", uri);
    fs.exists(filename, function (exists) {
        if (!exists) {
            console.log('file not found: ' + filename);
            // XXX: Need to add this fs.exists block as a callback to fs.readdir as that isn't synchronous
            // and results in 'read after write' errors for the res object
            // res.writeHead(404, { 'Content-Type': 'text/plain' });
            // res.write('file not found: ' + filename);
            // res.end();
        } else {
            console.log('sending file: ' + filename);
            switch (path.extname(uri)) {
            case '.m3u8':
                fs.readFile(filename, function (err, contents) {
                    if (err) {
                        res.writeHead(500);
                        res.end();
                    } else if (contents) {
                        res.writeHead(200,
                            {'Content-Type': 'application/vnd.apple.mpegURL'});
                        var ae = req.headers['accept-encoding'];
                        if (ae && ae.match(/\bgzip\b/)) {
                            zlib.gzip(contents, function (err, zip) {
                                if (err) {
                                    throw err;
                                }
                                res.writeHead(200,
                                    {'content-encoding': 'gzip'});
                                res.end(zip);
                            });
                        } else {
                            console.log('No valid accept-encoding sent');
                            res.end(contents, 'utf-8');
                        }
                    } else {
                        console.log('empty playlist');
                        res.writeHead(500);
                        res.end();
                    }
                });
                break;
            case '.ts':
                res.writeHead(200, { 'Content-Type':
                    'video/MP2T' });
                var stream = fs.createReadStream(filename,
                    { bufferSize: 64 * 1024 });
                stream.pipe(res);
                break;
            default:
                console.log('unknown file type: ' +
                    path.extname(uri));
                res.writeHead(500);
                res.end();
            }
        }
    });
}).listen(PORT);
