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

%define TEST_DIR /opt/cray/tests
%define COMMANDS /usr/bin

%description
This package contains files necessary to deploy the HMS CT tests.

%prep
%setup -q

%build
REPO_DIR=$(mktemp -d)
REPOS=(
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

# Determine which branch to pull CT tests from
CURRENT_BRANCH=$(git branch | grep -E "^\*" | cut -d " " -f 2)
echo "Current branch is: ${CURRENT_BRANCH}"
CURRENT_COMMIT=$(git rev-parse --verify HEAD)
echo "Current commit is: ${CURRENT_COMMIT}"

BRANCH_HIERARCHY=(
    ${CURRENT_BRANCH}
    develop
    master
)

# Check if we are building a PR in Jenkins
CURRENT_BRANCH_PR_CHECK=$(echo ${CURRENT_BRANCH} | grep -E "^PR-[0-9]+") || true
if [[ -n ${CURRENT_BRANCH_PR_CHECK} ]] ; then
    BRANCHES_AT_HEAD=$(git ls-remote --heads origin | grep ${CURRENT_COMMIT} | awk '{print $2}')
    echo "Branches at head commit: ${BRANCHES_AT_HEAD}"

    # Remove non-feature branches
    BRANCHES_AT_HEAD=$(echo "${BRANCHES_AT_HEAD}" | grep -v "master")
    BRANCHES_AT_HEAD=$(echo "${BRANCHES_AT_HEAD}" | grep -v "develop")

    while IFS= read -r BRANCH ; do
        # Extract the branch name by removing 'refs/heads/' from the beginning of the line
        BRANCH=$(echo ${BRANCH} | cut -c 12- )
        echo "Adding branch '${BRANCH}' to branch hierarchy..."
        BRANCH_HIERARCHY=(${BRANCH} ${BRANCH_HIERARCHY[@]})
    done <<< "${BRANCHES_AT_HEAD}"
fi

echo "Branch Hierarchy: ${BRANCH_HIERARCHY[@]}"

echo "Copying CT tests to %{buildroot}%{TEST_DIR}..."
for REPO in ${REPOS[@]} ; do
    echo "Cloning ${REPO} into ${REPO_DIR}/${REPO}..."
    git clone --depth 1 --no-single-branch https://stash.us.cray.com/scm/"${REPO}".git "${REPO_DIR}"/"${REPO}"

    echo "Changing directories into ${REPO_DIR}/${REPO}..."
    cd ${REPO_DIR}/${REPO}
    CURRENT_DIRECTORY=$(pwd)
    echo "Current directory is: ${CURRENT_DIRECTORY}..."

    for BRANCH in ${BRANCH_HIERARCHY[@]} ; do
        echo "Attempting to checkout branch ${BRANCH}..."
        git checkout ${BRANCH}
        if [[ $? -eq 0 ]] ; then
            echo "Successfully checked out branch ${BRANCH}..."
            break
        else
            echo "Could not find branch ${BRANCH}..."
            if [[ "${BRANCH}" == "master" ]] ; then
                echo "All out of possible branches... exiting" >&2
                exit 1
            fi
        fi
    done

    echo "Searching ${REPO_DIR}/${REPO} on branch ${BRANCH}for CT tests..."
    for TEST in ${TEST_BUCKETS[@]} ; do
        find ${REPO_DIR}/${REPO} -name "*${TEST}*" -exec mkdir -p %{buildroot}%{TEST_DIR}/${TEST}/${REPO}/ \; \
           -exec cp -v {} %{buildroot}%{TEST_DIR}/${TEST}/${REPO}/ \;
    done
done

echo "Cleaning up temporary repo directory..."
rm -rf ${REPO_DIR}

%install
install -m 755 -d %{buildroot}%{COMMANDS}/

# All commands from this project
cp -r cmd/* %{buildroot}%{COMMANDS}/

%files

# CT tests
%dir %{TEST_DIR}
%{TEST_DIR}/*

# CT-related commands
%dir %{COMMANDS}
%{COMMANDS}/*

%changelog
* Wed Apr 7 2021 Mitch Schooler <mitchell.schooler@hpe.com>
- Updated spec file to be branch aware.
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
