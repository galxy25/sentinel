// Package main runs the sentinel web server
// for ingesting, and broadcasting
// Levi's home security camera(s).
// Heavily inspired by
// https://github.com/drejkim/edi-cam/blob/master/web/server/server.js
// https://github.com/wangdxh/websocketvideostream/blob/master/main.go
// https://github.com/farisais/online-videostream-processing/blob/master/http/server.go
package main

import (
	"bufio"
	"crypto/tls"
	"fmt"
	"github.com/gorilla/websocket"
	"golang.org/x/crypto/acme/autocert"
	"io"
	"log"
	"net/http"
	"time"
)

// options to use when upgrading an http(s)
// connection to a websocket
var upgrader = websocket.Upgrader{
	ReadBufferSize:  1024,
	WriteBufferSize: 1024,
	CheckOrigin:     func(r *http.Request) bool { return true }, //TODO: only upgrade requests originating from the current host
}

// viewer implements functionality for a client to
// view sentinel content
type viewer struct {
	conn *websocket.Conn
}

// current list of viewers for sentinel content
var viewers = make(map[string]*viewer)

// ingress handles the ingestion (inputing) of sentinel content.
func ingress(w http.ResponseWriter, r *http.Request) {
	var ingested int
	reader := bufio.NewReader(r.Body)
	buf := make([]byte, 0, 40*1024)
	var err error
	for {
		ingested, err = reader.Read(buf[:cap(buf)])
		if ingested > cap(buf) {
			log.Println("Buffer overflow")
		}
		buf = buf[:ingested]
		_ = broadcast(buf)
		if ingested == 0 {
			if err == nil {
				continue
			}
			if err == io.EOF {
				log.Println("end of stream")
				break
			}
			log.Println(err)
		}
		if err != nil && err != io.EOF {
			log.Println(err)
		}
	}
}

// egress handles requests and setup for egressing (outputting)
// of sentinel content.
func egress(w http.ResponseWriter, r *http.Request) {
	conn, err := upgrader.Upgrade(w, r, nil)
	defer conn.Close()
	if err != nil {
		log.Println(err)
		return
	}
	viewerID := fmt.Sprintf("%v@%v", r.RemoteAddr, time.Now().Unix())
	viewer := &viewer{
		conn: conn,
	}
	// from web/js/jsmpg.js     jsmpeg.prototype.decodeSocketHeader = function( data ) {
	//     // Custom header sent to all newly connected clients when streaming
	//     // over websockets:
	//     // struct { char magic[4] = "jsmp"; unsigned short width, height; };
	//     if(
	//         data[0] == SOCKET_MAGIC_BYTES.charCodeAt(0) &&
	//         data[1] == SOCKET_MAGIC_BYTES.charCodeAt(1) &&
	//         data[2] == SOCKET_MAGIC_BYTES.charCodeAt(2) &&
	//         data[3] == SOCKET_MAGIC_BYTES.charCodeAt(3)
	//     ) {
	//         this.width = (data[4] * 256 + data[5]);
	//         this.height = (data[6] * 256 + data[7]);
	//         this.initBuffers();
	//     }
	// };
	startSequence := []byte{
		'j',
		's',
		'm',
		'p',
		0x01,
		0x40, // height: 640
		0x0,
		0xf0, // width: 240
	}
	err = conn.WriteMessage(websocket.BinaryMessage, startSequence)
	if err != nil {
		log.Println(err)
		return
	}
	viewers[viewerID] = viewer
	defer delete(viewers, viewerID)
	for {
		err = conn.WriteControl(websocket.PingMessage, []byte{}, time.Now().Add(time.Second))
		if err != nil {
			log.Println(err)
			break
		}
		time.Sleep(500 * time.Millisecond)
	}
}

// broadcast broadcasts the provided data to all current
// sentinel viewers, returning array of errors (if any).
func broadcast(data []byte) (errs []error) {
	var err error
	for id, viewer := range viewers {
		err = viewer.conn.WriteMessage(websocket.BinaryMessage, data)
		if err != nil {
			log.Printf("error broadcasting to %v %v\n", id, err)
			errs = append(errs, err)
		}
	}
	return errs
}

func main() {
	manta := http.NewServeMux()
	httpd := http.NewServeMux()
	ray := http.NewServeMux()
	// Serve web client code
	httpd.Handle("/", http.FileServer(http.Dir("./web")))
	// Handle incoming video
	manta.HandleFunc("/", ingress)
	go http.ListenAndServe(":9001", manta)
	// Set up automatic X.509 certificate management
	// via Lets Encrypt.
	certManager := autocert.Manager{
		Prompt:     autocert.AcceptTOS,
		Cache:      autocert.DirCache("tls"),
		HostPolicy: autocert.HostWhitelist("sentinel.levi.casa", "local.sentinel.levi.casa"),
	}
	rayServer := &http.Server{
		Addr:    ":9002",
		Handler: ray,
		TLSConfig: &tls.Config{
			GetCertificate: certManager.GetCertificate,
		},
	}
	// Handle video broadcast subscribers
	ray.HandleFunc("/", egress)
	// Run http server to respond to ACME http-01 challenges
	go http.ListenAndServe(":80", certManager.HTTPHandler(nil))
	go rayServer.ListenAndServeTLS("", "")
	webServer := &http.Server{
		Addr:    ":9000",
		Handler: httpd,
		TLSConfig: &tls.Config{
			GetCertificate: certManager.GetCertificate,
		},
	}
	err := webServer.ListenAndServeTLS("", "")
	if err != nil {
		log.Fatal(err)
	}
}
