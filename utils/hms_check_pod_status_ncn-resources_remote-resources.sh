#!/bin/bash

if [ -z "$1" ]; then
    echo "Please give one or more pod names"
    exit 1
fi

# If given multiple pod names, grep for them all via regex
PODS=""
for POD in $@; do
    PODS="$PODS\|$POD"
done
PODS_REGEX="\(${PODS: 2}\)"

# We're only filtering from the start of the pod name. Looking for exact
# matches is tricky, since "api-gateway" and "api-gateway-database" both
# have hashes appended to them, and the hashes are not fixed length. 
LINES=$(kubectl get pods --all-namespaces | grep -e "^\S*\s*$PODS_REGEX")

if [ "$LINES" == "" ]; then
    echo "No pods found" 1>&2
    exit 1
fi

echo "$LINES"
echo

STATUSES=$(echo "$LINES" | awk '{print $4}' | sort | uniq | tr $'\n' ' ')
echo "Pod status: $STATUSES"

GOOD_STATUSES="Running Completed"
for STATUS in $STATUSES; do
    if ! echo "$GOOD_STATUSES" | grep -q "$STATUS"; then
        exit 1
    fi
done