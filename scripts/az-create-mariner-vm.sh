#!/bin/bash

MARINER_IMAGE_ARM64=MicrosoftCBLMariner:cbl-mariner:cbl-mariner-2-arm64:2.20220527.01
MARINER_IMAGE_X86_64=MicrosoftCBLMariner:cbl-mariner:cbl-mariner-2:latest
LOCATION=westus2
SIZE_ARM64=Standard_D64pds_v5
SIZE_X86_64=Standard_D16d_v4
MARINER_IMAGE=
SIZE=
SSH_KEY_PATH=

USERNAME=`whoami`
RESOURCE_GROUP=$USERNAME-dev-test
TAGS="AzSecPackAutoConfigReady=true owner=$USERNAME"

ARCH=

function showUsage() {
    echo "Usage: az-create-mariner-vm.sh <options>"
    echo "   -a <arch>: List images for specified architecture"
    echo "              arch: { x86_64, arm64}"
    echo "   -n <instance name>"
    echo "   -i <image name>"
    echo "   -k <path to ssh public key>"
    echo "   -s <size>"
    echo "   -l <location>: Azure Location"
    echo "   -r <resource group>: Azure Resource Group to place VM"
    echo "   -s <vm size>: Azure VM Size"
    echo "   -h:        show this help message"
}

optstring="a:i:k:n:l:hr:s:"

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
      MARINER_IMAGE=$OPTARG
      ;;
    k)
      SSH_KEY_PATH=$OPTARG
      ;;
    l)
      LOCATION=$OPTARG
      ;;
    r)
      RESOURCE_GROUP=$OPTARG
      ;;
    s)
      SIZE=$OPTARG
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

if [ -z "$SIZE" ]; then
    case $ARCH in
        x86_64)
            if [ -z "$MARINER_IMAGE" ]; then
                MARINER_IMAGE=$MARINER_IMAGE_X86_64
            fi
            SIZE=$SIZE_X86_64
            ;;
        arm64)
            if [ -z "$MARINER_IMAGE" ]; then
                MARINER_IMAGE=$MARINER_IMAGE_ARM64
            fi
            SIZE=$SIZE_ARM64
            ;;
        *)
            echo "Error: Invalid architecture specified - [$ARCH]"
            showUsage
            exit 2
    esac
fi

if [ -z "$SSH_KEY_PATH" ]; then
  SSH_KEY_PATH="~/.ssh/id_rsa_azure.pub"
fi

if [ -z "$MARINER_IMAGE" ]; then
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
	--image $MARINER_IMAGE \
	--os-disk-size-gb 60 \
	--size $SIZE \
	--public-ip-sku Standard \
	--admin-username $USERNAME \
	--assign-identity [system] \
	--ssh-key-values "$SSH_KEY_PATH" \
	--tags $TAGS \
	--location $LOCATION
