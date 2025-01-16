#!/bin/bash

function showUsage() {
    echo "Usage: az-create-ubuntu-vm.sh <options>"
    echo "   -a <arch>: List images for specified architecture"
    echo "              arch: { x86_64, arm64}"
    echo "   -n <instance name>"
    echo "   -i <image name>"
    echo "   -l <location>: Azure Location"
    echo "   -r <resource group>: Azure Resource Group to place VM"
    echo "   -s <size>: Azure VM Size"
    echo "   -h:        show this help message"
}

optstring="n:hr:"

while getopts ${optstring} arg; do
  case ${arg} in
    h)
      showUsage
      exit 0
      ;;
    n)
      INSTANCE_NAME=$OPTARG
      ;;
    r)
      RESOURCE_GROUP=$OPTARG
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

if [ -z "$INSTANCE_NAME" ]; then
     echo "Error: must specify VM instance name"
     exit 1
fi

if [ -z "$RESOURCE_GROUP" ]; then
     echo "Error: must specify resource group"
     exit 1
fi

az vm extension set \
     --publisher Microsoft.Azure.ActiveDirectory \
     --name AADSSHLoginForLinux \
     --resource-group $RESOURCE_GROUP \
     --vm-name $INSTANCE_NAME
