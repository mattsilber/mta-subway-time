include default.mk

docker-run:
	docker run --rm -it \
	    -v $(shell pwd):/workspace \
	    -v /tmp/.X11-unix:/tmp/.X11-unix \
	    -w /workspace \
	    -e DISPLAY=$DISPLAY \
	    $(IMAGE_NAME)