#!/bin/bash

MARINER_IMAGE_ARM64=MicrosoftCBLMariner:azure-linux-3:azure-linux-3-arm64-gen2-acl:latest
MARINER_IMAGE_X86_64=MicrosoftCBLMariner:azure-linux-3:azure-linux-3-acl:latest
LOCATION=westus2
SIZE_ARM64=Standard_D2ps_v5
SIZE_X86_64=Standard_DS1_v2
MARINER_IMAGE=
SIZE=
SSH_KEY_PATH=
ZONE=

USERNAME=`whoami`
RESOURCE_GROUP=$USERNAME-dev-test
TAGS="AzSecPackAutoConfigReady=true owner=$USERNAME"

ARCH=

function showUsage() {
    echo "Usage: $0 <options>"
    echo "   -a <arch>: List images for specified architecture"
    echo "              arch: { x86_64, arm64}"
    echo "   -n <instance name>"
    echo "   -i <image name>"
    echo "   -k <path to ssh public key>"
    echo "   -s <size>"
    echo "   -l <location>: Azure Location"
    echo "   -z <zone>: Availability Zone (for example: 1, 2, or 3)"
    echo "   -r <resource group>: Azure Resource Group to place VM"
    echo "   -s <vm size>: Azure VM Size"
    echo "   -h:        show this help message"
}

optstring="a:i:k:n:l:z:hr:s:"

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
    z)
      ZONE=$OPTARG
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

case $ARCH in
  x86_64)
    if [ -z "$MARINER_IMAGE" ]; then
      MARINER_IMAGE=$MARINER_IMAGE_X86_64
    fi
    if [ -z "$SIZE" ]; then
      SIZE=$SIZE_X86_64
    fi
    ;;
  arm64)
    if [ -z "$MARINER_IMAGE" ]; then
      MARINER_IMAGE=$MARINER_IMAGE_ARM64
    fi
    if [ -z "$SIZE" ]; then
      SIZE=$SIZE_ARM64
    fi
    ;;
  *)
    echo "Error: Invalid architecture specified - [$ARCH]"
    showUsage
    exit 2
esac

if [ -z "$SSH_KEY_PATH" ]; then
  SSH_KEY_PATH="$HOME/.ssh/id_rsa_azure.pub"
fi

if [ ! -f "$SSH_KEY_PATH" ]; then
  echo "Error: SSH public key not found at [$SSH_KEY_PATH]"
  exit 5
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

AZ_VM_CREATE_ARGS=(
  --resource-group "$RESOURCE_GROUP"
  --name "$INSTANCE_NAME"
  --image "$MARINER_IMAGE"
  --security-type TrustedLaunch
  --enable-secure-boot true
  --enable-vtpm true
  --os-disk-size-gb 60
  --size "$SIZE"
  --public-ip-sku Standard
  --admin-username "$USERNAME"
  --assign-identity "[system]"
  --ssh-key-values "$SSH_KEY_PATH"
  --tags "$TAGS"
  --location "$LOCATION"
)

if [ -n "$ZONE" ]; then
  AZ_VM_CREATE_ARGS+=(--zone "$ZONE")
fi

az vm create "${AZ_VM_CREATE_ARGS[@]}"

