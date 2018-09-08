alias vim=vi
export PATH=/home/root/bin:$PATH

function bg_door_live {
  echo "Backgrounding Sentinel Door Live"
  pushd /home/root/sentinel
  nohup /home/root/sentinel/sentinel > sentine.out 2>&1&
  echo "Sentinel Door Capture"
  nohup /home/root/sentinel/do_ffmpeg.sh > /dev/null 2>&1&
  popd
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
  nohup /home/root/vod-pipe.sh > vod_pipe.out 2>&1&
}

function restart_vod_pipe() {
  kill_vod_pipe
  kill_vod_flow
  bg_vod_pipe
}
