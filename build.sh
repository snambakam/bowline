#!/bin/bash

set -e

MARINER_RELEASE_TAG=2.0-stable
SRC_ROOT=`pwd`
OUT_DIR=$SRC_ROOT/out
BOWLINE_LOG_LEVEL=info

trap cleanup EXIT

function cleanup() {
	if [ -d CBL-Mariner ]; then
		sudo rm -rf CBL-Mariner
	fi
}

function getToolkit() {
	echo "Building the Mariner toolkit..."
  if [ ! -d toolkit ]; then
		if [ ! -d CBL-Mariner ]; then
			git clone \
				--branch ${MARINER_RELEASE_TAG} \
				--depth 1 \
				https://github.com/microsoft/CBL-Mariner.git
		fi
		sudo make \
			-C CBL-Mariner/toolkit \
			package-toolkit \
			REBUILD_TOOLS=y \
			OUT_DIR=$OUT_DIR && \
			rm -rf toolkit && \
			tar -xzvf ${OUT_DIR}/toolkit-*.tar.gz -C "${SRC_ROOT}"
	fi
}

function buildPackages() {
	echo "Building the Bowline packages..."
	getToolkit
	pushd $SRC_ROOT/toolkit
	sudo make -j$(nproc) build-packages \
		CONFIG_FILE= \
		SPECS_DIR=../SPECS \
		OUT_DIR=$OUT_DIR \
		REBUILD_TOOLS=y \
		PACKAGE_REBUILD_LIST="$@" \
		PACKAGE_BUILD_LIST="$@" \
		SOURCE_URL=https://cblmarinerstorage.blob.core.windows.net/sources/core \
		USE_PREVIEW_REPO=n \
		SRPM_FILE_SIGNATURE_HANDLING=update \
		LOG_LEVEL=$BOWLINE_LOG_LEVEL
	popd
}

function buildImage() {
	echo "Building the Bowline images..."
	getToolkit
	pushd $SRC_ROOT/toolkit
	sudo make iso \
  	REBUILD_PACKAGES=n \
  	REBUILD_TOOLS=y \
  	CONFIG_FILE=../images/bowline-iso.json \
  	USE_PREVIEW_REPO=n \
  	LOG_LEVEL=$BOWLINE_LOG_LEVEL
	popd
}

function showUsage() {
	echo "build.sh [-p][-i][-t][-h]"
	echo "  [-h]: Show this help message"
	echo "  [-t]: Build the toolkit"
	echo "  [-i]: Build the image"
	echo "  [-p]:	Build the packages"
}

while getopts "hipt" OPTIONS; do
  case "${OPTIONS}" in
    h )
			showUsage
			exit 0
			;;
		i )
			buildImage
			;;
		p )
			buildPackages
			;;
		t )
			getToolkit
			;;
    \? )
        echo "-- Error - Invalid Option: -$OPTARG" 1>&2
        exit 1
        ;;
    : )
        echo "-- Error - Invalid Option: -$OPTARG requires an argument" 1>&2
        exit 1
        ;;
  esac
done
