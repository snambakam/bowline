#!/bin/bash

MARINER_IMAGE_ARM64=MicrosoftCBLMariner:cbl-mariner:cbl-mariner-2-arm64:2.20220527.01
MARINER_IMAGE_X86_64=MicrosoftCBLMariner:cbl-mariner:cbl-mariner-2:latest
LOCATION=westus2
SIZE=Standard_D16darm_V3
MARINER_IMAGE=

USERNAME=`whoami`
RESOURCE_GROUP=$USERNAME-dev-test

ARCH=

function showUsage() {
    echo "Usage: az-list-mariner-images.sh <options>"
    echo "   -a <arch>: List images for specified architecture"
    echo "              arch: { x86_64, arm64}"
    echo "   -r <resource group>: Azure Resource Group to place VM"
    echo "   -h:        show this help message"
}

optstring="ar:h"

while getopts ${optstring} arg; do
  case ${arg} in
    h)
      showUsage
      exit 0
      ;;
    a)
      ARCH=$OPTARG
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

INSTANCE_NAME=${!#}

if [ -z "$RESOURCE_GROUP" ]; then
    echo "Error: Invalid resource group specified - [$RESOURCE_GROUP]"
    showUsage
    exit 1
fi

case $ARCH in
    x86_64)
        MARINER_IMAGE=$MARINER_IMAGE_X86_64
        ;;
    arm64)
        MARINER_IMAGE=$MARINER_IMAGE_ARM64
        ;;
    *)
        echo "Error: Invalid architecture specified - [$ARCH]"
        showUsage
        exit 2
esac

if [ -z "$INSTANCE_NAME"]; then
    echo "Error: Invalid instance name specified - [$INSTANCE_NAME"
    showUsage
    exit 3
fi

az vm create \
	--resource-group $RESOURCE_GROUP \
	--name $INSTANCE_NAME \
	--image $MARINER_IMAGE \
	--os-disk-size-gb 60 \
	--size $SIZE \
	--public-ip-sku Standard \
	--admin-username $USERNAME \
	--assign-identity [system] \
	--ssh-key-values ~/.ssh/id_rsa_azure.pub \
	--location $LOCATION
