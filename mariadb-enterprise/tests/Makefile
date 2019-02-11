IMAGE_NAME  := mariadb-test
VERSION := 0.0.1
IMAGE := gcr.io/dbaas-development/$(IMAGE_NAME)

.PHONY: build-image

build-image:
	docker build . -t $(IMAGE):$(VERSION)
