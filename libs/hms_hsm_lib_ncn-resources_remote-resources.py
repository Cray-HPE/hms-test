"""
Copyright 2019-2020 Hewlett Packard Enterprise Development LP

CT Framework HSM Test Library

A library of python functions to support testing of Shasta HSM APIs within the CT Framework.

Author: Mitch Schooler
"""

def get_nodemap_first_id(nodemap):
    return {"ID": nodemap.json()["NodeMaps"][0]["ID"]}

def get_scn_subscription_first_id(subscription_list):
    return {"ID": subscription_list.json()["SubscriptionList"][0]["ID"]}
