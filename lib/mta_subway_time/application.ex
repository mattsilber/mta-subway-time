defmodule MtaSubwayTime.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: MtaSubwayTime.Supervisor]

    children =
      [
        # Children for all targets
        # Starts a worker by calling: MtaSubwayTime.Worker.start_link(arg)
        # {MtaSubwayTime.Worker, arg}
        MtaSubwayTime.Networking.Data,
        {MtaSubwayTime.Networking.Api, name: MtaSubwayTime.Networking.Api},
        {Scenic, [scenic_start_config()]},
      ] ++ children(target())

    Supervisor.start_link(children, opts)
  end

  # List all child processes to be supervised
  def children(:host) do
    [
      # Children that only run on the host
      # Starts a worker by calling: MtaSubwayTime.Worker.start_link(arg)
      # {MtaSubwayTime.Worker, arg},
    ]
  end

  def children(_target) do
    [
      # Children for all targets except host
      # Starts a worker by calling: MtaSubwayTime.Worker.start_link(arg)
      # {MtaSubwayTime.Worker, arg}
    ]
  end

  def target() do
    Application.get_env(:mta_subway_time, :target)
  end

  defp scenic_start_config do
    Application.get_env(:mta_subway_time, :scenic_config)
  end
end
