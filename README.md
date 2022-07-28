# HMS Continuous Test (CT) Base Infrastructure Repository

This is a MAJOR redesign (v3); see v1 code for how RPMs were previously packaged and deployed for testing in CSM-1.2 and earlier releases.
This repository contains the docker image `hms-test` that is inherited by the `continuous test` images (eg: `cray-firmware-action-test` in `hms-firmware-action` repo).
The image contains pytest, tavern, python, and execution scripts for smoke/functional tests. This image also includes the default configuration files (that can be overridden).
This repository also contains a dockerfile for `hms-pytest` which is the legacy way of executing CT RPMs.


# How to Test/Develop in a Kubernetes environment

This will describe some development tools that have been created to aid in rapid prototyping in a Kubernetes environment.

## How to install the development environment

1. Execute this script from an NCN in a tmp directory:

```setup_cray-hms-test-development.sh
#!/usr/bin/env bash

# Download the chart from artifactory. The raw source is: https://github.com/Cray-HPE/hms-test-charts/tree/main/charts/v1.0/cray-hms-test-development
wget https://artifactory.algol60.net/artifactory/csm-helm-charts/stable/cray-hms-test-development/cray-hms-test-development-1.0.1.tgz

# Upload the hms-test image to the system
export REMOTE_IMAGE=artifactory.algol60.net/csm-docker/stable/hms-test:3.2.0
export LOCAL_IMAGE=hms-test:3.2.0

NEXUS_USERNAME="$(kubectl -n nexus get secret nexus-admin-credential --template {{.data.username}} | base64 -d)"
NEXUS_PASSWORD="$(kubectl -n nexus get secret nexus-admin-credential --template {{.data.password}} | base64 -d)"

podman run --rm --network host quay.io/skopeo/stable \
    copy --dest-tls-verify=false docker://${REMOTE_IMAGE} docker://registry.local/csm-docker/stable/${LOCAL_IMAGE} \
    --dest-username "$NEXUS_USERNAME" \
    --dest-password "$NEXUS_PASSWORD"

echo

# Use helm to upgrade/install the chart
helm upgrade --install -n services cray-hms-test-development ./cray-hms-test-development-1.0.1.tgz
```

Output should look something like:

```
--2022-07-28 02:15:41--  https://artifactory.algol60.net/artifactory/csm-helm-charts/stable/cray-hms-test-development/cray-hms-test-development-1.0.1.tgz
Resolving artifactory.algol60.net (artifactory.algol60.net)... 34.120.105.219
Connecting to artifactory.algol60.net (artifactory.algol60.net)|34.120.105.219|:443... connected.
HTTP request sent, awaiting response... 200 OK
Length: 17671 (17K) [application/x-gzip]
Saving to: ‘cray-hms-test-development-1.0.1.tgz’

cray-hms-test-development-1.0.1.tgz                       100%[====================================================================================================================================>]  17.26K  --.-KB/s    in 0.01s

2022-07-28 02:15:41 (1.38 MB/s) - ‘cray-hms-test-development-1.0.1.tgz’ saved [17671/17671]

Trying to pull quay.io/skopeo/stable:latest...
Getting image source signatures
Copying blob 6590ad574cd4 done
Copying blob 3229a27b3890 done
Copying blob 528b87fb2c4e done
Copying blob 75f075168a24 done
Copying blob 3970ce8fd634 done
Copying config 2aa4e04998 done
Writing manifest to image destination
Storing signatures
Getting image source signatures
Copying blob sha256:abf4d74dda5185d214fcb6f021d469b5a77f658f15c750193ccae900b5e689be
Copying blob sha256:4551d438ec844bd88efcf09c6a0b3fc7e6a17eed7f9526b1d2e3a7bf432311bd
Copying blob sha256:92acb010721b2fd77128075e459deba71e65e20df36b75759276d110c19ebe67
Copying blob sha256:685a9b1372dd607371deca578c93945cb4bafa785f5f47be30d61c8176898811
Copying blob sha256:df9b9388f04ad6279a7410b85cedfdcb2208c0a003da7ab5613af71079148139
Copying blob sha256:6b5574c5400a49c9e8346c080519eedab4217d6b8e304699e494bf2a8ddb1918
Copying blob sha256:609656ff5830582882d16050a7a37ffad65b4c54817be825a29da81592074800
Copying blob sha256:d1d90b19f3020a7ad199467b4b773150fa330196475264f597140e6d7937c980
Copying blob sha256:7b04b77f68922a6ddbf20c88cd8bae8422d873b879a80f97c7c89db853175732
Copying blob sha256:4e5308d2b45f41b036623878979da8d2e7982bfd3e3ee44a9767fbd2844dc089
Copying blob sha256:4f4fb700ef54461cfa02571ae0db9a0dc1e0cdb5577484a6d75e68dc38e8acc1
Copying config sha256:66b3c40de9e6e6a1addbb2bca1756b4ae82f6c069c4d1b415908abcd82b0846e
Writing manifest to image destination
Storing signatures

Release "cray-hms-test-development" does not exist. Installing it now.
NAME: cray-hms-test-development
LAST DEPLOYED: Thu Jul 28 02:20:58 2022
NAMESPACE: services
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
Installation info for chart cray-hms-test-development:
```

## How to tell that the environment is working:

NOTE: it may take a few minutes for this to be ready and to setup the persistent volume claim (PVC). 

1. See if the deployment is operational:

```
ncn-m001 # kubectl -n services get deployment | grep -E "NAME|cray-hms-test-development"
NAME                                              READY   UP-TO-DATE   AVAILABLE   AGE
cray-hms-test-development                         1/1     1            1           51m
```

1. See if the pod is operational: 

NOTE: you will need the exact pod name from this output

```
ncn-m001 # kubectl -n services get pods | grep -E "NAME|cray-hms-test-development"
NAME                                                              READY   STATUS                  RESTARTS   AGE
cray-hms-test-development-6677f586dc-vp46b                        2/2     Running                 0          54m
```

1. To run the example smoke tests which will invoke a simple http response code checker, trigger the `entrypoint` script with the `smoke` argument from within the pod.
2. Pass in the `example_smoke.json` file with `-f` option.
3. Pass in the overloaded URL with `-u`.

```
ncn-m001 # kubectl -n services exec -i -t cray-hms-test-development-6677f586dc-vp46b -c cray-hms-test-development sh
/src/app $

/src/app $ entrypoint.sh smoke -f /src/libs/example_smoke.json -u http://httpbin.org
Running smoke tests...
2022-03-28 20:04:27,901 suite_name: example_smoke_tests
2022-03-28 20:04:27,901 file_path: /src/libs/example_smoke.json
2022-03-28 20:04:27,901 Running example_smoke_tests...
2022-03-28 20:04:27,901 default_url: http://httpbin.org
2022-03-28 20:04:27,901 override_url: http://httpbin.org
2022-03-28 20:04:27,902 configured_url: http://httpbin/
2022-03-28 20:04:27,902 Testing {"path": "/get?color=blue&size=big", "expected_status_code": 200, "method": "GET", "body": null, "headers": {}, "url": "http://httpbin.org/get?color=blue&size=big"}
2022-03-28 20:04:27,932 Starting new HTTP connection (1): httpbin.org:80
2022-03-28 20:04:28,031 http://httpbin.org:80 "GET /get?color=blue&size=big HTTP/1.1" 200 1682
2022-03-28 20:04:28,032 Testing {"path": "/post", "expected_status_code": 200, "method": "POST", "body": "HI THERE!", "headers": {"accept": "application/json", "custom-header": "just like this"}, "url": "http://httpbin.org/post"}
2022-03-28 20:04:28,069 Starting new HTTP connection (1): httpbin.org:80
2022-03-28 20:04:28,147 http://httpbin.org:80 "POST /post HTTP/1.1" 200 1745
2022-03-28 20:04:28,149 Testing {"path": "get?color=blue&size=big///", "expected_status_code": 200, "method": "GET", "body": null, "headers": {}, "url": "http://httpbin.org/get?color=blue&size=big///"}
2022-03-28 20:04:28,185 Starting new HTTP connection (1): httpbin.org:80
2022-03-28 20:04:28,261 http://httpbin.org:80 "GET /get?color=blue&size=big/// HTTP/1.1" 200 1694
2022-03-28 20:04:28,262 Testing {"path": "get?badreturncode=true", "expected_status_code": 200, "method": "GET", "body": null, "headers": {}, "url": "http://httpbin.org/get?badreturncode=true"}
2022-03-28 20:04:28,300 Starting new HTTP connection (1): httpbin.org:80
2022-03-28 20:04:28,375 http://httpbin.org:80 "GET /get?badreturncode=true HTTP/1.1" 200 1669
2022-03-28 20:04:28,376 MAIN_ERRORS = 0
2022-03-28 20:04:28,377 PASS: example_smoke_tests
2022-03-28 20:04:28,377 passed!
2022-03-28 20:04:28,377 PASS: example_smoke_tests passed!
```

## How to use the tools

1. Exec into the `cray-hms-test-development` pod (if you haven't already) and now you can use the tools.

```
ncn-m001 # kubectl -n services exec -i -t cray-hms-test-development-6677f586dc-vp46b -c cray-hms-test-development sh
/src/app $
```

1. To run functional tests which will invoke tavern via pytest, trigger the `entrypoint` script with the `functional` argument.
2. Pass in the tavern config file location using `-c`.
3. Point to the directory with the `test*.yaml` tavern tests with `-p`.

```
/src/app $ cp /src/libs/test_example_functional.tavern.yaml /src/app/

/src/app $ entrypoint.sh functional -c /src/libs/tavern_global_config_integration_test.yaml -p /src/app
Running functional tests...
================================================================= test session starts ==================================================================
platform linux -- Python 3.9.7, pytest-6.1.2, py-1.11.0, pluggy-0.13.1 -- /usr/bin/python3
cachedir: .pytest_cache
rootdir: /src/libs, configfile: pytest.ini
plugins: tap-3.3, tavern-1.12.2
collected 1 item

../libs/test_example_functional.tavern.yaml::Verify the service status resource PASSED                                                           [100%]

/src/app $ rm /src/app/test_example_functional.tavern.yaml
```

1. You should use the `/src/libs/tavern_global_config.yaml` file for functional tests that make calls to HMS services.
2. You will need to modify or add url paths in `/src/libs/tavern_global_config.yaml` to expose different APIs or include a separate file with updated paths.
3. The following example shows a simple HMS functional test for FAS (Firmware Action Service).

```
/src/app $ cat /src/libs/tavern_global_config.yaml | grep fas_base_url
  fas_base_url: http://cray-fas

/src/app $ cat /src/app/test_service_status.tavern.yaml
# Tavern test cases for the FAS service status API
# Author: Mitch Schooler
# Service: Firmware Action Service

# HMS test metrics test cases: 2
# 1. GET /service/status API response code
# 2. GET /service/status API response body
---
test_name: Verify the service status resource

stages:
  # 1. GET /service/status API response code
  # 2. GET /service/status API response body
  - name: Ensure that the FAS service status can be retrieved
    request:
      url: "{fas_base_url}/service/status"
      method: GET
      verify: !bool "{verify}"
    response:
      status_code: 200
      verify_response_with:
        function: tavern.testutils.helpers:validate_pykwalify
        extra_kwargs:
          schema:
            type: map
            required: True
            mapping:
              serviceStatus:
                type: str
                required: True
                enum:
                  - "running"

/src/app $ entrypoint.sh functional -c /src/libs/tavern_global_config.yaml -p /src/app
Running functional tests...
==================================================================================================== test session starts ====================================================================================================
platform linux -- Python 3.9.7, pytest-6.1.2, py-1.11.0, pluggy-0.13.1 -- /usr/bin/python3
cachedir: .pytest_cache
rootdir: /src/app, configfile: pytest.ini
plugins: tap-3.3, tavern-1.12.2
collected 1 item

test_service_status.tavern.yaml::Verify the service status resource PASSED                                                                                                                                            [100%]
```

## How to copy files into the pod's PVC

```
ncn-m001 # kubectl -n services cp {your file or directory} cray-hms-test-development-6677f586dc-vp46b:/src/data
```

NOTE: `/src/data` is where the 1gb PVC is mounted.

It is recommended to do development off cluster, then copy in files for rapid testing. However, the PVC is persistent, so if you put your data files in `/src/data` they should persist, assuming you don't delete the PVC.

## How to clean up and delete the PVC when you are COMPLETELY finished

```
ncn-m001 # helm uninstall -n services cray-hms-test-development
release "cray-hms-test-development" uninstalled
```

If you watch quickly, you can see the resources being terminated:

```
ncn-m001 # kubectl -n services get pods | grep -E "NAME|cray-hms-test-development"
NAME                                                              READY   STATUS                  RESTARTS   AGE
cray-hms-test-development-6677f586dc-vp46b                        2/2     Terminating             0          77m
```