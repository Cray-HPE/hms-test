# Most smoke tests are the same, however, smd_smoke_test_discovery_status_ncn-smoke in hms-smd/test/ct is not


# TODO; convert this to python, or not :) but use it for the smoke test idea:
#
#
# #!/bin/bash -l
#
# # timestamp_print <message>
# function timestamp_print()
# {
#     echo "($(date +"%H:%M:%S")) $1"
# }
#
# # Print a URL to be used for an API call. The basic usage is:
# #
# #   url [http|https] [<port_number>] <target_uri>
# #
# # Only the <target_uri> argument is required.
# # E.g. target uri: apis/smd/hsm/v1/Inventory/ComponentEndpoints
# function url()
# {
# # handle optional leading http[s] argument
# if [[ $# -gt 1 ]] && [[ "$1" == "http" ]] ; then
# shift
# HTTP="http"
# elif [[ $# -gt 1 ]] && [[ "$1" == "https" ]] ; then
# shift
# HTTP="https"
# else
# HTTP="https"
# fi
#
# # build up target URL
# if [[ $# -eq 1 ]] ; then
# echo "${HTTP}://${TARGET}/$1"
# elif [[ $# -eq 2 ]] ; then
# echo "${HTTP}://${TARGET}:$1/$2"
# else
# >&2 echo "ERROR: Invalid number of arguments passed to url() function"
# return 1
# fi
# }
#
# # run_curl <http_operation> [curl_args]
# #
# #   Make a curl call and verify that the status code is 200 or 204. Return 0 if it is, else return
# #   1 and echo an error message containing the response code and the error line from the curl output.
# #   The first argument you pass into it has to be the argument to curl’s -X flag (i.e. the type of
# #   request: GET, POST, etc). Any other arguments are just passed through to the curl command.
# #
# #   Global variable dependencies:
# #
# #       CURL_ARGS           Leading command line arguments to supply to curl call
# #       CURL_COUNT          Running total of number of curl calls made during a test run
# #       OUTPUT_FILES_PATH   Path to writable filesystem location for temporary curl output files
# #
# function run_curl()
# {
# ((CURL_COUNT++))
# CURL_OUTFILE="${OUTPUT_FILES_PATH}.curl${CURL_COUNT}.tmp"
# CURL_CMD="curl -k ${CURL_ARGS} -o ${CURL_OUTFILE} -X $@"
# _run_curl "${CURL_CMD}"
# }
#
# # _run_curl <curl_cmd>
# #
# #   Pass the entire command to run as "$1". It must ultimately generate curl "-i"
# #   output and store it in the file $CURL_OUTFILE on this host. The output is then
# #   checked for a 200 or 204 response code. Return 0 if it is, else return 1 and echo an
# #   error message that contains the status code and the error line from the curl output.
# #
# function _run_curl()
# {
# CMD="$1"
# timestamp_print "Testing '${CMD}'..."
# CMD_OUT=$(eval "${CMD}" 2>&1)
# RET=$?
# if [[ -n ${CMD_OUT} ]] ; then
# echo "${CMD_OUT}"
# fi
# if [[ ${RET} -ne 0 ]] ; then
# >&2 echo -e "ERROR: '${CMD}' failed with error code: ${RET}\n"
# return 1
# fi
# STATUS_CODE_LINE=$(head -1 ${CURL_OUTFILE})
# STATUS_CHECK=$(echo "${STATUS_CODE_LINE}" | grep -E -w "200|204")
# if [[ -z "${STATUS_CHECK}" ]] ; then
# echo "${STATUS_CODE_LINE}"
# >&2 echo -e "ERROR: '${CMD}' did not return \"200\" or \"204\" status code as expected\n"
# return 1
# fi
# }
#




