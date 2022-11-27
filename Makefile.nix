include default.mk

docker-run:
	docker run --rm -it -v $PWD:/workspace -w /workspace $(IMAGE_NAME)