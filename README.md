# HMS Continuous Test (CT) Base Infrastructure Repository

This is a MAJOR redesign (v3); see v1 code for how RPMs were previously packaged and deployed for testing in CSM-1.2 and earlier releases.
This repository contains the docker image `hms-test` that is inherited by the `continuous test` images (eg: `cray-firmware-action-test` in `hms-firmware-action` repo.
The image contains pytest, tavern, python, and execution scripts for smoke/functional tests.  This image also includes the default configuration files (that can be overridden).
This repository also contains a dockerfile for `hms-pytest` which is the legacy way of executing CT rpms.   


# How to Test/Develop in a kubernetes environment

This will describe some development tools that have been created to aid in rapid prototyping in a kubernetes environment.

## How to install the development environment

1. Execute this script from an NCN in a tmp directory:

```setup_cray-hms-test-development.sh
#!/usr/bin/env bash
#download the chart from artifactory. The raw source is: https://github.com/Cray-HPE/hms-test-charts/tree/main/charts/v1.0/cray-hms-test-development
wget https://artifactory.algol60.net/artifactory/csm-helm-charts/stable/cray-hms-test-development/cray-hms-test-development-1.0.0.tgz

#upload the hms-test image to the system
export REMOTE_IMAGE=artifactory.algol60.net/csm-docker/stable/hms-test:3.0.0
export LOCAL_IMAGE=hms-test:3.0.0

NEXUS_USERNAME="$(kubectl -n nexus get secret nexus-admin-credential --template {{.data.username}} | base64 -d)"
NEXUS_PASSWORD="$(kubectl -n nexus get secret nexus-admin-credential --template {{.data.password}} | base64 -d)"

podman run --rm --network host quay.io/skopeo/stable \
    copy --dest-tls-verify=false docker://${REMOTE_IMAGE} docker://registry.local/csm-docker/stable/${LOCAL_IMAGE} \
    --dest-username "$NEXUS_USERNAME" \
    --dest-password "$NEXUS_PASSWORD"

#use helm to upgrade/install the chart
helm upgrade --install -n services cray-hms-test-development ./cray-hms-test-development-1.0.0.tgz
```

Output should look something like:

```
--2022-03-28 20:21:11--  https://artifactory.algol60.net/artifactory/csm-helm-charts/stable/cray-hms-test-development/cray-hms-test-development-1.0.0.tgz
Resolving artifactory.algol60.net (artifactory.algol60.net)... 34.120.105.219
Connecting to artifactory.algol60.net (artifactory.algol60.net)|34.120.105.219|:443... connected.
HTTP request sent, awaiting response... 200 OK
Length: 17671 (17K) [application/x-gzip]
Saving to: ‘cray-hms-test-development-1.0.0.tgz.1’

cray-hms-test-development-1.0.0.tgz.1 100%[=========================================================================>]  17.26K  --.-KB/s    in 0.01s

2022-03-28 20:21:11 (1.33 MB/s) - ‘cray-hms-test-development-1.0.0.tgz.1’ saved [17671/17671]

Getting image source signatures
Copying blob sha256:3aa4d0bbde192bfaba75f2d124d8cf2e6de452ae03e55d54105e46b06eb8127e
Copying blob sha256:defb6b2bb024703a6d221086b7718a0ed2801058ca1ee9ca4305e3c2d590c647
Copying blob sha256:530d8982cc424f38053f7942ba83843739aeeccc8c70a99fb156a964719292f3
Copying blob sha256:235ceb423e67f551977e1abac28d2eaae26e50a020e0972a28ca4b8d897178be
Copying blob sha256:1b01ea1be8aca3fd95873b99083e97482c88374c6d648eef8031dc339c88ce2a
Copying blob sha256:38f8e7472ea57428cc374eba8974cd1e340f69cb9fbba58bc036b8f9e6d52ab3
Copying blob sha256:00f71969241bae02a4c5a8382fb32a6634e142e6cc780f6a9a21dbdceb77ce7f
Copying blob sha256:b31b23df732d346b415e55c50f13261f5767ff01ad54abdf5dadc5a2cff46e01
Copying blob sha256:2ac4b606308fae3b514bfadcb7b1a9b5666e8fa13849d568e1a85d2907ff7137
Copying blob sha256:4f4fb700ef54461cfa02571ae0db9a0dc1e0cdb5577484a6d75e68dc38e8acc1
Copying blob sha256:f0548e2cebadd91eb72e7ed4be37462f87973ebb11717fd739a28f6be63161c5
Copying config sha256:4c881529d3e1d1dcf95c20645b2310571873bc0519278bd61c260fa3064ae6e6
Writing manifest to image destination
Storing signatures
Release "cray-hms-test-development" does not exist. Installing it now.
NAME: cray-hms-test-development
LAST DEPLOYED: Mon Mar 28 20:21:15 2022
NAMESPACE: services
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
Installation info for chart cray-hms-test-development
```

## How to tell that the environment is working:

NOTE: it may take a few minutes for this to be ready and to setup the persistent volume claim (PVC). 

1. See if the deployment is operational:

```
ncn-m001:~/anieuwsma/hms-test # kubectl -n services get deployment  | grep -E "NAME|cray-hms-test-development"
NAME                                              READY   UP-TO-DATE   AVAILABLE   AGE
cray-hms-test-development                         1/1     1            1           51m
```

1. See if the pod is operational: 

NOTE: you will need the exact pod name from this output

```
ncn-m001:~/anieuwsma/hms-test # kubectl -n services get pods | grep -E "NAME|cray-hms-test-development"
NAME                                                              READY   STATUS                  RESTARTS   AGE
cray-hms-test-development-6677f586dc-vp46b                        2/2     Running                 0          54m
```

## How to use the tools

1. Exec into the pod and now you can use the tools

```
kubectl -n services exec -i -t cray-hms-test-development-6677f586dc-vp46b sh
/src/app $
```

1. You need to modify the `tavern_global_config_integration_test.yaml` to look like this...

```
/src/app $ cat /src/libs/tavern_global_config_integration_test.yaml
# This file contains the base common configurations for running pytest tavern tests.  It is statically generated,
#  because we anticipate the same settings for all ct-test  containers that inherit from it.
name: tavern_global_configuration #is this needed, used?
description: common configuration for all tavern invocations
variables:
  verify: false #should ssl verification happen in tavern tests? its hard coded everywhere to false (partially because the PIT would complain)
  base_url: http://httpbin.org/
```

1. To run functional tests which will invoke tavern via pytest, trigger the `entrypoint` script with the `functional` argument.
2. Pass in the tavern config file location using `-c`
3. Point to the directory with the `test*.yaml` tavern tests with `-p`

```
/src/app $ entrypoint.sh functional -c /src/libs/tavern_global_config_integration_test.yaml -p /src/app
Running functional tests...
================================================================= test session starts ==================================================================
platform linux -- Python 3.9.7, pytest-6.1.2, py-1.11.0, pluggy-0.13.1 -- /usr/bin/python3
cachedir: .pytest_cache
rootdir: /src/libs, configfile: pytest.ini
plugins: tap-3.3, tavern-1.12.2
collected 1 item

../libs/test_example_functional.tavern.yaml::Verify the service status resource PASSED                                                           [100%]

```

1. To run the smoke tests which will invoke a simple http response code checker, trigger the `entrypoint` script with the `smoke` argument.
2. Pass in the `example_smoke.json` file with `-f` option
3. Pass in the overloaded URL with `-u`

```
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
/src/app $
```

1. You will most likely use the `/src/libs/tavern_global_config.yaml` file with the functional tests (that invoke pytest + tavern)
2. You will need to modify or add url paths in `/src/libs/tavern_global_config.yaml` to expose different APIs or include a separate file with updated paths.

## How to copy files into the pod's PVC

```
kubectl -n services cp {your file or directory} cray-hms-test-development-6677f586dc-vp46b:/src/data
```

NOTE: `/src/data` is where the 1gb PVC is mounted.

I recommend you do most development off cluster, then copy in files for rapid testing.  However, the PVC is persistent, so if you put your data files in `/src/data` they should persist, assuming you don't delete the PVC.

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