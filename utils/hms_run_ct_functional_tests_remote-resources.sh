#!/bin/bash -l

# Copyright 2021 Hewlett Packard Enterprise Development LP

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
    echo "exiting with status code: 1"
    exit 1
else
    echo "HMS functional tests ran with no failures"
    echo "exiting with status code: 0"
    exit 0
fi