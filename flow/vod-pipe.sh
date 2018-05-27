#!/bin/bash
# Record, upload and delete
# 30 minute segments
# of a live stream
while true; do
  current_start_time="$(date +%F-%H-%M)"
  echo "Recording live stream starting at $current_start_time"
  /home/root/bin/ffmpeg -r 30 -f mpegvideo -i udp://localhost:2001 \
    -movflags faststart \
    -keyint_min 30 \
    -x264opts "keyint=30:min-keyint=30:no-scenecut" \
    -g 30 \
    -r:v 30 \
    -c:v libx264 \
    -pix_fmt yuv420p \
    -profile:v main \
    -level 3.1 \
    -c:a aac \
    -ar 48000 \
    -b:a 128k \
    "$current_start_time.mp4" > /dev/null 2>&1&
  live_stream_recording_pid=$!
  sleep 900
  kill -2 $live_stream_recording_pid
  sleep 2
  previous_start_time="$current_start_time"
  echo "Background uploading live stream recording from $previous_start_time to sentinel.cloud"
  ls *.mp4
  touch "$previous_start_time.lockfile"
  (echo "Two phase upload in progress" \
    && sshpass -p  "XXX" scp "$previous_start_time.lockfile" root@167.99.109.131:/root/ \
    && sshpass -p  "XXX" scp "$previous_start_time.mp4" root@167.99.109.131:/root/ \
    && sshpass -p  "XXX" ssh root@167.99.109.131 "rm $previous_start_time.lockfile" \
    && rm "$previous_start_time.mp4" \
    && rm "$previous_start_time.lockfile") &
done
