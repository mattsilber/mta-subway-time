# MtaSubwayTime

**TODO: Add description**

## Targets

Nerves applications produce images for hardware targets based on the
`MIX_TARGET` environment variable. If `MIX_TARGET` is unset, `mix` builds an
image that runs on the host (e.g., your laptop). This is useful for executing
logic tests, running utilities, and debugging. Other targets are represented by
a short name like `rpi3` that maps to a Nerves system image for that platform.
All of this logic is in the generated `mix.exs` and may be customized. For more
information about targets see:

https://hexdocs.pm/nerves/targets.html#content

## Getting Started

To start your Nerves app:
  * `export MIX_TARGET=my_target` or prefix every command with
    `MIX_TARGET=my_target`. For example, `MIX_TARGET=rpi3`
  * Install dependencies with `mix deps.get`
  * Create firmware with `mix firmware`
  * Burn to an SD card with `mix burn`

## Learn more

  * Official docs: https://hexdocs.pm/nerves/getting-started.html
  * Official website: https://nerves-project.org/
  * Forum: https://elixirforum.com/c/nerves-forum
  * Discussion Slack elixir-lang #nerves ([Invite](https://elixir-slackin.herokuapp.com/))
  * Source: https://github.com/nerves-project/nerves


## Windows setup

Follow these [instructions](https://medium.com/@jeffborch/running-the-scenic-elixir-gui-framework-on-windows-10-using-wsl-f9c01fd276f6) for setting up a WSL instance.

Inside the created WSL instance, run `./scripts/wsl_setup.sh` to install everything required to build this project and run with Windows as the GUI host.

WSL won't have permissions to write to the directory, so just adjust the deps and build paths to somewhere mix does have access to, e.g.:

```sh
MIX_BUILD_PATH=~/build \
  MIX_DEPS_PATH=~/deps \
  MIX_TARGET=host \
  mix run --no-halt
```