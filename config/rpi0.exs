import Config

config :mta_subway_time, :scenic_config, [
  name: :main_viewport,
  size: {800, 480},
  default_scene: MtaSubwayTime.Scene.Schedule,
  opts: [
    scale: 1.0
  ],
  drivers: [
    [
      module: Scenic.Driver.Local,
      name: :local,
      position: [
        scaled: true,
        centered: true,
        orientation: :normal
      ],
    ]
  ]
]