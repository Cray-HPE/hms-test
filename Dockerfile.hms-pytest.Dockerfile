# MIT License
#
# (C) Copyright [2019-2022,2025] Hewlett Packard Enterprise Development LP
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

FROM artifactory.algol60.net/docker.io/alpine:3.21
LABEL maintainer="Hewlett Packard Enterprise"
STOPSIGNAL SIGTERM

# Install the necessary packages.
RUN set -ex \
    && apk -U upgrade \
    && apk add --no-cache \
        python3 \
        py3-pip \
        python3-dev \
        gcc \
        musl-dev \
        libffi-dev \
        openssl-dev \
        make \
        cython

RUN python3 -m venv /opt/venv \
    && . /opt/venv/bin/activate \
    && pip3 install --upgrade \
       pip \
       pytest==6.1.2 \
       tavern==1.12.2 \
       pytest-tap \
    && deactivate \
    && apk del \
	python3-dev \
	gcc \
	musl-dev \
        libffi-dev \
        openssl-dev \
        make \
	cython

# Set the PATH to include the virtual environment
ENV PATH="/opt/venv/bin:$PATH"

# nobody 65534:65534
USER 65534:65534
