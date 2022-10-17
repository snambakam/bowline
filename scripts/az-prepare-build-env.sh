#!/bin/bash

sudo tdnf install -y \
	bison \
	build-essential \
	cdrkit \
	curl \
	fakeroot \
	gawk \
	git \
	golang \
	make \
	moby-cli \
	moby-containerd \
	moby-engine \
	moby-runc \
	parted \
	pigz \
	rpm \
	rpmdevtools \
	tar \
	vim \
	wget

sudo usermod -aG docker $USER

echo "Info: Re-login to session or reboot the system"
