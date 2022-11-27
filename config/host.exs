import Config

# Add configuration that is only needed when running on the host here.

config :mta_subway_time, :scenic_config, [
  name: :main_viewport,
  size: {800, 480},
  default_scene: MtaSubwayTime.Scene.Schedule,
  drivers: [
  # Uncomment to actually run locally not through Docker
    [
      module: Scenic.Driver.Local,
      name: :local,
      window: [
        resizeable: false,
        title: "MTA Subway Times"
      ],
    ]
  ]
]

config :logger,
       level: :debug

config :logger, :console,
       format: "$date $time [$level] $message\n",
       colors: [info: :green]