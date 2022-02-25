# HMS Continuous Test (CT) Base Infrastructure Repository

This is a MAJOR redisign (v3); go see v1 code for how the RPMs were created.
This repository contains the docker image `hms-test` that is inherited by the `continious test` images (eg: `cray-fimrware-action-test` in `hms-firmware-action` repo.
The image contains pytest, tavern, python, and execution scripts for smoke/functional tests.  This image also includes the default configuration files (that can be overridden).
This repository also contains a dockerfile for `hms-pytest` which is the legacy way of executing CT rpms.   
