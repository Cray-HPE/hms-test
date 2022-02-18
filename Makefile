NAME ?= hms-test
VERSION ?= $(shell cat .version)

all: image

image:
	docker build --pull ${DOCKER_ARGS} --tag '${NAME}:${VERSION}' .

#this repo also builds the legacy pytest image, in case you need it!
pytest:
	docker build --pull ${DOCKER_ARGS} -f Dockerfile.hms-pytest --tag 'hms-pytest:${VERSION}' .