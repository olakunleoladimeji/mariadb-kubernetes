DOCKER_REPO  ?= gcr.io/dbaas-development
MARIADB_CLUSTER ?= sa-test
IMAGE_NAME := mariadb-test
VERSION := 0.0.2
IMAGE := $(DOCKER_REPO)/$(IMAGE_NAME)

.PHONY: help

help:
	@echo "Usage: make test MARIADB_CLUSTER=<cluster-name>"

build-image:
	build/docker-build.sh "$(IMAGE)" "$(VERSION)"

push-image: build-image
	build/docker-push.sh "$(IMAGE)" "$(VERSION)"

test: push-image
	build/kubernetes-run.sh "$(MARIADB_CLUSTER)" "$(IMAGE):$(VERSION)"
#	$(sed -e "s/\\$\\(MARIADB_CLUSTER\\)/$(MARIADB_CLUSTER)/g" -e "s/\\$\\(IMAGE\\)/$(IMAGE)/g" | kubectl create -f ./test-job.yaml)
#	$(kubectl wait --for=condition=complete job/$(MARIADB_CLUSTER)-sanity)
