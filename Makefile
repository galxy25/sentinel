include Envfile
export $(shell sed 's/=.*//' Envfile)
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
ifneq ($(SENTINEL_PASSWORD),)
	echo "Cross compiling for intel edison and local architecture"
	cd $(PACKAGE_DIR)/$(ROOT_PACKAGE); \
		GOARCH=386 GOOS=linux go install -ldflags "-X main.streamPassword=$$SENTINEL_PASSWORD"; \
		go install -ldflags "-X main.streamPassword=$$SENTINEL_PASSWORD"
		# https://stackoverflow.com/questions/28459102/golang-compile-environment-variable-into-binary
else
	echo "SENTINEL_PASSWORD can not be empty"
endif

deploy: build
	scp -r web SentinelLocal:~/sentinel/
	scp flow/do_ffmpeg.sh SentinelLocal:~/sentinel
	scp flow/vod-pipe.sh SentinelLocal:~/
	scp bin/linux_386/sentinel SentinelLocal:~/sentinel

clean:
	rm -rf bin/linux_386
	rm -f bin/sentinel
	cd $(PACKAGE_DIR)/$(ROOT_PACKAGE); \
		go clean ../...
