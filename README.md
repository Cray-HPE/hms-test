# HMS Continuous Test (CT) Base Infrastructure Repository

This repository contains base infrastructure (RPM build, shared libraries, utilities, etc) required to deploy and execute the HMS CT tests that live in other HMS repositories along with the services that they verify. The hms-ct-test-base.spec file generates hms-ct-test-base RPMs which are installed on Shasta system NCNs and provide infrastructure expected by the HMS CT tests during runtime. The hms-ct-test-base RPM by itself does not include tests for HMS services.
