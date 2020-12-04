#!/usr/bin/env python3
#
# Copyright 2019-2020 Hewlett Packard Enterprise Development LP
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
#     LAST MODIFIED     : 11/16/2020
#
#     UPDATE HISTORY
#       user       date         description
#       ----------------------------------------------------------------
#       schooler   12/17/2019   initial implementation
#       schooler   04/17/2020   ignore deprecation warnings
#       schooler   05/13/2020   ignore insecure request warnings
#       schooler   09/11/2020   package utility in remote-resources
#       schooler   11/16/2020   specify python3 instead of python
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
tavern-beta-new-traceback = True
filterwarnings =
    ignore::FutureWarning
    ignore::DeprecationWarning
    ignore::urllib3.exceptions.InsecureRequestWarning
"""

# Write the ini data into a file
with open(file_path, 'w') as fp:
    fp.write(output)
