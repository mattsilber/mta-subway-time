# MtaSubwayTime

## Windows Docker Setup

Launch XLaunch instance:
[XLaunch](https://x.cygwin.com/docs/xlaunch/index.html)

## Mac Docker Setup

```
brew install glew
brew install glfw
```

Launch Quartz instance:
[Quartz](https://gist.github.com/cschiewek/246a244ba23da8b9f0e7b11a68bf3285), with [original instructions](https://gist.github.com/cschiewek/246a244ba23da8b9f0e7b11a68bf3285)


## Google Transit Data

To download the latest google transit data used to load the base schedules, run:

```sh
./scripts/update_google_transit_data.sh
```

## Docker

### Docker Build

```
make docker-build
```

### Run on Windows

```
make windows-docker-run-with-x
```

### Run on Mac

```
make nix-docker-run
```

## ENV

Edit `.bashrc` in container or WSL instance and fill in values:
```
export GTFS_API_KEY=
export GOOGLE_TRANSIT_DATA=
export TRANSIT_DATA_TIMEZONE=America/New_York
export AUTHORIZED_SSH_KEY=
```

## Running Locally

```sh
MIX_BUILD_PATH=~/build \
  MIX_DEPS_PATH=~/deps \
  MIX_TARGET=host \
  mix run --no-halt
```