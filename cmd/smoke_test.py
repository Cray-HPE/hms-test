#!/usr/bin/env python3

# MIT License
#
# (C) Copyright [2022] Hewlett Packard Enterprise Development LP
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

# Most smoke tests are the same, however, smd_smoke_test_discovery_status_ncn-smoke in hms-smd/test/ct is not


import json
import argparse
import requests
import unittest
import logging
from urllib.parse import urljoin
import signal
import os
import traceback


def signal_handler(sig, frame):
    logging.fatal("recieved kill signal, exiting...")
    exit(sig)


if __name__ == '__main__':
    #######################
    ##  CONFIGURE
    #######################
    # Set up the command line parser
    parser = argparse.ArgumentParser(description='Simple HTTP based url requests to validate endpoint health')

    # Define command line arguments
    parser.add_argument('-f', '--file', action='store', required=True,
                        help='The path to the input file')
    parser.add_argument('-u', '--url', action='store', required=False,
                        help='Override the default URL specified in the file')
    # This is a FLAG only.  Many ways to do this: https://www.pythonpool.com/python-argparse-boolean/
    parser.add_argument('-x', '--exit', action='store_true', default=False,
                        help='Should the application abort tests on first error')

    # Parse the command line arguments
    arguments = parser.parse_args()
    exit_on_error = arguments.exit
    file_path = arguments.file
    override_url = arguments.url

    logging.basicConfig(format='%(asctime)s %(message)s',
                        level=logging.DEBUG)
    logging.Formatter(fmt='%(asctime)s.%(msecs)03d', datefmt='%Y-%m-%d,%H:%M:%S')

    with open(file_path, 'r') as file:
        data = json.load(file)
    test_paths = data["test_paths"]
    configured_url = data["default_base_url"]
    suite_name = data["smoke_test_name"]

    logging.debug("suite_name: %s", suite_name)
    logging.debug("file_path: %s", file_path)

    logging.info("Running %s...", (suite_name))

    default_url = ""

    if override_url is not None and len(override_url) > 0:
        default_url = override_url
    else:
        default_url = configured_url

    logging.debug("default_url: %s", default_url)
    logging.debug("override_url: %s", override_url)
    logging.debug("configured_url: %s", configured_url)

    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGHUP, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)

    #######################
    ##  RUN TESTS
    #######################
    test_case = unittest.TestCase()

    verificationErrors = []
    for test in test_paths:
        url = urljoin(default_url, test["path"])
        test["url"] = url
        testing_msg = "Testing " + json.dumps(test)
        logging.info(testing_msg)

        try:

            req = requests.request(url=url, method=str(test["method"]).upper(), data=test["body"],
                                   headers=test["headers"])  # Could return requests.exceptions.RequestException

            test_case.assertEqual(req.status_code, test["expected_status_code"],
                                  "unexpected status code.")  # could return an AssertionError
        except Exception as e:
            verificationErrors.append(str(e))
            fail_msg = "FAIL: " + str(e)
            logging.error((fail_msg))
            #logging.error(traceback.format_exc())

            if exit_on_error:
                logging.error("aborting the rest of the tests")
                break

    #######################
    ##  LOG RESULTS
    #######################
    final_string = ""
    final_line = ""
    main_error = "MAIN_ERRORS = " + str(len(verificationErrors))
    logging.info(main_error)
    if len(verificationErrors) > 0:
        final_string = "FAIL: " + suite_name
        final_line = "failed!"
        fail_suite = "FAIL: " + suite_name + " ran with failures"
        logging.error(final_string)
        logging.error(final_line)
        logging.error(fail_suite)
    else:
        final_string = "PASS: " + suite_name
        final_line = "passed!"
        final_suite = "PASS: " + suite_name + " passed!"
        logging.info(final_string)
        logging.info(final_line)
        logging.info(final_suite)

    # throw a non-zero exit code if there were errors!
    exit(len(verificationErrors) > 0)
