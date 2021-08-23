#!/bin/bash -l

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

# create list of all HMS CT functional test directories
echo "searching for HMS CT functional tests..."
HMS_FUNCTIONAL_TEST_DIR="/opt/cray/tests/remote-functional/hms"
HMS_FUNCTIONAL_TEST_SUB_DIRS=$(ls ${HMS_FUNCTIONAL_TEST_DIR})
if [[ -z "${HMS_FUNCTIONAL_TEST_SUB_DIRS}" ]] ; then
    >&2 echo "ERROR: no HMS functional test directories found in: ${HMS_FUNCTIONAL_TEST_DIR}"
    exit 1
fi

# create list of all executables in each of the HMS functional test directories
FUNCTIONAL_TESTS=""
for DIR in ${HMS_FUNCTIONAL_TEST_SUB_DIRS} ; do
    if [[ -d "${HMS_FUNCTIONAL_TEST_DIR}/${DIR}" ]] ; then
        DIR_FILES=$(ls ${HMS_FUNCTIONAL_TEST_DIR}/${DIR})
        for FILE in ${DIR_FILES} ; do
            FILE_PATH="${HMS_FUNCTIONAL_TEST_DIR}/${DIR}/${FILE}"
            # check for executable that is not a directory
            if [[ -x "${FILE_PATH}" ]] && [[ ! -d "${FILE_PATH}" ]] ; then
                if [[ -z "${FUNCTIONAL_TESTS}" ]] ; then
                    FUNCTIONAL_TESTS="${FILE_PATH}"
                else
                    FUNCTIONAL_TESTS="${FUNCTIONAL_TESTS} ${FILE_PATH}"
                fi
            fi
        done
    fi
done

# check if any tests were found
NUM_TESTS=$(echo "${FUNCTIONAL_TESTS}" | wc -w)
if [[ ${NUM_TESTS} -eq 0 ]] ; then
    >&2 echo "ERROR: no executable HMS functional tests found under: ${HMS_FUNCTIONAL_TEST_DIR}"
    exit 1
elif [[ ${NUM_TESTS} -eq 1 ]] ; then
    echo "found ${NUM_TESTS} HMS CT functional test..."
else
    echo "found ${NUM_TESTS} HMS CT functional tests..."
fi

# execute all HMS functional tests
NUM_FAILURES=0
echo "running HMS CT functional tests..."
echo
echo "##############################################"
echo
for TEST in ${FUNCTIONAL_TESTS} ; do
    echo "running '${TEST}'..."
    eval ${TEST}
    TEST_RET=$?
    echo "'${TEST}' exited with status code: ${TEST_RET}"
    if [[ ${TEST_RET} -ne 0 ]] ; then
        ((NUM_FAILURES++))
    fi
    echo
    echo "##############################################"
    echo
done

# check for failures
if [[ ${NUM_FAILURES} -gt 0 ]] ; then
    echo "HMS functional tests ran with ${NUM_FAILURES}/${NUM_TESTS} failures"
    echo
    echo "Additional information about interpreting these test results can be found at:"
    echo "https://stash.us.cray.com/projects/CSM/repos/docs-csm/browse/troubleshooting/interpreting_hms_health_check_results.md"
    echo
    echo "exiting with status code: 1"
    exit 1
else
    echo "HMS functional tests ran with no failures"
    echo "exiting with status code: 0"
    exit 0
fi