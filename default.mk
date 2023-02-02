IMAGE_NAME := mta-subway-time

docker-build:
	docker build -t $(IMAGE_NAME) .

run-host-test:
	MIX_TARGET=host mix test