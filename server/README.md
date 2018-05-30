# Sentinel Server Service
Segmenting, Serving, and Sweeping recorded video

## Goals
    List the actors in the story of the Sentinel server service.
## Non-Goals
    1,2,3 Step by step (instructions/install script/one click static binary) => $
## Pre-requisites
    Public IP addressable server with public Internet connectivity
    'puter
## Instructions
    1. Gate
        * Allow ssh access to "cloud" server from Sentinel flow service network
        * Allow outbound connections on port 8000
        * Add functions in ./bashrc.sh to ~/.bashrc
    2. Fertilize
        * Upload ./vod-chop.sh, ./vod-sweep.sh, ./hls-server.js
        * $> cat export HOST_IP=PUBLIC_IP_OF_THE_HOST > ~/.bashrc
        * $> sudo add-apt-repository ppa:jonathonf/ffmpeg-4
        * $> sudo apt-get update
        * $> sudo apt-get install ffmpeg
    3. Grow
        * $> bg_vod_chop
        * $> bg_hls_server
    4. Harvest
        * http://HOSTNAME:8000/player.html
    5. Prune
        *
        ```
        #write out current crontab
        crontab -l > mycron
        #echo new cron into cron file
        echo "@daily /root/vod-sweep.sh" >> mycron
        #install new cron file
        crontab mycron
        rm mycron
        ```
## Errata
