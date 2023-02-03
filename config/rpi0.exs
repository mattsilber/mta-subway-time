import Config

config :mta_subway_time, :viewport, %{
  name: :main_viewport,
  default_scene: {MtaSubwayTime.Scene.Schedule, nil},
  size: {800, 480},
  opts: [scale: 1.0],
  drivers: [
    %{
      module: Scenic.Driver.Nerves.Rpi
    },
  ]
}