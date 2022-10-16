# Build Host

For my Build Host, I use an Azure VM based on Mariner.

## Step 1: Login into Azure

```
az login --use-device-code
```

### Setp 1.1 Set Azure Subscription

```
az account set --subscription <subscription uuid>
```

## Step 2: Create the Build VM

```
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
```

### Step 2.1: [optional] Save connection information to ~/.ssh/config

For convenience, capture the Public IP Address for the VM in $HOME/.ssh/config

```
Host azure-arm-1
	HostName 20.113.59.60
	User cooldude
	IdentityFile ~/.ssh/id_rsa_azure
```

This will allow the following commands to work from the terminal.

```
ssh cooldude@azure-arm-1
scp blah cooldude@azurearm-1:
```

## References

* [Install azure-cli (az) on Mac](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli-macos)
* [Create SSH key pair](https://learn.microsoft.com/en-us/azure/virtual-machines/linux/create-ssh-keys-detailed)