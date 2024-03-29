# This file is responsible for configuring your application and its
# dependencies.
#
# This configuration file is loaded before any dependency and is restricted to
# this project.
import Config

# Enable the Nerves integration with Mix
Application.start(:nerves_bootstrap)

config :mta_subway_time, target: Mix.target()

config :mta_subway_time, :subway_lines, [
  %{
    line: "F",
    stop_id: "F24N",
    direction: "Manhatten",
  },
]

config :mta_subway_time, gtfs_api_key: System.get_env("GTFS_API_KEY")
config :mta_subway_time, google_transit_data: System.get_env("GOOGLE_TRANSIT_DATA")
config :mta_subway_time, transit_data_timezone: System.get_env("TRANSIT_DATA_TIMEZONE")

# The name of the network interface to check network status
config :mta_subway_time, network_interface_name: "eth0"

# Customize non-Elixir parts of the firmware. See
# https://hexdocs.pm/nerves/advanced-configuration.html for details.

config :nerves, :firmware, rootfs_overlay: "rootfs_overlay"

# Set the SOURCE_DATE_EPOCH date for reproducible builds.
# See https://reproducible-builds.org/docs/source-date-epoch/ for more information

config :nerves, source_date_epoch: "1668866892"

config :nerves_time, await_initialization_timeout: :timer.seconds(5)

config :scenic, :assets, module: MtaSubwayTime.Assets

if Mix.target() == :host do
  import_config "host.exs"
else
  import_config "target.exs"
end

# Ensure our test configs override our normal host configs
if config_env() == :test do
  import_config "test.exs"
end
