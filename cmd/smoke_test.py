#!/usr/bin/env python3

# MIT License
#
# (C) Copyright [2022-2023] Hewlett Packard Enterprise Development LP
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

import argparse
import logging
import signal
import subprocess


def signal_handler(sig, frame):
    logging.fatal("received kill signal, exiting...")
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
    parser.add_argument('-p', '--path', action='store', default="/src/app/smoke_pytest",
                        help='Directory containing the pytest tests')
    parser.add_argument('-a', '--allure-dir', action='store', required=False,
                        help='Directory to store Allure')
    # This is a FLAG only.  Many ways to do this: https://www.pythonpool.com/python-argparse-boolean/
    parser.add_argument('-x', '--exit', action='store_true', default=False,
                        help='Should the application abort tests on first error')

    # Parse the command line arguments
    args = parser.parse_args()
    smoke_json_file = args.file
    override_url = args.url
    allure_dir = args.allure_dir
    test_dir = args.path
    exit_on_first_failure = args.exit


    logging.basicConfig(format='%(asctime)s %(message)s',
                        level=logging.DEBUG)
    logging.Formatter(fmt='%(asctime)s.%(msecs)03d', datefmt='%Y-%m-%d,%H:%M:%S')

    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGHUP, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)



    #######################
    ##  RUN TESTS
    #######################
    try:
        cmd = ["pytest", "-vvvv", test_dir, "--smoke-json", smoke_json_file]
        if override_url is not None and len(override_url) != 0:
            cmd += ["--smoke-url", override_url]
        if allure_dir is not None:
            cmd += ["--alluredir", allure_dir]
        if exit_on_first_failure:
            cmd += ["-x"]
        pytest_run = subprocess.run(cmd, check=True)
    except Exception as e:

        logging.error("FAIL")
        exit(1)
    logging.info("PASS")
