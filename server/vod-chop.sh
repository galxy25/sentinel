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
