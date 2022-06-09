# MIT License
#
# (C) Copyright [2019-2022] Hewlett Packard Enterprise Development LP
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

FROM artifactory.algol60.net/docker.io/alpine:3

LABEL maintainer="Hewlett Packard Enterprise"
STOPSIGNAL SIGTERM

# Install the necessary packages.
RUN set -ex \
    && apk -U upgrade \
    && apk add --no-cache \
        python3 \
        python3-dev \
        py3-pip \
        bash \
        curl \
        tar \
        gcc \
        musl-dev

#TODO: need to verify HMS Tavern tests w/ these latest versions of pytest and tavern
RUN pip3 install --upgrade \
    pip \
    pytest==7.1.2 \
    tavern==1.23.1 \
    pytest-tap

COPY cmd/hms-pytest /usr/bin/hms-pytest
COPY cmd/entrypoint.sh /usr/bin/entrypoint.sh
COPY cmd/smoke_test.py /src/app/smoke_test.py
COPY cmd/functional_test.py /src/app/functional_test.py
COPY libs/ /src/libs
COPY libs/pytest.ini /src/app/pytest.ini

# Run as nobody
RUN chown -R 65534:65534 /src
USER 65534:65534

WORKDIR /src/app
ENTRYPOINT [ "entrypoint.sh" ]