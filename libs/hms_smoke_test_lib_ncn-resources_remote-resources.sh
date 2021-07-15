#!/bin/bash -l

# MIT License
#
# (C) Copyright [2019-2021] Hewlett Packard Enterprise Development LP
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

###############################################################
#
#     CASM Test - Cray Inc.
#
#     LIBRARY IDENTIFIER   : hms_smoke_test_lib
#
#     DESCRIPTION          : Library of BASH functions used to support the
#                            HMS smoke tests that verify HMS microservice API
#                            infrastructure and installation on Cray Shasta
#                            systems.
#                         
#     AUTHOR               : Mitch Schooler
#
#     DATE STARTED         : 04/23/2019
#
#     LAST MODIFIED        : 03/25/2021
#
#     SYNOPSIS
#       This library file contains BASH functions that are used and shared by
#       HMS tests that execute within the DST Continuous Testing (CT) framework.
#       The functions provide shared infrastructure for making HTTP requests to
#       API endpoints using curl and processing the responses.
#
#     INPUT SPECIFICATIONS
#       This library is not meant to be executed directly. It is intended to be
#       sourced by various HMS CT tests that share commonly needed functionality.
#
#     DESIGN DESCRIPTION
#       These functions are based on DST's Shasta health check srv_check.sh script
#       functions in the CrayTest repository but have been modified to better suite
#       the needs of the HMS group.
#
#     UPDATE HISTORY
#       user       date         description
#       -------------------------------------------------------
#       schooler   04/25/2019   initial implementation
#       schooler   06/20/2019   added AuthN support functions
#       schooler   08/02/2019   updated expected HTTP response header for AuthN
#       schooler   08/19/2019   added check_pod_status function
#       schooler   09/10/2019   updated Cray copyright header
#       schooler   10/07/2019   switched from SMS to NCN naming convention
#       schooler   06/23/2020   allow 204 status codes for liveness/readiness probes
#       schooler   07/27/2020   added run_check_pod_job_status function
#       schooler   09/21/2020   updated for remote testing from ct-pipelines container
#       schooler   01/21/2021   added HMS version of check_pod_status tool
#       schooler   01/29/2021   added curl -k option for running on PIT nodes
#       schooler   01/29/2021   specify python3 instead of python for parsing json
#       schooler   03/25/2021   removed deprecated run_check_pod_job_status function
#       schooler   03/25/2021   added run_check_job_status function
#
#     DEPENDENCIES
#       None
#
#     BUGS/LIMITATIONS
#       None
#
###############################################################

# timestamp_print <message>
function timestamp_print()
{
    echo "($(date +"%H:%M:%S")) $1"
}

# Print a URL to be used for an API call. The basic usage is:
#
#   url [http|https] [<port_number>] <target_uri>
#
# Only the <target_uri> argument is required.
# E.g. target uri: apis/smd/hsm/v1/Inventory/ComponentEndpoints
function url()
{
    # handle optional leading http[s] argument
    if [[ $# -gt 1 ]] && [[ "$1" == "http" ]] ; then
        shift
        HTTP="http"
    elif [[ $# -gt 1 ]] && [[ "$1" == "https" ]] ; then
        shift
        HTTP="https"
    else
        HTTP="https"
    fi
    
    # build up target URL
    if [[ $# -eq 1 ]] ; then
        echo "${HTTP}://${TARGET}/$1"
    elif [[ $# -eq 2 ]] ; then
        echo "${HTTP}://${TARGET}:$1/$2"
    else
        >&2 echo "ERROR: Invalid number of arguments passed to url() function"
        return 1
    fi
}

# run_curl <http_operation> [curl_args]
#
#   Make a curl call and verify that the status code is 200 or 204. Return 0 if it is, else return
#   1 and echo an error message containing the response code and the error line from the curl output.
#   The first argument you pass into it has to be the argument to curl’s -X flag (i.e. the type of
#   request: GET, POST, etc). Any other arguments are just passed through to the curl command.
#
#   Global variable dependencies:
#
#       CURL_ARGS           Leading command line arguments to supply to curl call
#       CURL_COUNT          Running total of number of curl calls made during a test run
#       OUTPUT_FILES_PATH   Path to writable filesystem location for temporary curl output files
#
function run_curl()
{
    ((CURL_COUNT++))
    CURL_OUTFILE="${OUTPUT_FILES_PATH}.curl${CURL_COUNT}.tmp"
    CURL_CMD="curl -k ${CURL_ARGS} -o ${CURL_OUTFILE} -X $@"
    _run_curl "${CURL_CMD}"
}

# _run_curl <curl_cmd>
#
#   Pass the entire command to run as "$1". It must ultimately generate curl "-i"
#   output and store it in the file $CURL_OUTFILE on this host. The output is then
#   checked for a 200 or 204 response code. Return 0 if it is, else return 1 and echo an
#   error message that contains the status code and the error line from the curl output.
#
function _run_curl()
{
    CMD="$1"
    timestamp_print "Testing '${CMD}'..."
    CMD_OUT=$(eval "${CMD}" 2>&1)
    RET=$?
    if [[ -n ${CMD_OUT} ]] ; then
        echo "${CMD_OUT}"
    fi
    if [[ ${RET} -ne 0 ]] ; then
        >&2 echo -e "ERROR: '${CMD}' failed with error code: ${RET}\n"
        return 1
    fi
    STATUS_CODE_LINE=$(head -1 ${CURL_OUTFILE})
    STATUS_CHECK=$(echo "${STATUS_CODE_LINE}" | grep -E -w "200|204")
    if [[ -z "${STATUS_CHECK}" ]] ; then
        echo "${STATUS_CODE_LINE}"
        >&2 echo -e "ERROR: '${CMD}' did not return \"200\" or \"204\" status code as expected\n"
        return 1
    fi
}

# get_auth_access_token
#
#   Retrieve a Keycloak authentication token for the test session which requires the
#   client secret to be supplied. Once the token is obtained, extract the "access_token"
#   field of the JSON dictionary since that is the token string that will need to be
#   supplied in the authorization headers of the curl HTTP requests being tested.
#
function get_auth_access_token()
{
    # get client secret
    CLIENT_SECRET=$(get_client_secret)
    CLIENT_SECRET_RET=$?
    if [[ ${CLIENT_SECRET_RET} -ne 0 ]] ; then
        return 1
    fi

    # get authentication token
    AUTH_TOKEN=$(get_auth_token "${CLIENT_SECRET}")
    AUTH_TOKEN_RET=$?
    if [[ ${AUTH_TOKEN_RET} -ne 0 ]] ; then
        return 1
    fi

    # extract access_token field from authentication token
    ACCESS_TOKEN=$(extract_access_token "${AUTH_TOKEN}")
    ACCESS_TOKEN_RET=$?
    if [[ ${ACCESS_TOKEN_RET} -ne 0 ]] ; then
        return 1
    fi

    # return the access_token
    echo "${ACCESS_TOKEN}"
}

# get_client_secret
#
#   Return the admin client authentication secret from Kubernetes.
#
#   Example:
#      sms01-nmn:~ # kubectl get secrets admin-client-auth -o jsonpath='{.data.client-secret}' | base64 -d
#      be914011-91f5-4c84-bd06-88ec7f1bc00d
#
function get_client_secret()
{
    # get client secret from Kubernetes
    KUBECTL_GET_SECRET_CMD="kubectl get secrets admin-client-auth -o jsonpath='{.data.client-secret}'"
    >&2 echo $(timestamp_print "Running '${KUBECTL_GET_SECRET_CMD}'...")
    KUBECTL_GET_SECRET_OUT=$(eval ${KUBECTL_GET_SECRET_CMD})
    KUBECTL_GET_SECRET_RET=$?
    if [[ ${KUBECTL_GET_SECRET_RET} -ne 0 ]] ; then
        >&2 echo -e "${KUBECTL_GET_SECRET_OUT}\n"
        >&2 echo -e "ERROR: '${KUBECTL_GET_SECRET_CMD}' failed with error code: ${KUBECTL_GET_SECRET_RET}\n"
        return 1
    elif [[ -z "${KUBECTL_GET_SECRET_OUT}" ]] ; then
        >&2 echo -e "ERROR: '${KUBECTL_GET_SECRET_CMD}' failed to return client secret\n"
        return 1
    fi
    CLIENT_SECRET=$(echo "${KUBECTL_GET_SECRET_OUT}" | base64 -d)
    echo "${CLIENT_SECRET}"
}

# get_auth_token <client_secret>
#
#   Return an admin client authentication token from Keycloak in dictionary form.
#
#   Example:
#      sms01-nmn:~ # curl -s \
#                         -d grant_type=client_credentials -d client_id=admin-client \
#                         -d client_secret=be914011-91f5-4c84-bd06-88ec7f1bc00d \
#                         https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token \
#                         | python3 -m json.tool
#      {
#         "access_token": "eyJhbGciOiJSUzI1NiIsInR5cCIgOiAiSld...<snip>",
#         "expires_in": 300,
#         "not-before-policy": 0,
#         "refresh_expires_in": 1800,
#         "refresh_token": "eyJhbGciOiJSUzI1NiIsInR5cCIgOiAiSld...<snip>",
#         "scope": "profile email",
#         "session_state": "b7a848af-42e4-4702-a866-25dd4b8cc3cc",
#         "token_type": "bearer"
#      }
#
function get_auth_token()
{
    CLIENT_SECRET="${1}"
    if [[ -z "${CLIENT_SECRET}" ]] ; then
        >&2 echo "ERROR: No client secret argument passed to get_auth_token() function"
        return 1
    fi
    KEYCLOAK_TOKEN_URI="https://api-gw-service-nmn.local/keycloak/realms/shasta/protocol/openid-connect/token"
    KEYCLOAK_TOKEN_CMD="curl -k -i -s -S -d grant_type=client_credentials -d client_id=admin-client -d client_secret=${CLIENT_SECRET} ${KEYCLOAK_TOKEN_URI}"
    >&2 echo $(timestamp_print "Running '${KEYCLOAK_TOKEN_CMD}'...")
    KEYCLOAK_TOKEN_OUT=$(eval ${KEYCLOAK_TOKEN_CMD})
    KEYCLOAK_TOKEN_RET=$?
    if [[ ${KEYCLOAK_TOKEN_RET} -ne 0 ]] ; then
        >&2 echo -e "${KEYCLOAK_TOKEN_OUT}\n"
        >&2 echo -e "ERROR: '${KEYCLOAK_TOKEN_CMD}' failed with error code: ${KEYCLOAK_TOKEN_RET}\n"
        return 1
    fi
    KEYCLOAK_TOKEN_HTTP_STATUS=$(echo "${KEYCLOAK_TOKEN_OUT}" | head -n 1)
    KEYCLOAK_TOKEN_HTTP_STATUS_CHECK=$(echo "${KEYCLOAK_TOKEN_HTTP_STATUS}" | grep -E -w "200")
    if [[ -z "${KEYCLOAK_TOKEN_HTTP_STATUS_CHECK}" ]] ; then
        >&2 echo -e "${KEYCLOAK_TOKEN_OUT}\n"
        >&2 echo -e "ERROR: '${KEYCLOAK_TOKEN_CMD}' did not return \"200\" status code as expected\n"
        return 1
    fi
    KEYCLOAK_TOKEN_JSON=$(echo "${KEYCLOAK_TOKEN_OUT}" | tail -n 1)
    KEYCLOAK_TOKEN_JSON_PARSED=$(echo "${KEYCLOAK_TOKEN_JSON}" | python3 -m json.tool)
    KEYCLOAK_TOKEN_JSON_PARSED_CHECK=$?
    if [[ ${KEYCLOAK_TOKEN_JSON_PARSED_CHECK} -ne 0 ]] ; then
        >&2 echo -e "${KEYCLOAK_TOKEN_OUT}\n"
        >&2 echo -e "ERROR: '${KEYCLOAK_TOKEN_CMD}' did not return parsable JSON structure as expected\n"
        return 1
    fi
    echo "${KEYCLOAK_TOKEN_JSON_PARSED}"
}

# extract_access_token <auth_token>
#
#   Use python to extract the "access_token" field of the supplied Keycloak authentication
#   token in JSON dictionary form. This field will need to be supplied in the authorization
#   headers of the curl HTTP requests being tested.
#
function extract_access_token()
{
    AUTH_TOKEN="${1}"
    if [[ -z "${AUTH_TOKEN}" ]] ; then
        >&2 echo "ERROR: No authentication token argument passed to extract_access_token() function"
        return 1
    fi
    ACCESS_TOKEN=$(python3 -c '
import json, sys
js = json.loads(sys.argv[1])
print(js["access_token"])
sys.exit(0)
        ' "${AUTH_TOKEN}")
    ACCESS_TOKEN_RET=$?
    if [[ ${ACCESS_TOKEN_RET} -ne 0 ]] || [[ -z "${ACCESS_TOKEN}" ]] ; then
        >&2 echo -e "${AUTH_TOKEN}\n"
        >&2 echo -e "ERROR: failed to extract \"access_token\" field from authentication token JSON structure\n"
        return 1
    fi
    echo "${ACCESS_TOKEN}"
}

# run_check_pod_status <pod_name_string>
function run_check_pod_status()
{
    POD_NAME_STRING="${1}"
    if [[ -z "${POD_NAME_STRING}" ]] ; then
        >&2 echo "ERROR: No pod name string argument passed to run_check_pod_status() function"
        return 1
    fi
    # HMS check_pod_status tool on NCN
    CHECK_POD_STATUS_PATH="/opt/cray/tests/ncn-resources/hms/hms-test/hms_check_pod_status_ncn-resources_remote-resources.sh"
    if [[ ! -x ${CHECK_POD_STATUS_PATH} ]] ; then
        >&2 echo "ERROR: failed to locate executable check_pod_status tool in run_check_pod_status(): ${CHECK_POD_STATUS_PATH}"
        # HMS check_pod_status tool in remote ct-portal container
        CHECK_POD_STATUS_PATH="/opt/cray/tests/remote-resources/hms/hms-test/hms_check_pod_status_ncn-resources_remote-resources.sh"
        if [[ ! -x ${CHECK_POD_STATUS_PATH} ]] ; then
            >&2 echo "ERROR: failed to locate executable check_pod_status tool in run_check_pod_status(): ${CHECK_POD_STATUS_PATH}"
            return 1
        fi
    fi
    CHECK_POD_STATUS_CMD="${CHECK_POD_STATUS_PATH} ${POD_NAME_STRING}"
    timestamp_print "Running '${CHECK_POD_STATUS_CMD}'..."
    CHECK_POD_STATUS_OUT=$(${CHECK_POD_STATUS_CMD})
    CHECK_POD_STATUS_RET=$?
    if [[ ${CHECK_POD_STATUS_RET} -ne 0 ]] ; then
        echo "${CHECK_POD_STATUS_OUT}"
        >&2 echo "ERROR: '${CHECK_POD_STATUS_CMD}' failed with error code: ${CHECK_POD_STATUS_RET}"
        return 1
    fi
}

# run_check_job_status <job_name_string>
function run_check_job_status()
{
    JOB_NAME_STRING="${1}"
    if [[ -z "${JOB_NAME_STRING}" ]] ; then
        >&2 echo "ERROR: No job name string argument passed to run_check_job_status() function"
        return 1
    fi
    # HMS check_job_status tool on NCN
    CHECK_JOB_STATUS_PATH="/opt/cray/tests/ncn-resources/hms/hms-test/hms_check_job_status_ncn-resources_remote-resources.sh"
    if [[ ! -x ${CHECK_JOB_STATUS_PATH} ]] ; then
        >&2 echo "ERROR: failed to locate executable check_job_status tool in run_check_job_status(): ${CHECK_JOB_STATUS_PATH}"
        # HMS check_job_status tool in remote ct-portal container
        CHECK_JOB_STATUS_PATH="/opt/cray/tests/remote-resources/hms/hms-test/hms_check_job_status_ncn-resources_remote-resources.sh"
        if [[ ! -x ${CHECK_JOB_STATUS_PATH} ]] ; then
            >&2 echo "ERROR: failed to locate executable check_job_status tool in run_check_job_status(): ${CHECK_JOB_STATUS_PATH}"
            return 1
        fi
    fi
    CHECK_JOB_STATUS_CMD="${CHECK_JOB_STATUS_PATH} ${JOB_NAME_STRING}"
    timestamp_print "Running '${CHECK_JOB_STATUS_CMD}'..."
    CHECK_JOB_STATUS_OUT=$(${CHECK_JOB_STATUS_CMD})
    CHECK_JOB_STATUS_RET=$?
    if [[ ${CHECK_JOB_STATUS_RET} -ne 0 ]] ; then
        echo "${CHECK_JOB_STATUS_OUT}"
        >&2 echo "ERROR: '${CHECK_JOB_STATUS_CMD}' failed with error code: ${CHECK_JOB_STATUS_RET}"
        return 1
    fi
}
