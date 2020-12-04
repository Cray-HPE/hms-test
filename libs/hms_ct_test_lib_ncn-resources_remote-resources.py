"""
Copyright 2020 Hewlett Packard Enterprise Development LP

HMS CT Framework Test Library

A library of python functions to support testing of Shasta HMS APIs within the CT Framework.

Author: Mitch Schooler
"""

def get_bmc_xname_from_first_node_xname(components):
    return {"xname": components.json()["Components"][0]["ID"].split("n")[0]}
