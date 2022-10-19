#!/bin/bash

set -ex

function cleanup() {
    echo "Cleaning up..."
    rm -f /tmp/get-docker.sh
}

trap cleanup EXIT

sudo add-apt-repository ppa:longsleep/golang-backports
sudo apt-get update

sudo apt -y install \
	bison \
	curl \
	genisoimage \
	gawk \
	git \
	golang-1.17-go \
	make \
	parted \
	pigz \
	python3-minimal \
	rpm \
	tar \
	wget

sudo ln -vsf /usr/lib/go-1.17/bin/go /usr/bin/go

curl -fsSL https://get.docker.com -o /tmp/get-docker.sh
sudo sh /tmp/get-docker.sh
sudo usermod -aG docker $USER
