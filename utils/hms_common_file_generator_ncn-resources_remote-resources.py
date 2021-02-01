#!/usr/bin/env python3
#
# MIT License

# (C) Copyright [2018-2021] Hewlett Packard Enterprise Development LP

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
#     TOOL IDENTIFIER   : common_file_generator
#
#     DESCRIPTION       : This tool generates a pytest configuration file based
#                         on supplied inputs to be used for Tavern API testing
#                         allowing variables and other data used by Tavern to
#                         be easily shared across multiple tests.
#
#     SYNOPSIS
#       hms_common_file_generator_ncn-resources_remote-resources.py \
#           -b base_url \
#           -f output_file \
#           -a access_token \
#           -v verify \
#           -o bmc_basic_auth_orig \
#           -p bmc_password_orig \
#           -n bmc_basic_auth_new \
#           -m bmc_password_new
#
#       Arguments:            Description:
#         -b, --base_url              The base url for the target API endpoint
#         -f, --file                  The output file path for the generated configuration file
#         -a, --access_token          The Keycloak authentication token
#         -v, --verify                The SSL certificate check flag
#         -o, --bmc_basic_auth_orig   The original basic BMC authentication header token
#         -p, --bmc_password_orig     The original BMC password
#         -n, --bmc_basic_auth_new    The new basic BMC authentication header token
#         -m, --bmc_password_new      The new BMC password
#
#     AUTHOR            : Mitch Schooler, Isa Wazirzada
#
#     DATE STARTED      : 09/2018
#
#     UPDATE HISTORY
#       user          date       description
#       ----------------------------------------------------------------
#       iwazirzada    09/2018    Initial check-in
#       schooler      09/2019    Added access_token option, updated header
#       schooler      10/2019    Switch from SMS to NCN naming convention
#       schooler      05/2020    Added BMC basic authentication and password options
#       schooler      09/2020    Package utility in remote-resources
#       schooler      09/2020    Add verify parameter support
#       schooler      11/2020    Specify python3 instead of python
#
#     BUGS/LIMITATIONS
#       None
#
###############################################################

import yaml
import argparse

# Set up the command line parser
parser = argparse.ArgumentParser(description='A tool for generating Tavern configuration files')

# Define command line arguments
parser.add_argument('-b', '--base_url', action='store', required=True,
                        help='The base url for the API under test')
parser.add_argument('-f', '--file', action='store', required=True,
                        help='The path to the output file')
parser.add_argument('-a', '--access_token', action='store', required=True,
                        help='The API authentication access token')
parser.add_argument('-v', '--verify', action='store', required=True,
                        help='The SSL certificate check flag')
parser.add_argument('-o', '--bmc_basic_auth_orig', action='store', required=False,
                        help='Original basic BMC authentication header token')
parser.add_argument('-p', '--bmc_password_orig', action='store', required=False,
                        help='Original BMC password')
parser.add_argument('-n', '--bmc_basic_auth_new', action='store', required=False,
                        help='New basic BMC authentication header token')
parser.add_argument('-m', '--bmc_password_new', action='store', required=False,
                        help='New BMC password')

# Parse the command line arguments
arguments = parser.parse_args()
base_url = arguments.base_url
file_path = arguments.file
access_token = arguments.access_token
verify = arguments.verify
bmc_basic_auth_orig = arguments.bmc_basic_auth_orig
bmc_password_orig = arguments.bmc_password_orig
bmc_basic_auth_new = arguments.bmc_basic_auth_new
bmc_password_new = arguments.bmc_password_new

# Define the template dictionary
template_dictionary = {}
template_dictionary["name"] = "Autogenerated Common File"
template_dictionary["description"] = "Common file generated by hms_common_file_generator_ncn-resources_remote-resources.py"
template_dictionary["variables"] = {}

# Set the configuration file values to user-provided input values
template_dictionary['variables']['access_token'] = access_token
template_dictionary['variables']['base_url'] = base_url
template_dictionary['variables']['verify'] = verify
template_dictionary['variables']['bmc_basic_auth_orig'] = bmc_basic_auth_orig
template_dictionary['variables']['bmc_password_orig'] = bmc_password_orig
template_dictionary['variables']['bmc_basic_auth_new'] = bmc_basic_auth_new
template_dictionary['variables']['bmc_password_new'] = bmc_password_new

# Output the YAML content into a file
output = yaml.dump(template_dictionary, allow_unicode=True, default_flow_style=False)
with open(file_path, 'w') as fp:
    fp.write(output)
