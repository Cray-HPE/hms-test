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
