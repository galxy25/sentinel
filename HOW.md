#Just The Juicy Bits

##Create Flow

Run the command below on the IOT server to capture and create two copies of the stream for the live and vod playout pipelines.
```
#!/bin/sh
/home/root/bin/ffmpeg -r 30 -s 320x240 -f video4linux2 -i /dev/video0 \
-r 30 \
-c:v mpeg1video \
-f tee \
-map 0:v "[f=mpeg1video]udp://127.0.0.1:2001|[f=mpeg1video]http://127.0.0.1:9002" > /dev/null
```
##Serve Flow
On the IOT server the flow is served by a web server, the vod playout occurs via a remote computer. The command below takes on of the web cam stream copies and transcodes it to h264 in an mp4 container for eventual HLS playout. Then it uploads this file to the remote server, and garbage collects the file once the upload to the remote server is complete.
```
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
  echo "Two phase upload in progress" \
    && sshpass -p  "XXX" scp "$previous_start_time.lockfile" root@167.99.109.131:/root/ \
    && sshpass -p  "XXX" scp "$previous_start_time.mp4" root@167.99.109.131:/root/ \
    && sshpass -p  "XXX" ssh root@167.99.109.131 "rm $previous_start_time.lockfile" \
    && rm "$previous_start_time.mp4" \
    && rm "$previous_start_time.lockfile"
done
```
##Chop Flow
On the remote server, the HLS assets-.ts segments, and HLS manefist and playlist are created as new mp4 files are discovered.
```
#!/bin/bash
# set -x
# set -e
function list_pick_lock_segment_sweep_it() {
    while true; do
        sleep .$[ ( $RANDOM % 10 ) + 1 ]
        echo "Looping looking for an mp4 file to lock"
        #Pick a random mp4 video prefix/recorded_at timestamp to try and segment
        video_start_timestamp=$(ls *.mp4 | sed s/.mp4// | xargs shuf -n 1 -e)
        echo "Selected random mp4: $video_start_timestamp.mp4"
        if [ -n "$video_start_timestamp" ];
        then
            if [ -z $(ls -t *.lockfile | sed s/.lockfile// | grep $video_start_timestamp) ];
            then
                #Lock it
                touch "$video_start_timestamp.lockfile"
                echo "Lot'sa Dice, rolled a six, locking $video_start_timestamp.mp4 for segmenting"
                break
            else
                #Try again
                echo "No Dice, someone else has this file, looping again to grab another one"
            fi
        else
            #Loop again
            echo "No mp4 files found to lock"
        fi
    done
    #Segment it
    echo "Segmenting $video_start_timestamp.mp4 live recording for hls playout"
    ffmpeg -r 30 -f mp4 -i "$video_start_timestamp.mp4" \
        -c:v h264 \
        -c:a aac \
        -ar 48000 \
        -b:a 128k \
        -profile:v main \
        -level 3.1 \
        -r 30 \
        -b:v 400k \
        -hls_playlist_type vod \
        -hls_time 6 \
        -use_localtime 1 \
        -hls_segment_filename "$video_start_timestamp-door-%s.ts" \
        -master_pl_name "$video_start_timestamp.m3u8" \
        "$video_start_timestamp-out.m3u8" 2>&1 | logger
    #Sweep it
    rm "$video_start_timestamp.mp4"
    rm "$video_start_timestamp.lockfile"
}

while true; do
    (list_pick_lock_segment_sweep_it) &
    (list_pick_lock_segment_sweep_it) &
    (list_pick_lock_segment_sweep_it) &
    wait
done
```
##Clean Flow
The script below is run daily as part of a crontab configured as detailed in ./server/README.md
and deletes any HLS files older than 7 days.
```
#!/bin/bash
find /root -type f -mmin +10080 | grep -E '*.ts|*.m3u8|*.mp4|*.lockfile' | xargs rm
touch /root/vod-sweep.check
```
