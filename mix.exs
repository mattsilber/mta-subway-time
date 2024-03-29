defmodule MtaSubwayTime.MixProject do
  use Mix.Project

  @app :mta_subway_time
  @version "0.1.0"
  @all_targets [:rpi, :rpi0, :rpi2, :rpi3, :rpi3a, :rpi4, :bbb, :osd32mp1, :x86_64, :grisp2]

  def project do
    [
      app: @app,
      version: @version,
      elixir: "~> 1.11",
      archives: [nerves_bootstrap: "~> 1.11"],
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      deps_path: System.get_env("MIX_DEPS_PATH") || "deps",
      releases: [{@app, release()}],
      preferred_cli_target: [run: :host, test: :host]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {MtaSubwayTime.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # Dependencies for all targets
      {:nerves, "~> 1.9.0", runtime: false},
      {:shoehorn, "~> 0.9.1"},
      {:ring_logger, "~> 0.8.6"},
      {:toolshed, "~> 0.2.26"},

      # Nerves.Time to ensure clock is synchronized on embedded devices
      {:nerves_time, "~> 0.4"},

      # Nerves.Network to check network status
      {:nerves_network_interface, "~> 0.4.6"},

      # Dependencies for all targets except :host
      {:nerves_runtime, "~> 0.13.0", targets: @all_targets},
      {:nerves_pack, "~> 0.7.0", targets: @all_targets},

      # Dependencies for specific targets
      # NOTE: It's generally low risk and recommended to follow minor version
      # bumps to Nerves systems. Since these include Linux kernel and Erlang
      # version updates, please review their release notes in case
      # changes to your application are needed.
      {:nerves_system_rpi, "~> 1.21", runtime: false, targets: :rpi},
      {:nerves_system_rpi0, "~> 1.21", runtime: true, targets: :rpi0},
      {:nerves_system_rpi2, "~> 1.21", runtime: false, targets: :rpi2},
      {:nerves_system_rpi3, "~> 1.21", runtime: false, targets: :rpi3},
      {:nerves_system_rpi3a, "~> 1.21", runtime: false, targets: :rpi3a},
      {:nerves_system_rpi4, "~> 1.21", runtime: false, targets: :rpi4},
      {:nerves_system_bbb, "~> 2.16", runtime: false, targets: :bbb},
      {:nerves_system_osd32mp1, "~> 0.12", runtime: false, targets: :osd32mp1},
      {:nerves_system_x86_64, "~> 1.21", runtime: false, targets: :x86_64},
      {:nerves_system_grisp2, "~> 0.5", runtime: false, targets: :grisp2},

      # Scenic for displaying train schedules
      {:scenic, "~> 0.11"},
      {:scenic_driver_local, "~> 0.11"},

      # Httpoison for networking
      {:httpoison, "~> 1.8"},
      
      # Protobuf for Google
      {:protobuf, "~> 0.10.0"},
      {:google_protos, "~> 0.1"},

      # Nimble for reading CSV files into structs
      {:nimble_csv, "~> 1.2.0"},

      # Date parsing
      {:timex, "~> 3.0"},

      # Parsing RGB values....
      {:chameleon, "~> 2.2.0"},

      # VintageNet for connecting to network
      {:vintage_net_wifi, "~> 0.11.3", targets: @all_targets},

      # Upload the firmware using SSH / FWUP
      {:nerves_ssh,"~> 0.4.1", targets: @all_targets},
      {:ssh_subsystem_fwup,"~> 0.6.1", targets: @all_targets},
    ]
  end

  def release do
    [
      overwrite: true,
      # Erlang distribution is not started automatically.
      # See https://hexdocs.pm/nerves_pack/readme.html#erlang-distribution
      cookie: "#{@app}_cookie",
      include_erts: &Nerves.Release.erts/0,
      steps: [&Nerves.Release.init/1, :assemble],
      strip_beams: Mix.env() == :prod or [keep: ["Docs"]]
    ]
  end
end
