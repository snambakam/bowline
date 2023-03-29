#!/bin/bash

UBUNTU_IMAGE_ARM64=Canonical:0001-com-ubuntu-server-jammy:22_04-lts-arm64:22.04.202209211
UBUNTU_IMAGE_X86_64=UbuntuLTS
LOCATION=westus2
SIZE_ARM64=Standard_D16darm_V3
SIZE_X86_64=Standard_D16d_v4
UBUNTU_IMAGE=
SIZE=

USERNAME=`whoami`
RESOURCE_GROUP=$USERNAME-dev-test
TAGS="AzSecPackAutoConfigReady=true owner=$USERNAME"

ARCH=

function showUsage() {
    echo "Usage: az-create-ubuntu-vm.sh <options>"
    echo "   -a <arch>: List images for specified architecture"
    echo "              arch: { x86_64, arm64}"
    echo "   -n <instance name>"
    echo "   -i <image name>"
    echo "   -l <location>: Azure Location"
    echo "   -r <resource group>: Azure Resource Group to place VM"
    echo "   -h:        show this help message"
}

optstring="a:i:n:l:hr:"

while getopts ${optstring} arg; do
  case ${arg} in
    h)
      showUsage
      exit 0
      ;;
    a)
      ARCH=$OPTARG
      ;;
    n)
      INSTANCE_NAME=$OPTARG
      ;;
    i)
      UBUNTU_IMAGE=$OPTARG
      ;;
    l)
      LOCATION=$OPTARG
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

if [ -z "$RESOURCE_GROUP" ]; then
    echo "Error: Invalid resource group specified - [$RESOURCE_GROUP]"
    showUsage
    exit 1
fi

if [ -z "$LOCATION" ]; then
    echo "Error: Invalid location specified - [$LOCATION]"
    showUsage
    exit 1
fi

case $ARCH in
    x86_64)
        if [ -z "$UBUNTU_IMAGE" ]; then
            UBUNTU_IMAGE=$UBUNTU_IMAGE_X86_64
        fi
        SIZE=$SIZE_X86_64
        ;;
    arm64)
        if [ -z "$UBUNTU_IMAGE" ]; then
            UBUNTU_IMAGE=$UBUNTU_IMAGE_ARM64
        fi
        SIZE=$SIZE_ARM64
        ;;
    *)
        echo "Error: Invalid architecture specified - [$ARCH]"
        showUsage
        exit 2
esac

if [ -z "$UBUNTU_IMAGE" ]; then
    echo "Error: Invalid image specified - [$MARINER_IMAGE]"
    exit 4
fi

if [ -z "$INSTANCE_NAME" ]; then
    echo "Error: Invalid instance name specified - [$INSTANCE_NAME]"
    showUsage
    exit 3
fi

az vm create \
	--resource-group $RESOURCE_GROUP \
	--name $INSTANCE_NAME \
	--image $UBUNTU_IMAGE \
	--os-disk-size-gb 60 \
	--size $SIZE \
	--public-ip-sku Standard \
	--admin-username $USERNAME \
	--assign-identity [system] \
	--ssh-key-values ~/.ssh/id_rsa_azure.pub \
	--tags $TAGS \
	--location $LOCATION
