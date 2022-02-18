# HMS Continuous Test (CT) Base Infrastructure Repository

This repository contains the docker image `hms-test` that is inherited by the `continious test` images.  The image contains pytest, tavern, python, and a few support scripts and common configurations used by tavern invocations.
This is a MAJOR redisign (v3); go see v1 code for how the RPMs were created.
This repository also contains a dockerfile for `hms-pytest` which is the legacy way of executing CT rpms.   
