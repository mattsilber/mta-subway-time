import Config

# Add configuration that is only needed when running on the host here.

config :mta_subway_time, :scenic_config, [
  name: :main_viewport,
  size: {800, 480},
  default_scene: MtaSubwayTime.Scene.Schedule,
  drivers: [
    [
      module: Scenic.Driver.Local,
      name: :local,
      window: [
        resizeable: false,
        title: "MTA Subway Times"
      ],
      on_close: :stop_system,
    ]
  ]
]

config :logger,
       level: :debug

config :logger, :console,
       format: "$date $time [$level] $message\n",
       colors: [info: :green]