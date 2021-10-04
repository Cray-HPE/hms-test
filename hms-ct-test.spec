# MIT License
#
# (C) Copyright [2020-2021] Hewlett Packard Enterprise Development LP
#
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included
# in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR
# OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
# ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.

Name: hms-ct-test
License: MIT
Summary: HMS CT test supporting infrastructure
Group: System/Management
Version: %(cat .version) 
Release: %(echo ${BUILD_METADATA})
Source: %{name}-%{version}.tar.bz2
Vendor: Hewlett Packard Enterprise

# name of this repository
%define REPO hms-test

# test installation location
%define TEST_DIR /opt/cray/tests

# command installation location
%define COMMANDS /usr/bin

%description
This package contains shared libraries and utilities used by the HMS CT tests.

%prep
%setup -q

%build
# Categories of CT test files to install
TEST_BUCKETS=(
    ncn-smoke
    ncn-functional
    ncn-long
    ncn-destructive
    ncn-resources
    remote-smoke
    remote-functional
    remote-long
    remote-destructive
    remote-resources
)

echo "Current directory is: ${PWD}..."

echo "Searching for CT test files..."
for BUCKET in ${TEST_BUCKETS[@]} ; do
    find . -name "*${BUCKET}*" -exec mkdir -p %{buildroot}%{TEST_DIR}/${BUCKET}/hms/${REPO}/ \; \
       -exec cp -v {} %{buildroot}%{TEST_DIR}/${BUCKET}/hms/${REPO}/ \;
done

%install
install -m 755 -d %{buildroot}%{COMMANDS}/

# All commands from this project
cp -r cmd/* %{buildroot}%{COMMANDS}/

%files

# CT test files
%dir %{TEST_DIR}
%{TEST_DIR}/*

# CT test-related commands
%dir %{COMMANDS}
%{COMMANDS}/*

%changelog
* Mon Oct 04 2021 Mitch Schooler <mitchell.schooler@hpe.com>
- Updated hms-test infrastructure for separate CT test RPMs per service.
* Wed Jul 28 2021 Mitch Schooler <mitchell.schooler@hpe.com>
- Updated hms-test repository for migration to GitHub.
* Fri Jun 18 2021 Ryan Sjostrand <sjostrand@hpe.com>
- Bump minor version for CSM 1.2 release branch.
* Fri Jun 18 2021 Ryan Sjostrand <sjostrand@hpe.com>
- Bump minor version for CSM 1.1 release branch.
* Wed Apr 7 2021 Mitch Schooler <mitchell.schooler@hpe.com>
- Updated hms-test spec file to be branch aware.
* Tue Mar 30 2021 Mitch Schooler <mitchell.schooler@hpe.com>
- Added RTS repository to HMS CT test deployment.
* Fri Jan 22 2021 Mitch Schooler <mitchell.schooler@hpe.com>
- Removed Badger and PMDBD repositories from HMS CT test deployment.
* Wed Sep 16 2020 Mitch Schooler <mitchell.schooler@hpe.com>
- Added support for CT testing from remote ct-pipelines containers.
* Wed Jun 24 2020 Mitch Schooler <mitchell.schooler@hpe.com>
- Removed hms-fw-update from list of CT test repositories as part of FUS deprecation.
* Thu Jun 18 2020 Mitch Schooler <mitchell.schooler@hpe.com>
- Changed CT test RPM name to include 'crayctldeploy' for proper deployment.
* Tue Jun 9 2020 Mitch Schooler <mitchell.schooler@hpe.com>
- Moved CT test packaging from hms-install to hms-test repository for their own RPM build.
