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

# verify_results_processing_api_connectivity
function verify_results_processing_api_connectivity()
{
    CURL_CMD="curl -s -X GET dashboard.us.cray.com:5050"
    CURL_OUT=$(eval ${CURL_CMD})
    CURL_RET=$?
    if [[ ${CURL_RET} -ne 0 ]] ; then
        >&2 echo "ERROR: failed to connect to results processing API: '${CURL_CMD}' failed with error code: ${CURL_RET}"
        return 1
    fi

    QUERY_CHECK=$(echo "${CURL_OUT}" | jq '.success')
    if [[ -z "${QUERY_CHECK}" ]] ; then
        >&2 echo "ERROR: failed to connect to results processing API with '${CURL_CMD}', empty 'success' response field"
        return 1
    elif [[ "${QUERY_CHECK}" == "null" ]] ; then
        >&2 echo "ERROR: failed to connect to results processing API with '${CURL_CMD}', null 'success' response field"
        return 1
    elif [[ "${QUERY_CHECK}" != "true" ]] ; then
        >&2 echo "ERROR: failed to connect to results processing API with '${CURL_CMD}', unexpected 'success' response field: ${QUERY_CHECK}, expected: true"
        return 1
    fi
}

# get_test_entry_label_system_name
function get_test_entry_label_system_name()
{
    KUBECTL_SECRET_SITE_INIT_CMD="kubectl get secrets -n loftsman site-init -o jsonpath='{.data.customizations\.yaml}'"
    KUBECTL_SECRET_SITE_INIT_OUT=$(eval "${KUBECTL_SECRET_SITE_INIT_CMD}")
    KUBECTL_SECRET_SITE_INIT_RET=$?
    if [[ ${KUBECTL_SECRET_SITE_INIT_RET} -ne 0 ]] ; then
        >&2 echo "ERROR: '${KUBECTL_SECRET_SITE_INIT_CMD}' failed with error code: ${KUBECTL_SECRET_SITE_INIT_RET}"
        return 1
    fi
    SYSTEM_NAME=$(echo "${KUBECTL_SECRET_SITE_INIT_OUT}" \
        | base64 -d \
        | grep -E -o "cluster_name: \S+$" \
        | grep -E -o " \S+$" \
        | tr -d " ")
    if [[ -z "${SYSTEM_NAME}" ]] ; then
        >&2 echo "ERROR: failed to extract system name from '${KUBECTL_SECRET_SITE_INIT_CMD}' output"
        return 1
    else
        echo "${SYSTEM_NAME}"
    fi
}

# get_test_entry_product_name
function get_test_entry_product_name()
{
    echo "csm"
}

# get_test_entry_product_version
function get_test_entry_product_version()
{
    KUBECTL_CM_PRODUCT_CATALOG_CMD="kubectl -n services get cm cray-product-catalog -o jsonpath='{.data.csm}'"
    KUBECTL_CM_PRODUCT_CATALOG_OUT=$(eval "${KUBECTL_CM_PRODUCT_CATALOG_CMD}")
    KUBECTL_CM_PRODUCT_CATALOG_RET=$?
    if [[ ${KUBECTL_CM_PRODUCT_CATALOG_RET} -ne 0 ]] ; then
        >&2 echo "ERROR: '${KUBECTL_CM_PRODUCT_CATALOG_CMD}' failed with error code: ${KUBECTL_CM_PRODUCT_CATALOG_RET}"
        return 1
    fi
    PRODUCT_VERSION=$(echo "${KUBECTL_CM_PRODUCT_CATALOG_OUT}" \
        | yq r -j - \
        | jq -r 'keys[]' \
        | sed '/-/!{s/$/_/}' \
        | sort -V \
        | sed 's/_$//' \
        | tail -n 1)
    if [[ -z "${PRODUCT_VERSION}" ]] ; then
        >&2 echo "ERROR: failed to extract product version from '${KUBECTL_CM_PRODUCT_CATALOG_CMD}' output"
        return 1
    else
        echo "${PRODUCT_VERSION}"
    fi
}

# generate_results_report_triage_json <arg1> <arg2> ... <arg6>
#
# Arguments:
#     1. triage_slack_enabled | bool (true or false)
#     2. triage_slack_channel | string (example: ct-failures)
#     3. triage_jira_enabled | bool (true or false)
#     4. triage_jira_project | string (example: CASMHMS)
#     5. triage_jira_assignee | string (example: <jira_username>)
#     6. triage_jira_watchers | list of strings or "none"
#
function generate_results_report_triage_json()
{
    TRIAGE_SLACK_ENABLED=$(echo "${1}" | grep -E "true|false")
    if [[ -z "${TRIAGE_SLACK_ENABLED}" ]] ; then
        >&2 echo "ERROR: invalid TRIAGE_SLACK_ENABLED setting, must be 'true' or 'false'"
        return 1
    fi

    TRIAGE_SLACK_CHANNEL="${2}"
    if [[ -z "${TRIAGE_SLACK_CHANNEL}" ]] ; then
        >&2 echo "ERROR: missing TRIAGE_SLACK_CHANNEL setting"
        return 1
    fi

    TRIAGE_JIRA_ENABLED=$(echo "${3}" | grep -E "true|false")
    if [[ -z "${TRIAGE_JIRA_ENABLED}" ]] ; then
        >&2 echo "ERROR: invalid TRIAGE_JIRA_ENABLED setting, must be 'true' or 'false'"
        return 1
    fi

    TRIAGE_JIRA_PROJECT="${4}"
    if [[ -z "${TRIAGE_JIRA_PROJECT}" ]] ; then
        >&2 echo "ERROR: missing TRIAGE_JIRA_PROJECT setting"
        return 1
    fi

    TRIAGE_JIRA_ASSIGNEE="${5}"
    if [[ -z "${TRIAGE_JIRA_ASSIGNEE}" ]] ; then
        >&2 echo "ERROR: missing TRIAGE_JIRA_ASSIGNEE setting"
        return 1
    fi

    TRIAGE_JIRA_WATCHERS="${6}"
    if [[ -z "${TRIAGE_JIRA_WATCHERS}" ]] ; then
        >&2 echo "ERROR: missing TRIAGE_JIRA_WATCHERS setting"
        return 1
    elif [[ "${TRIAGE_JIRA_WATCHERS}" == "none" ]] ; then
        TRIAGE_JIRA_WATCHERS=""
    fi

    TRIAGE_JSON=$(cat <<EOF
    "triage": {
        "elk": {
            "enabled": true
        },
        "slack": {
            "enabled": ${TRIAGE_SLACK_ENABLED},
            "channel": "${TRIAGE_SLACK_CHANNEL}"
        },
        "jira": {
            "enabled": ${TRIAGE_JIRA_ENABLED},
            "project": "${TRIAGE_JIRA_PROJECT}",
            "assignee": "${TRIAGE_JIRA_ASSIGNEE}",
            "watchers": [${TRIAGE_JIRA_WATCHERS}]
        },
        "zephyr": {
            "enabled": false
        }
    },
EOF
)
    echo "${TRIAGE_JSON}"
}

# generate_results_report_test_entry_json <arg1> <arg2> ... <arg6>
#
# Arguments:
#     1. test_name | string (example: smd_smoke_test_ncn-smoke.sh)
#     2. label | string (example: <system>-<host>-<datetime>)
#     3. product_name | string (example: csm)
#     4. product_version | string (example: 0.9.3)
#     5. status | string ("pass", "fail", "skip", or "warn")
#     6. output_file | string (file to cat, output limited to 5000 characters)
#
function generate_results_report_test_entry_json()
{
    TEST_ENTRY_TEST_NAME="${1}"
    if [[ -z "${TEST_ENTRY_TEST_NAME}" ]] ; then
        >&2 echo "ERROR: missing TEST_ENTRY_TEST_NAME field"
        return 1
    fi

    TEST_ENTRY_LABEL="${2}"
    if [[ -z "${TEST_ENTRY_LABEL}" ]] ; then
        >&2 echo "ERROR: missing TEST_ENTRY_LABEL field"
        return 1
    fi

    TEST_ENTRY_PRODUCT_NAME="${3}"
    if [[ -z "${TEST_ENTRY_PRODUCT_NAME}" ]] ; then
        >&2 echo "ERROR: missing TEST_ENTRY_PRODUCT_NAME field"
        return 1
    fi

    TEST_ENTRY_PRODUCT_VERSION="${4}"
    if [[ -z "${TEST_ENTRY_PRODUCT_VERSION}" ]] ; then
        >&2 echo "ERROR: missing TEST_ENTRY_PRODUCT_VERSION field"
        return 1
    fi

    TEST_ENTRY_STATUS=$(echo "${5}" | grep -E "^pass$|^fail$|^skip$|^warn$")
    if [[ -z "${TEST_ENTRY_STATUS}" ]] ; then
        >&2 echo "ERROR: invalid TEST_ENTRY_STATUS field: '${TEST_ENTRY_STATUS}', must be 'pass', 'fail', 'skip', or 'warn'"
        return 1
    fi

    TEST_ENTRY_OUTPUT_FILE_PATH="${6}"
    if [[ -z "${TEST_ENTRY_OUTPUT_FILE_PATH}" ]] ; then
        >&2 echo "ERROR: missing test output file path"
        return 1
    elif [[ ! -f ${TEST_ENTRY_OUTPUT_FILE_PATH} ]] ; then
        >&2 echo "ERROR: missing test output file: ${TEST_ENTRY_OUTPUT_FILE_PATH}"
        return 1
    elif [[ ! -r ${TEST_ENTRY_OUTPUT_FILE_PATH} ]] ; then
        >&2 echo "ERROR: unreadable test output file: ${TEST_ENTRY_OUTPUT_FILE_PATH}"
        return 1
    fi

    # process the test entry output
    TEST_ENTRY_OUTPUT=$(cat ${TEST_ENTRY_OUTPUT_FILE_PATH})
    # save space by not storing long and repeated keycloak tokens
    TEST_ENTRY_OUTPUT=$(echo "${TEST_ENTRY_OUTPUT}" | sed -E 's/Authorization: Bearer \S+ /Authorization: Bearer \${TOKEN} /g')
    # only capture failure, error, or summary output since we are limited to 5000 characters per entry
    TEST_ENTRY_OUTPUT=$(echo "${TEST_ENTRY_OUTPUT}" | grep -E -i "fail|error|warn|alert|unexpected|fatal|critical|skip|Enum '\S+' does not exist.|short test summary info|[0-9]+ passed in")
    # remove extraneous characters from tavern output lines for tests that passed
    TEST_ENTRY_OUTPUT=$(echo "${TEST_ENTRY_OUTPUT}" | sed -E '/=+ [0-9]+ passed in [0-9]+\.[0-9]+s.* =+/s/=//g' | sed 's/^[ \t]*//;s/[ \t]*$//')
    # exclude tavern output of entire API json responses since they are huge and won't fit
    TEST_ENTRY_OUTPUT=$(echo "${TEST_ENTRY_OUTPUT}" | grep -E -v "tavern.schemas.files.*Error validating {.*}")
    # exclude these tavern messages since they aren't helpful for debugging failures
    TEST_ENTRY_OUTPUT=$(echo "${TEST_ENTRY_OUTPUT}" | grep -E -v "Error calling validate function '.*'|BadSchemaError|raise SchemaError")
    # more tavern output messages to exclude that don't provide useful information
    TEST_ENTRY_OUTPUT=$(echo "${TEST_ENTRY_OUTPUT}" | grep -E -v "pykwalify.core:core.py:[0-9]+")
    # replace double quotes with single quotes that can be parsed as json
    TEST_ENTRY_OUTPUT=$(echo "${TEST_ENTRY_OUTPUT}" | tr "\"" "'")
    # remove unescaped newline and carriage return characters that cause parsing problems
    TEST_ENTRY_OUTPUT=$(echo "${TEST_ENTRY_OUTPUT}" | tr '\r\n' ' ')
    # remove trailing whitespace character
    TEST_ENTRY_OUTPUT=$(echo "${TEST_ENTRY_OUTPUT}" | sed 's/ $//')

    TEST_ENTRY_JSON=$(cat <<EOF
        {
            "test_name": "${TEST_ENTRY_TEST_NAME}",
            "label": "${TEST_ENTRY_LABEL}",
            "product_name": "${TEST_ENTRY_PRODUCT_NAME}",
            "product_version": "${TEST_ENTRY_PRODUCT_VERSION}",
            "status": "${TEST_ENTRY_STATUS}",
            "output": "${TEST_ENTRY_OUTPUT}"
        },
EOF
)
    # Note: the trailing comma above needs to be removed for the last test entry in the report to form valid JSON
    echo "${TEST_ENTRY_JSON}"
}

# ship_test_results results_file_path
function ship_test_results()
{
    RESULTS_FILE_PATH="${1}"
    if [[ -z "${RESULTS_FILE_PATH}" ]] ; then
        >&2 echo "ERROR: missing results json file path"
        return 1
    elif [[ ! -f ${RESULTS_FILE_PATH} ]] ; then
        >&2 echo "ERROR: missing results json file: ${RESULTS_FILE_PATH}"
        return 1
    elif [[ ! -r ${RESULTS_FILE_PATH} ]] ; then
        >&2 echo "ERROR: unreadable results json file: ${RESULTS_FILE_PATH}"
        return 1
    fi

    CURL_CMD="curl -s dashboard.us.cray.com:5050 -d @${RESULTS_FILE_PATH}"
    CURL_OUT=$(eval ${CURL_CMD})
    CURL_RET=$?
    if [[ ${CURL_RET} -ne 0 ]] ; then
        >&2 echo "ERROR: failed to ship test results, '${CURL_CMD}' failed with error code: ${CURL_RET}"
        return 1
    fi

    SHIP_CHECK=$(echo "${CURL_OUT}" | jq '.success')
    if [[ -z "${SHIP_CHECK}" ]] ; then
        >&2 echo "ERROR: failed to ship test results with '${CURL_CMD}', empty 'success' response field"
        return 1
    elif [[ "${SHIP_CHECK}" == "null" ]] ; then
        >&2 echo "ERROR: failed to ship test results with '${CURL_CMD}', null 'success' response field"
        return 1
    elif [[ "${SHIP_CHECK}" != "true" ]] ; then
        >&2 echo "ERROR: failed to ship test results with '${CURL_CMD}', unexpected 'success' response field: ${SHIP_CHECK}, expected: true"
        return 1
    fi

    RUN_ID=$(echo "${CURL_OUT}" | jq -r '.artifacts.run_id')
    if [[ -z "${RUN_ID}" ]] ; then
        >&2 echo "ERROR: empty run_id artifact in results API response"
        return 1
    elif [[ "${RUN_ID}" == "null" ]] ; then
        >&2 echo "ERROR: null run_id artifact in results API response"
        return 1
    else
        RUN_URL="http://dashboard.us.cray.com/run/${RUN_ID}"
        echo "${RUN_URL}"
    fi
}
