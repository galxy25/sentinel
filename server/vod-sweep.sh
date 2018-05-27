#!/bin/bash
find /root -type f -mmin +10080 | grep -E '*.ts|*.m3u8' | xargs rm
touch /root/vod-sweep.check
