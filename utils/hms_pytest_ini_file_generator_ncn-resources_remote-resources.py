#!/usr/bin/env python3
#
# MIT License

# (C) Copyright [2019-2021] Hewlett Packard Enterprise Development LP

# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included
# in all copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR
# OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
# ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.
#
###############################################################
#
#     CASM Test - Cray Inc.
#
#     TOOL IDENTIFIER   : pytest_ini_file_generator
#
#     DESCRIPTION       : This tool generates a pytest.ini file based
#                         on supplied inputs to be used for Tavern API testing
#                         allowing variables and other data used by pytest and
#                         Tavern to be easily shared across multiple tests.
#
#     SYNOPSIS
#       hms_pytest_ini_file_generator_ncn-resources_remote-resources.py -f output_file
#
#       Arguments:            Description:
#         -f, --file            The output file path for the generated ini file
#
#     AUTHOR            : Mitch Schooler
#
#     DATE STARTED      : 12/17/2019
#
#     LAST MODIFIED     : 02/01/2021
#
#     UPDATE HISTORY
#       user       date         description
#       ----------------------------------------------------------------
#       schooler   12/17/2019   initial implementation
#       schooler   04/17/2020   ignore deprecation warnings
#       schooler   05/13/2020   ignore insecure request warnings
#       schooler   09/11/2020   package utility in remote-resources
#       schooler   11/16/2020   specify python3 instead of python
#       schooler   02/01/2021   remove default tavern-beta-new-traceback option
#
#     BUGS/LIMITATIONS
#       None
#
###############################################################

import argparse

# Set up the command line parser
parser = argparse.ArgumentParser(description='A tool for generating pytest.ini files')

# Define command line arguments
parser.add_argument('-f', '--file', action='store', required=True,
                        help='The path to the output file')

# Parse the command line arguments
arguments = parser.parse_args()
file_path = arguments.file

# Define the ini file data
output = """[pytest]
filterwarnings =
    ignore::FutureWarning
    ignore::DeprecationWarning
    ignore::urllib3.exceptions.InsecureRequestWarning
"""

# Write the ini data into a file
with open(file_path, 'w') as fp:
    fp.write(output)
