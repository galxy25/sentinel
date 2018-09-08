PACKAGE_DIR=src
ROOT_PACKAGE=github.com/galxy25/sentinel
GOPATH=$(PWD)
export GOPATH=$(PWD)

.PHONY: lint install build deploy clean

lint:
	cd $(PACKAGE_DIR)/$(ROOT_PACKAGE); \
		go fmt ../...; \
		go vet ../...;

install:
	cd $(PACKAGE_DIR)/$(ROOT_PACKAGE); \
		dep ensure; \
		go get;

build: lint
	echo "Cross compiling for intel edison and local architecture"
	cd $(PACKAGE_DIR)/$(ROOT_PACKAGE); \
		GOARCH=386 GOOS=linux go install; \
		go install

deploy: build
	scp bin/linux_386/sentinel SentinelLocal:~/sentinel
	scp -r web SentinelLocal:~/sentinel/
	scp flow/do_ffmpeg.sh SentinelLocal:~/sentinel
	scp flow/vod-pipe.sh SentinelLocal:~/

clean:
	rm -rf bin/linux_386
	rm -f bin/sentinel
	cd $(PACKAGE_DIR)/$(ROOT_PACKAGE); \
		go clean ../...
