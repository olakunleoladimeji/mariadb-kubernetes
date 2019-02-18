DOCKER_REPO  ?= gcr.io/dbaas-development
DOCKER_REPO  = docker.io/nastybuff
MARIADB_CLUSTER ?= zeppelin-sandbox
THREADS ?= 16
IMAGE_NAME := mariadb-zeppelin-sandbox
VERSION := 0.0.4
IMAGE := $(DOCKER_REPO)/$(IMAGE_NAME)
DATABASE_SERVICE ?= database_service
.PHONY: help

help:
	@echo "Usage: make sandbox MARIADB_CLUSTER=<cluster-name>\n

build-image:
	build/docker-build.sh "$(IMAGE)" "$(VERSION)"

push-image: build-image
	build/docker-push.sh "$(IMAGE)" "$(VERSION)"

sandbox: push-image
	build/kubernetes-run.sh "$(MARIADB_CLUSTER)" "$(IMAGE):$(VERSION)" sandbox 4G
