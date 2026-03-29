PHONY: build

build: Dockerfile
	docker build ./ -t cryptopro
