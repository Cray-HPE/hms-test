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

#!/usr/bin/env python3

import json
import argparse
import requests
import unittest
import logging

if __name__ == '__main__':
    # Set up the command line parser
    parser = argparse.ArgumentParser(description='Simple HTTP based url requests to validate endpoint health')

    # Define command line arguments
    parser.add_argument('-f', '--file', action='store', required=True,
                        help='The path to the input file')
    # This is a FLAG only.  Many ways to do this: https://www.pythonpool.com/python-argparse-boolean/
    parser.add_argument('-x', '--exit', action='store_true', default=False,
                        help='Should the application abort tests on first error')

    # Parse the command line arguments
    arguments = parser.parse_args()
    exit_on_error = arguments.exit
    file_path = arguments.file

    logging.basicConfig(format='%(asctime)s %(message)s',
                         level=logging.INFO)
    logging.Formatter(fmt='%(asctime)s.%(msecs)03d', datefmt='%Y-%m-%d,%H:%M:%S')


    with open(file_path, 'r') as file:
        data = json.load(file)
    test_paths = data["test_paths"]
    suite_name = data["smoke_test_name"]

    test_case = unittest.TestCase()

    verificationErrors = []
    for test in test_paths:
        testing_msg = "Testing " + json.dumps(test)
        logging.info(testing_msg)
        req = requests.request(url=test["url"], method=str(test["method"]).upper(), data=test["body"],
                               headers=test["headers"])
        try:
            test_case.assertEqual(req.status_code, test["expected_status_code"], "unexpected status code.")
        except AssertionError as e:
            verificationErrors.append(str(e))
            fail_msg = "FAIL: " + str(e)
            logging.error((fail_msg))

            if exit_on_error:
                logging.error("aborting the rest of the tests")
                break


    final_string = ""
    final_line = ""
    main_error = "MAIN_ERRORS = " + str(len(verificationErrors))
    logging.info(main_error)
    if len(verificationErrors) > 0:
        final_string = "FAIL: " + suite_name
        final_line = "failed!"
        logging.error(final_string)
        logging.error(final_line)
    else:
        final_string = "PASS: " + suite_name
        final_line = "passed!"
        logging.info(final_string)
        logging.info(final_line)


    # throw a non-zero exit code if there were errors!
    exit(len(verificationErrors) > 0)
