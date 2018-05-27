export HOST_IP=167.99.109.131

function kill_hls_server() {
    echo "Killing  all hls-server.js instances"
    ps -ax | grep "[h]ls-server.js"
    ps -ax | grep "[h]ls-server.js" | awk '{ print $1 }' | xargs kill -9
    echo "Currently running hls-server.js instances"
    ps -ax | grep "[h]ls-server.js"
}

function bg_hls_server() {
    echo "Backgrounding hls-server.js"
    nohup node /root/hls-server.js 2>&1 | logger &
}

function restart_hls_server() {
    kill_hls_server
    bg_hls_server
}

function kill_vod_chop() {
    echo "Killing  all vod-chop.sh instances"
    ps -ae | grep [v]od-chop.sh
    ps -ae | grep [v]od-chop.sh | awk '{ print $1 }' | xargs kill -9
    echo "Currently running vod-chop.sh instances"
    ps -ae | grep [v]od-chop.sh
    echo "Killing  all vod-chop.sh ffmpeg instances"
    ps -ae | grep [f]fmpeg
    ps -ae | grep [f]fmpeg | awk '{ print $1 }' | xargs kill -9
    echo "Currently running vod-chop.sh ffmpeg instances"
    ps -ae | grep [f]fmpeg
}

function bg_vod_chop() {
    echo "Backgrounding vod-chop"
    nohup /root/vod-chop.sh 2>&1 | logger &
}

function restart_vod_chop() {
    kill_vod_chop
    bg_vod_chop
}
