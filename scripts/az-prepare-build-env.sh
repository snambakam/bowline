#!/bin/bash

sudo tdnf install -y \
	bison \
	cdrkit \
	curl \
	gawk \
	git \
	golang \
	make \
	moby-containerd \
	moby-engine \
	moby-runc \
	parted \
	pigz \
	rpm \
	tar \
	wget

sudo usermod -aG docker $USER
