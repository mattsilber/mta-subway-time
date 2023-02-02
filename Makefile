include default.mk

windows-docker-run:
	make -f Makefile.win docker-run

windows-docker-run-with-x:
	make -f Makefile.win docker-run-with-x

nix-docker-run:
	make -f Makefile.nix docker-run