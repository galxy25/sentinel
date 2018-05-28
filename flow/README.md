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
    'puter

## Instructions
    1. Till
        * Follow instructions https://software.intel.com/en-us/flashing-the-firmware-on-intel-edison-board using files in ./edison-image-ww25
    2. Plant
        *Follow README.md instructions in edi-cam/README.md with the following modifications:
            ** Use the opkg sources in ./base-feeds.conf
            ** If ffmpeg mirror is unresponsive, use  **./ffmpeg-release-32bit-static.tar.xz
    3. Water
        * Upload ./vod-pipe.sh
        * Replace values of XXX in vod-pipe.sh with remote Sentinel server's password or pointer to file containing password
        * $> bg_door_live
          $> bg_vod_pipe
    4. Farm
        * Go to localhost:8080 and view flow.
    5. Share(Optional)
        * Setup port forwarding to allow off home WI-FI network access to live stream using configuration in ./SentinelWebFording.png and ./SentinelWebSocketForwarding.png
## Errata
