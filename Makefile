MAKEFILE := $(abspath $(lastword $(MAKEFILE_LIST)))
MAKEFILE_DIR := $(dir $(MAKEFILE))

docker-build:
	docker build -t elixir-nerves .

docker-run:
	docker run -it -v $(MAKEFILE_DIR):/workspace -w /workspace elixir-nerves