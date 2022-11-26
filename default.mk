docker-build:
	docker build -t elixir-nerves-mtast .

run-host-test:
	MIX_TARGET=host mix test