# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

<!--
Guiding Principles:
* Changelogs are for humans, not machines.
* There should be an entry for every single version.
* The same types of changes should be grouped.
* Versions and sections should be linkable.
* The latest version comes first.
* The release date of each version is displayed.
* Mention whether you follow Semantic Versioning.

Types of changes:
Added - for new features
Changed - for changes in existing functionality
Deprecated - for soon-to-be removed features
Fixed - for any bug fixes
Removed - for now removed features
Security - in case of vulnerabilities
-->

## [5.3.0] - 2025-03-13

### Changed

- Removed activate/deactivate from Dockerfile as not needed
- Restored original contents of legacy pytest Dockerfile as pinned versions required

## [5.2.0] - 2025-03-12

### Security

- Updated image dependencies for security updates
- Updated Dockerfiles to install python packages via virtual environment due to image update
- Fixed Makefile so pytest image can be built locally
- Removed deprecated Version from docker compose file
- Updated 'docker-compose' to 'docker compose' references in test script

## [5.1.0] - 2023-06-26

### Added

- Added base URL for system-power-capping service.

## [5.0.0] - 2023-01-12

### Changed

- The smoke tests now run under pytest.
- Added allure-pytest library to enable test report generation when running pytest.

## [4.0.0] - 2022-09-13

### Added

- converted notion of 'functional' tests to what they really are 'tavern' invocations.

## [3.2.0] - 2022-07-19

### Changed

- kill the istio sidecar after the tests run to save wait time
- remove build dependencies from final test image
- revert back to alpine:3.15 base image to resolve CVEs

## [3.1.0] - 2022-06-15

### Changed

- run integration test workflow on pushes
- update to pytest:7.1.2 and tavern:1.23.1 to work around python:3.10 regression issue43798
- add packages required to build latest test image
- clean up documentation for developing tavern tests in a live kubernetes environment
- pull alpine base image from algol60 csm-docker/stable

## [3.0.0] - 2022-04-05

### Deprecated

- this no longer builds an RPM; this now builds a docker image that will be used by other test containers

### Added

- this build the hms-pytest legacy image
- builds in github actions
- global configuration defaults are provided.
- includes a runIntegration.sh script which will run the example smoke/functional tests
- added base URL for cray-power-control service.
- rebuilt hms-test image for security updates to fix Alpine vulnerabilities.

### Changed

- major redesign. This moves to a plug-n-play model: the functional test and smoke test executions are provided by hms-test.
- example smoke test and functional tests are provided.

## [1.11.0] - 2022-01-13

### Changed

- CASMHMS-5312 - Updated hms-pytest image location for Nexus.

## [1.10.0] - 2021-11-18

### Changed

- CASMHMS-5205 - Reorder CT smoke test execution order.

## [1.9.0] - 2021-10-27

### Changed

- CASMHMS-5055 - Updated hms-test infrastructure for separate CT test RPMs per service.

## [1.8.5] - 2021-09-29

### Changed

- Changed to work with a non-root docker image.

## [1.8.4] - 2021-09-01

### Changed

- CASMHMS-5128 - Updated cmd/hms-pytest wrapper to pull hms-pytest:1.6.1 instead of hms-pytest:1.1.1.

## [1.8.3] - 2021-07-28

### Changed

- GitHub migration phase #3 changes.

## [1.8.2] - 2021-07-22

### Added

- Added new Jenkinsfile and Makefile for migration to GitHub from Stash.

## [1.8.1] - 2021-06-22

### Added

- CASMHMS-4672 - Added support for DST's test results processing API.

## [1.8.0] - 2021-06-18

### Changed

- Bumped minor version for CSM 1.2 release branch.

## [1.7.0] - 2021-06-18

### Changed

- Bumped minor version for CSM 1.1 release branch.

## [1.6.0] - 2021-04-08

### Changed

- CASMHMS-4681 - Updated hms-test spec file to be branch aware.

## [1.5.3] - 2021-03-31

### Added

- CASMHMS-3973 - Added job checker tool and supporting infrastructure.

## [1.5.2] - 2021-02-05

### Changed

- CASMHMS-4478 - Updated hms-pytest to pull image from local NCN registry instead of DTR.

## [1.5.1] - 2021-02-01

### Changed

- Added MIT license to all files that required it.

## [1.5.0] - 2021-01-29

### Changed

- CASMHMS-4372 - Updated hms-pytest to use podman instead of containerd.
- CASMHMS-4351 - Package and use HMS version of pod checker tool.
- CASMHMS-4325 - Removed Badger and PMDBD repositories from HMS CT test deployment.
- CASMHMS-4349 - Added HMS CT test runner scripts.
- Made changes to support testing on PIT nodes.

## [1.4.0] - 2021-01-14

### Changed

- Updated license file.

## [1.3.2] - 2020-12-01

### Removed

- CASMHMS-3717 - Removed the tavern-beta-new-traceback pytest option since it is now the default setting.

## [1.3.1] - 2020-11-16

### Changed

- CASMHMS-3018 - Updated hms-pytest to use containerd instead of docker.
- CASMHMS-4154 - Specify python3 instead of python for CT test utilities.

## [1.3.0] - 2020-09-16

### Added

- CASMHMS-3956 - Added support for CT testing from remote ct-pipelines containers.

## [1.2.3] - 2020-07-27

### Added

- CASMHMS-3819 - Added pod/job check function for Badger CT smoke test.

## [1.2.2] - 2020-06-29

### Changed

- CASMHMS-3611 - Updated CT smoke test library for service liveness/readiness probes.

## [1.2.1] - 2020-06-24

### Removed

- CASMHMS-3574 - Removed hms-fw-update from list of CT test repositories as part of FUS deprecation.

## [1.2.0] - 2020-06-18

### Changed

- CASMHMS-3597 - Changed CT test RPM name to include 'crayctldeploy' for proper deployment.

## [1.1.0] - 2020-06-09

### Added

- CASMHMS-3536 - Package HMS CT tests in their own RPM for the ct-tests product stream.

## [1.0.1] - 2020-05-20

### Changed

- CASMHMS-3485 - Update HMS pytest ini and common files for SCSD testing.

## [1.0.0] - 2020-04-20

### Added

- CASMHMS-2990 - Initial release version.
