# Sentinel Flow Service
    Capturing live video input and transcoding it for live and VOD playout.

## Goals
    List the actors in the story of the Sentinel flow service.

## Non-Goals
    1,2,3 Step by step (instructions/install script/one click static binary) => $

## Pre-requisites
    Wifi
    AC power outlet
    Intel Edison with IOT board(Arduino/Intel Breakout)
    USB UVC compatible camera
    2x Micro-usb cables
    developer machine
    domain (this README assumes control of levi.casa)
    golang 1.11 installed on developer machine

## Instructions
    1. Home Base
        * Follow instructions https://software.intel.com/en-us/flashing-the-firmware-on-intel-edison-board using files in ./edison-image-ww25
        * Plug in usb camera
    2. Seeds
        * Unzip the ffmpeg archive to /home/root/bin
        * Add functions in ./bashrc.sh to the edison's bashrc and source the augmented bashrc.
        * Upload ./vod-pipe.sh to home/root
        * Create directory home/root/sentinel
            ** Upload do_ffmpeg.sh to home/root/sentinel
            ** run make install && make deploy to build and copy over sentinel service to intel edison
    3. River
        * Replace values of XXX in vod-pipe.sh with remote Sentinel server's password or pointer to file containing password
        * Launch live stream and vod pipelines
            ** $> bg_door_live
            ** $> bg_vod_pipe
    4. Dam
        * Update local DNS to route local.sentinel.levi.casa to 10.0.0.XXX
        * Update/add remote DNS records for local.sentinel.levi.casa and sentinel.levi.casa to point to the public ip address of your wi-fi router
        * Setup port forwarding to allow for
            ** obtaining ssl certificates
                *** forward port 80 http from the intel edison
            ** serving web page
                *** forward port 9000 http
            ** broadcasting sentinel content over websockets
                *** forward port 9002
    5. Harvest
        * Go to https://local.sentinel.levi.casa:9000 and view flow.

## Errata
