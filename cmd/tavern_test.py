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
    logging.fatal("recieved kill signal, exiting...")
    exit(sig)


if __name__ == '__main__':
    #######################
    ##  CONFIGURE
    #######################
    # Set up the command line parser
    parser = argparse.ArgumentParser(description='Simple HTTP based url requests to validate endpoint health')

    # Define command line arguments
    parser.add_argument('-c', '--config', action='store', required=True,
                        help='The path to the Tavern global config file')
    parser.add_argument('-p', '--path', action='store', required=True,
                        help='Directory with the tavern tests')
    parser.add_argument('-a', '--allure-dir', action='store', required=False,
                        help='Directory to store Allure')

    # # Parse the command line arguments
    arguments = parser.parse_args()
    config_file = arguments.config
    tavern_test_dir = arguments.path

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
        cmd = ["pytest", "-vvvv", "--tavern-global-cfg=" + config_file, tavern_test_dir]
        if arguments.allure_dir is not None:
            cmd += ["--alluredir="+arguments.allure_dir]
        pytest_run = subprocess.run(cmd, check=True)
    except Exception as e:

        logging.error("FAIL")
        exit(1)
    logging.info("PASS")
