#!/bin/bash

ARCH=

function showUsage() {
    echo "Usage: az-list-mariner-images.sh <options>"
    echo "   -a <arch>: List images for specified architecture"
    echo "              arch: { x86_64, arm64}"
    echo "   -h:        show this help message"
}

optstring="a:h"

while getopts ${optstring} arg; do
  case ${arg} in
    h)
      showUsage
      exit 0
      ;;
    a)
      ARCH=$OPTARG  
      ;;
    :)
      echo "$0: Must supply an argument to -$OPTARG." >&2
      exit 1
      ;;
    ?)
      echo "Invalid option: -${OPTARG}."
      exit 2
      ;;
  esac
done

OPTIONAL_ARGS=

if [ ! -z "$ARCH" ]; then
    OPTIONAL_ARGS="$OPTIONAL_ARGS --architecture $ARCH"
fi

az vm image list \
    --all \
    --publisher MicrosoftCBLMariner \
    $OPTIONAL_ARGS