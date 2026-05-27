#!/bin/bash

LOCATION=westus2
FILTER=
CORES=
ARCH=

function showUsage() {
    echo "Usage: az-list-vm-sizes.sh <options>"
    echo "   -l <location>: Azure region to query (default: westus2)"
    echo "   -a <arch>:     Filter by CPU architecture: { x86_64, arm64 }"
    echo "   -c <cores>:    Filter by exact vCPU count (e.g. 4, 8, 16)"
    echo "   -f <filter>:   Filter size names by substring (e.g. Standard_D)"
    echo "   -h:            Show this help message"
}

optstring="a:c:f:l:h"

while getopts ${optstring} arg; do
  case ${arg} in
    h)
      showUsage
      exit 0
      ;;
    a)
      ARCH=$OPTARG
      ;;
    c)
      CORES=$OPTARG
      ;;
    f)
      FILTER=$OPTARG
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

ARCH_VALUE=
if [ -n "$ARCH" ]; then
    case "$ARCH" in
        x86_64) ARCH_VALUE="x64" ;;
        arm64)  ARCH_VALUE="Arm64" ;;
        *)
            echo "Error: Unknown architecture '$ARCH'. Use x86_64 or arm64."
            exit 1
            ;;
    esac
fi

# Build JMESPath filter conditions
# Always exclude SKUs with a location-level restriction (not available in this region/subscription)
CONDITIONS=("length(restrictions[?reasonCode=='NotAvailableForSubscription']) == \`0\`")
[ -n "$ARCH_VALUE" ] && CONDITIONS+=("capabilities[?name=='CpuArchitectureType' && value=='$ARCH_VALUE']")
[ -n "$CORES" ]      && CONDITIONS+=("capabilities[?name=='vCPUs' && value=='$CORES']")
[ -n "$FILTER" ]     && CONDITIONS+=("contains(name, '$FILTER')")

CONDITION_STR="${CONDITIONS[0]}"
for cond in "${CONDITIONS[@]:1}"; do
    CONDITION_STR="$CONDITION_STR && $cond"
done
QUERY="[?${CONDITION_STR}]"

QUERY="${QUERY}.{Name:name, vCPUs:capabilities[?name=='vCPUs'].value|[0], MemoryGB:capabilities[?name=='MemoryGB'].value|[0], Architecture:capabilities[?name=='CpuArchitectureType'].value|[0], Zones:join(', ', locationInfo[0].zones), Restrictions:join(', ', restrictions[*].reasonCode)}"

SIZE_FILTER=()
[ -n "$FILTER" ] && SIZE_FILTER=(--size "$FILTER")

az vm list-skus \
    --location "$LOCATION" \
    --resource-type virtualMachines \
    "${SIZE_FILTER[@]}" \
    --query "$QUERY" \
    --output table
