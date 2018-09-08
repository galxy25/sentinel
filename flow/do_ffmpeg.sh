#!/bin/sh
/home/root/bin/ffmpeg -r 30 -s 320x240 -f video4linux2 -i /dev/video0 \
-r 30 \
-c:v mpeg1video \
-f tee \
-map 0:v "[f=mpeg1video]udp://127.0.0.1:2001|[f=mpeg1video]http://127.0.0.1:9001"
