# MIT License

# (C) Copyright [2020-2021] Hewlett Packard Enterprise Development LP

# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included
# in all copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR
# OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
# ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.

Name: hms-ct-test-crayctldeploy
License: Cray Software License Agreement
Summary: HMS Continuous Test deployment
Group: System/Management
Version: %(cat .version) 
Release: %(echo ${BUILD_METADATA})
Source: %{name}-%{version}.tar.bz2
Vendor: Cray Inc.
BuildRequires: git

%define test_dir /opt/cray/tests
%define commands /usr/bin

%description
This package contains files necessary to deploy the HMS CT tests.

%prep
%setup -q

%build
repo_dir=$(mktemp -d)
repos=(
    hms/hms-bss
    hms/hms-capmc
    hms/hms-firmware-action
    hms/hms-hmcollector
    hms/hms-hmi-nfd
    hms/hms-hmi-service
    hms/hms-meds
    hms/hms-redfish-translation-layer
    hms/hms-reds
    hms/hms-scsd
    hms/hms-sls
    hms/hms-smd
    hms/hms-test
)
tests_list=(
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

echo "Copying CT tests to %{buildroot}%{test_dir}..."

for repo in ${repos[@]} ; do
    echo "Cloning $repo into $repo_dir/$repo..."
    git clone --depth 1 https://stash.us.cray.com/scm/"$repo".git "${repo_dir}"/"${repo}"

    for test in ${tests_list[@]} ; do
        find ${repo_dir}/${repo} -name "*${test}*" -exec mkdir -p %{buildroot}%{test_dir}/${test}/${repo}/ \; \
           -exec cp -v {} %{buildroot}%{test_dir}/${test}/${repo}/ \;
    done
done

echo "Cleaning up temporary repo directory..."
rm -rf ${repo_dir}

%install
install -m 755 -d %{buildroot}%{commands}/

# All commands from this project
cp -r cmd/* %{buildroot}%{commands}/

%files

# CT tests
%dir %{test_dir}
%{test_dir}/*

# CT-related commands
%dir %{commands}
%{commands}/*

%changelog
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
