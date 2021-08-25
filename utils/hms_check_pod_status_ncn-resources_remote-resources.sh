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

GOOD_STATUSES="Running Completed"

while read LINE ; do
    POD_NAME=$(echo "${LINE}" | awk '{print $2}')
    if [[ -z "${POD_NAME}" ]] ; then
        echo "Missing pod name" 1>&2
        exit 1
    fi
    POD_STATUS=$(echo "${LINE}" | awk '{print $4}')
    if [[ -z "${POD_STATUS}" ]] ; then
        echo "Missing pod status" 1>&2
        exit 1
    fi
    echo "${POD_NAME} pod status: ${POD_STATUS}"
    POD_STATUS_CHECK=$(echo "${GOOD_STATUSES}" | grep "${POD_STATUS}")
    if [[ -z "${POD_STATUS_CHECK}" ]] ; then
        echo "Unexpected pod status '${POD_STATUS}', expected one of: ${GOOD_STATUSES}"
        echo "Run 'kubectl -n services describe pod ${POD_NAME}' to continue troubleshooting"
        exit 1
    fi
done <<< "${LINES}"