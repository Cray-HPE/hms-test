#!/bin/bash

# MIT License
#
# (C) Copyright [2021] Hewlett Packard Enterprise Development LP
#
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included
# in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR
# OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
# ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.

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