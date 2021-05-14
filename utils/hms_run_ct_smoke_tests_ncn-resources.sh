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

DASHP=false
SEND_RESULTS=false
TMP_OUTFILE="/tmp/hms-ct-test-temp-outfile"

# parse command-line options
while getopts "hp" opt; do
    case ${opt} in
        h) echo "Usage: hms_run_ct_smoke_tests_ncn-resources.sh [-h] [-p]"
           echo
           echo "Arguments:"
           echo "    -h        display this help message"
           echo "    -p        enable results processing"
           exit 0
           ;;
        p) DASHP=true
           ;;
    esac
done

if ${DASHP} ; then
    # enable results processing
    RESULTS_PROCESSING_LIB="/opt/cray/tests/ncn-resources/hms/hms-test/hms_ct_test_results_processing_lib_ncn-resources_remote-resources.sh"
    # source HMS results processing library file
    if [[ -r ${RESULTS_PROCESSING_LIB} ]] ; then
        . ${RESULTS_PROCESSING_LIB}
        # verify results processing API connectivity
        RESULTS_PROCESSING_SETUP_OUT=$(verify_results_processing_api_connectivity)
        RESULTS_PROCESSING_SETUP_RET=$?
        if [[ ${RESULTS_PROCESSING_SETUP_RET} -eq 0 ]] ; then
            SEND_RESULTS=true
        fi
    else
        >&2 echo "ERROR: failed to source HMS results processing library: ${RESULTS_PROCESSING_LIB}"
        echo "proceeding without results processing..."
    fi
fi

# create list of all HMS CT smoke test directories
echo "searching for HMS CT smoke tests..."
HMS_SMOKE_TEST_DIR="/opt/cray/tests/ncn-smoke/hms"
HMS_SMOKE_TEST_SUB_DIRS=$(ls ${HMS_SMOKE_TEST_DIR})
if [[ -z "${HMS_SMOKE_TEST_SUB_DIRS}" ]] ; then
    >&2 echo "ERROR: no HMS smoke test directories found in: ${HMS_SMOKE_TEST_DIR}"
    exit 1
fi

# create list of all executables in each of the HMS smoke test directories
SMOKE_TESTS=""
for DIR in ${HMS_SMOKE_TEST_SUB_DIRS} ; do
    if [[ -d "${HMS_SMOKE_TEST_DIR}/${DIR}" ]] ; then
        DIR_FILES=$(ls ${HMS_SMOKE_TEST_DIR}/${DIR})
        for FILE in ${DIR_FILES} ; do
            FILE_PATH="${HMS_SMOKE_TEST_DIR}/${DIR}/${FILE}"
            # check for executable that is not a directory
            if [[ -x "${FILE_PATH}" ]] && [[ ! -d "${FILE_PATH}" ]] ; then
                if [[ -z "${SMOKE_TESTS}" ]] ; then
                    SMOKE_TESTS="${FILE_PATH}"
                else
                    SMOKE_TESTS="${SMOKE_TESTS} ${FILE_PATH}"
                fi
            fi
        done
    fi
done

# check if any tests were found
NUM_TESTS=$(echo "${SMOKE_TESTS}" | wc -w)
if [[ ${NUM_TESTS} -eq 0 ]] ; then
    >&2 echo "ERROR: no executable HMS smoke tests found under: ${HMS_SMOKE_TEST_DIR}"
    exit 1
elif [[ ${NUM_TESTS} -eq 1 ]] ; then
    echo "found ${NUM_TESTS} HMS CT smoke test..."
else
    echo "found ${NUM_TESTS} HMS CT smoke tests..."
fi

if ${SEND_RESULTS} ; then
    echo "setting up results processing..."

    # get system name for test entry labels
    TEST_ENTRY_LABEL_SYSTEM=$(get_test_entry_label_system_name)
    TEST_ENTRY_LABEL_SYSTEM_RET=$?
    if [[ ${TEST_ENTRY_LABEL_SYSTEM_RET} -ne 0 ]] ; then
        TEST_ENTRY_LABEL_SYSTEM="<system>"
        SEND_RESULTS=false
    fi

    # get the system time for test entry labels
    TEST_ENTRY_LABEL_TIME=$(date +"%Y%m%dT%H%M%S")

    # get the product name for test entries
    TEST_ENTRY_PRODUCT_NAME=$(get_test_entry_product_name)
    TEST_ENTRY_PRODUCT_NAME_RET=$?
    if [[ ${TEST_ENTRY_PRODUCT_NAME_RET} -ne 0 ]] ; then
        TEST_ENTRY_PRODUCT_NAME="<product>"
        SEND_RESULTS=false
    fi

    # get the product version for test entries
    TEST_ENTRY_PRODUCT_VERSION=$(get_test_entry_product_version)
    TEST_ENTRY_PRODUCT_VERSION_RET=$?
    if [[ ${TEST_ENTRY_PRODUCT_VERSION_RET} -ne 0 ]] ; then
        TEST_ENTRY_PRODUCT_VERSION="<version>"
        SEND_RESULTS=false
    fi

    # generate the triage section of the results report json
    RESULTS_REPORT_TRIAGE_JSON_OUT=$(generate_results_report_triage_json true ct-failures false CASMHMS schooler none)
    RESULTS_REPORT_TRIAGE_JSON_RET=$?
    if [[ ${RESULTS_REPORT_TRIAGE_JSON_RET} -ne 0 ]] ; then
        RESULTS_REPORT_TRIAGE_JSON_OUT=$(cat <<EOF
    "triage": {
    }
EOF
)
        SEND_RESULTS=false
    fi

    # initialize the results json
    RESULTS_JSON=$(cat <<EOF
{
${RESULTS_REPORT_TRIAGE_JSON_OUT}
    "tests": [
EOF
)
fi

# execute all HMS smoke tests
NUM_FAILURES=0
echo "running HMS CT smoke tests..."
echo
echo "##############################################"
echo
for TEST in ${SMOKE_TESTS} ; do
    echo "running '${TEST}'..."
    eval ${TEST} 2>&1 | tee ${TMP_OUTFILE}
    TEST_RET=${PIPESTATUS[0]}
    echo "'${TEST}' exited with status code: ${TEST_RET}"
    if [[ ${TEST_RET} -ne 0 ]] ; then
        ((NUM_FAILURES++))
        TEST_ENTRY_STATUS="fail"
    else
        TEST_ENTRY_STATUS="pass"
    fi

    if ${SEND_RESULTS} ; then
        TEST_ENTRY_NAME="${TEST##*/}"
        TEST_ENTRY_LABEL="${TEST_ENTRY_LABEL_SYSTEM}_${HOSTNAME}_${TEST_ENTRY_LABEL_TIME}"
        TEST_ENTRY_OUT=$(generate_results_report_test_entry_json \
            ${TEST_ENTRY_NAME} \
            ${TEST_ENTRY_LABEL} \
            ${TEST_ENTRY_PRODUCT_NAME} \
            ${TEST_ENTRY_PRODUCT_VERSION} \
            ${TEST_ENTRY_STATUS} \
            ${TMP_OUTFILE})
        TEST_ENTRY_RET=$?
        if [[ ${TEST_ENTRY_RET} -eq 0 ]] ; then
            RESULTS_JSON="${RESULTS_JSON}
${TEST_ENTRY_OUT}"
        fi
    fi
    rm -f ${TMP_OUTFILE}
    echo
    echo "##############################################"
    echo
done

if ${SEND_RESULTS} ; then
    # close off the results JSON structure
    RESULTS_JSON="${RESULTS_JSON}
    ]
}"
    # remove the trailing comma of the last test entry in the report
    RESULTS_JSON=$(echo "${RESULTS_JSON}" | sed -zr 's/,([^,]*$)/\1/')

    # verify that we have a valid JSON structure
    echo "verifying results JSON structure..."
    RESULTS_JSON_CHECK_OUT=$(echo "${RESULTS_JSON}" | jq)
    RESULTS_JSON_CHECK_RET=$?
    if [[ ${RESULTS_JSON_CHECK_RET} -ne 0 ]] ; then
        >&2 echo "ERROR: generated invalid JSON structure for results processing"
        SEND_RESULTS=false
    fi
fi

# final check
if ${SEND_RESULTS} ; then
    echo "shipping test results..."
    # write results json to output file
    RESULTS_FILE="/tmp/hms-ct-test-results.json"
    echo "${RESULTS_JSON}" > ${RESULTS_FILE}

    # ship the results json to the results API for processing and storage
    SHIP_TEST_RESULTS_OUT=$(ship_test_results ${RESULTS_FILE})
    SHIP_TEST_RESULTS_RET=$?
    if [[ ${SHIP_TEST_RESULTS_RET} -eq 0 ]] ; then
        echo "results processed successfully and available at: ${SHIP_TEST_RESULTS_OUT}"
    fi
    echo

    # clean up results file
    rm -f ${RESULTS_FILE}
else
    if ${DASHP} ; then
        echo "skipping test results processing..."
        echo
    fi
fi

# check for failures
if [[ ${NUM_FAILURES} -gt 0 ]] ; then
    echo "HMS smoke tests ran with ${NUM_FAILURES}/${NUM_TESTS} failures"
    echo "exiting with status code: 1"
    exit 1
else
    echo "HMS smoke tests ran with no failures"
    echo "exiting with status code: 0"
    exit 0
fi