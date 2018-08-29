#!/bin/bash
find /root -type f -mmin +10080 | grep -E '*.lockfile|*.ts|*.m3u8|*.mp4' | xargs rm
touch /root/vod-sweep.check
