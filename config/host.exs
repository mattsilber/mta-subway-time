import Config

# Add configuration that is only needed when running on the host here.

config :mta_subway_time, :viewport, %{
  name: :main_viewport,
  default_scene: {MtaSubwayTime.Scene.Schedule, nil},
  size: {800, 480},
  opts: [scale: 1.0],
  drivers: [
    %{
      module: Scenic.Driver.Local,
      opts: [title: "MIX_TARGET=host, app = :mta_subway_time"],
      window: [title: "MTA Subway Time", resizeable: true]
    }
  ]
}

config :logger,
       level: :debug

config :logger, :console,
       format: "$date $time [$level] $message\n",
       colors: [info: :green]