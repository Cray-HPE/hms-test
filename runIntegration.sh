#!/usr/bin/env bash

# MIT License
#
# (C) Copyright [2021-2022,2025] Hewlett Packard Enterprise Development LP
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

set -x

# Configure docker compose
export COMPOSE_PROJECT_NAME=$RANDOM
export COMPOSE_FILE=docker-compose.integration.yaml

echo "COMPOSE_PROJECT_NAME: ${COMPOSE_PROJECT_NAME}"
echo "COMPOSE_FILE: $COMPOSE_FILE"


function cleanup() {
  docker compose down
  if [[ $? -ne 0 ]]; then
    echo "Failed to decompose environment!"
    exit 1
  fi
  exit $1
}


echo "Starting containers..."
docker compose build
if [[ $? -ne 0 ]]; then
  echo "Failed to build images!"
  cleanup 1
fi

docker compose up --exit-code-from smoke_test smoke_test
test_result=$?

# Clean up
echo "Cleaning up containers..."
if [[ $test_result -ne 0 ]]; then
  echo "Integration smoke tests FAILED!"
  cleanup 1
fi

docker compose up --exit-code-from tavern_test tavern_test
test_result=$?

# Clean up
echo "Cleaning up containers..."
if [[ $test_result -ne 0 ]]; then
  echo "Integration tavern tests FAILED!"
  cleanup 1
fi

echo "Integration tests PASSED!"
cleanup 0
