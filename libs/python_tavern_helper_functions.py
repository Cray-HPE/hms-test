"""
MIT License

(C) Copyright [2019-2022] Hewlett Packard Enterprise Development LP

Permission is hereby granted, free of charge, to any person obtaining a
copy of this software and associated documentation files (the "Software"),
to deal in the Software without restriction, including without limitation
the rights to use, copy, modify, merge, publish, distribute, sublicense,
and/or sell copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR
OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.
HMS CT Framework Test Library

A library of python functions to support testing of Shasta HMS APIs within the CT Framework.

Author: Mitch Schooler
"""

def get_bmc_xname_from_first_node_xname(components):
    return {"xname": components.json()["Components"][0]["ID"].split("n")[0]}

def get_nodemap_first_id(nodemap):
    return {"ID": nodemap.json()["NodeMaps"][0]["ID"]}

def get_scn_subscription_first_id(subscription_list):
    return {"ID": subscription_list.json()["SubscriptionList"][0]["ID"]}
