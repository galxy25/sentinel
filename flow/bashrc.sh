alias vim=vi
export PATH=/home/root/bin:$PATH

function kill_hls_server {
echo "Attempting to kill all hls-server.js executions"
echo "Currently running executions: "
ps | grep '[h]ls-server.js'
ps | grep '[h]ls-server.js' | awk '{ print $1 }' | xargs kill -2
echo "Currently running executions: "
ps | grep '[h]ls-server.js'
}

function bg_hls_server {
nohup node /home/root/hls-server.js > /dev/null 2>&1&
}

function restart_hls_server {
kill_hls_server
bg_hls_server
}

function bg_door_record {
echo "Backgrounding: "
echo "Sentinel T-5 Door edi-cam"
nohup /home/root/bin/ffmpeg -r 30 -s 320x240 -f video4linux2 -i /dev/video0 \
-c:v mpeg1video \
-acodec aac \
-r 30 \
-hls_list_size 50 \
-hls_time 6 \
-use_localtime 1 \
-hls_segment_filename 'door-%Y%m%d-%s.ts' \
-hls_flags delete_segments \
-master_pl_name master.m3u8 \
out.m3u8 > /dev/null 2>&1&
}

function grace_kill_hls_ffmpeg {
echo "Attempting to kill all hls ffmpeg processes"
echo "Currently running executions: "
ps | grep ffmpeg | grep hls | awk '{ print $1 }'
ps | grep ffmpeg | grep hls | awk '{ print $1 }' | xargs kill -2
sleep 2s
echo "Currently running executions: "
ps | grep ffmpeg | grep hls | awk '{ print $1 }'
}

function restart_door_record {
grace_kill_hls_ffmpeg
bg_door_record
}

function bg_door_live {
echo "Backgrounding: "
echo "Sentinel Door Live"
nohup /home/root/sentinel/sentinel > /dev/null 2>&1&
echo "Sentinel Door Capture"
nohup /home/root/sentinel/do_ffmpeg.sh > /dev/null 2>&1&
}

function grace_kill_door_live {
echo "Attempting to kill all sentinel server and flow executions"
echo "Currently running executions: "
ps | grep '[d]o_ffmpeg.sh'
ps | grep '[s]entinel'
ps | grep '[d]o_ffmpeg.sh' | awk '{ print $1 }' | xargs kill -2
ps | grep '[s]entinel' | awk '{ print $1 }' | xargs kill -2
echo "Currently running executions: "
ps | grep '[d]o_ffmpeg.sh'
ps | grep '[s]entinel'
}

function restart_door_live_view {
grace_kill_door_live
bg_door_live
}

function mp4ize_door_live_stream {
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
  "$1".mp4
}

function hlsize_mp4 {
  /home/root/bin/ffmpeg -r 30 -f mp4 -i $1 \
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
  -hls_segment_filename 'door-%Y%m%d-%s.ts' \
  -master_pl_name "$1.m3u8" \
  "$1-out".m3u8
}

function kill_vod_pipe() {
echo "Attempting to kill all vod-pipe.sh executions"
echo "Currently running executions: "
ps | grep '[v]od-pipe.sh'
ps | grep '[v]od-pipe.sh' | awk '{ print $1 }' | xargs kill -9
echo "Currently running vod-pipe.sh executions: "
ps | grep '[v]od-pipe.sh'
}

function kill_vod_flow() {
echo "Attempting to kill all vod-pipe.sh ffmpeg executions"
echo "Currently running executions: "
ps | grep '[f]fmpeg -r 30 -f mpegvideo -i udp://localhost:2001'
ps | grep '[f]fmpeg -r 30 -f mpegvideo -i udp://localhost:2001' | awk '{ print $1 }' | xargs kill -9
echo "Currently running vod-pipe.sh ffmpeg executions: "
ps | grep '[f]fmpeg -r 30 -f mpegvideo -i udp://localhost:2001'
}

function bg_vod_pipe() {
nohup /home/root/vod-pipe.sh > /dev/null 2>&1&
}

function restart_vod_pipe() {
kill_vod_pipe
kill_vod_flow
bg_vod_pipe
}
