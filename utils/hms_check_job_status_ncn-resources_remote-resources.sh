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
    echo "Please give one or more job names"
    exit 1
fi

# If given multiple job names, grep for them all via regex
JOBS=""
for JOB in $@; do
    JOBS="$JOBS\|$JOB"
done
JOBS_REGEX="\(${JOBS: 2}\)"

# We're only filtering from the start of the job name. Looking for exact
# matches is tricky, since "api-gateway" and "api-gateway-database" both
# have hashes appended to them, and the hashes are not fixed length. 
LINES=$(kubectl get jobs --all-namespaces | grep -e "^\S*\s*$JOBS_REGEX")

if [ "$LINES" == "" ]; then
    echo "No jobs found" 1>&2
    exit 1
fi

echo "$LINES"
echo

while read LINE ; do
    JOB_NAME=$(echo "$LINE" | awk '{print $2}')
    if [[ -z "${JOB_NAME}" ]] ; then
        echo "Missing job name" 1>&2
        exit 1
    fi
    COMPLETIONS_COLUMN=$(echo "$LINE" | awk '{print $3}')
    COMPLETIONS_COLUMN_CHECK=$(echo "${COMPLETIONS_COLUMN}" | grep -E -o "[0-9]+/[0-9]+")
    if [[ -z "${COMPLETIONS_COLUMN_CHECK}" ]] ; then
        echo "Missing job data" 1>&2
        exit 1
    fi
    COMPLETIONS=$(echo "${COMPLETIONS_COLUMN}" | cut -d "/" -f 1 | grep -E -o "[0-9]+")
    if [[ -z ${COMPLETIONS} ]] ; then
        echo "Missing job completion value" 1>&2
        exit 1
    fi
    TOTAL=$(echo "${COMPLETIONS_COLUMN}" | cut -d "/" -f 2 | grep -E -o "[0-9]+")
    if [[ -z ${TOTAL} ]] ; then
        echo "Missing job total value" 1>&2
        exit 1
    fi
    echo "${JOB_NAME} job completions: ${COMPLETIONS}/${TOTAL}"
    if [[ ${TOTAL} -eq 0 ]] ; then
        echo "Zero jobs found" 1>&2
        exit 1
    fi
    if [[ ${COMPLETIONS} -ne ${TOTAL} ]] ; then
        if [[ ${COMPLETIONS} -eq 1 ]] ; then
            echo "${COMPLETIONS} job completed, expected: ${TOTAL}"
        else
            echo "${COMPLETIONS} jobs completed, expected: ${TOTAL}"
        fi
        exit 1
    fi
done <<< "${LINES}"