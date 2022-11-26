include default.mk

docker-run:
	docker run -it -v $PWD:/workspace -w /workspace elixir-nerves-mtast