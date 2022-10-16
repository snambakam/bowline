#!/bin/bash

LOCATION=westus

function showUsage() {
    echo "Usage: az-list-vm-sizes.sh <options>"
    echo "   -l <location>: Azure Location (westus, eastus etc.)"
    echo "   -h:        show this help message"
}

optstring="l:h"

while getopts ${optstring} arg; do
  case ${arg} in
    h)
      showUsage
      exit 0
      ;;
    l)
      LOCATION=$OPTARG
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

if [ -z "$LOCATION" ]; then
    echo "Error: Invalid location specified - [$LOCATION]"
    showUsage
    exit 1
fi

az vm list-sizes --location $LOCATION
