include default.mk

windows-docker-build:
	make -f makefile.win docker-build

windows-docker-run:
	make -f makefile.win docker-run

nix-docker-build:
	make -f makefile.nix docker-build

nix-docker-run:
	make -f makefile.nix docker-run