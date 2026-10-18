.PHONY: run test test-race build clean

run:
	CONFIG_PATH=config.json go run ./cmd/server

test:
	go test -v ./...

test-race:
	go test -v -race ./...

build:
	CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o bubble-server ./cmd/server

clean:
	rm -f bubble-server coverage.txt
