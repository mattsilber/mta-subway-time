defmodule MtaSubwayTime.Scene.Schedule do
  require Logger
  use Scenic.Scene
  alias Scenic.Graph
  alias Scenic.ViewPort
  import Scenic.Primitives
  import Scenic.Components

  @refresh_rate_ms 5 * 1000

  @graph Graph.build()
         |> text(
              "Loading train schedule...",
              font_size: 22,
              translate: {10, 14},
              fill: :white,
              id: :name_1
            )

  def init(scene, _params, _options) do
    Logger.info("Scene init...")

    {:ok, refresh_timer} = :timer.send_interval(@refresh_rate_ms, :refresh)

    scene =
      scene
      |> assign(
           graph: @graph,
           target_index: 0,
           last_subway_line_update_ms: 0,
           refresh_timer: refresh_timer
         )
      |> push_graph(@graph)

    {:ok, scene}
  end

  def handle_info(:refresh, state) do
    Logger.info("Refreshing...")

    graph =
      state.graph
      |> modify_title(:name_1, state)

    state =
      state
      |> assign(graph: graph)
      |> push_graph(graph)

    {:noreply, state}
  end

  defp modify_title(graph, name, %{target_index: target_index}) do
    target = elem(MtaSubwayTime.subway_line_targets(), target_index)

    Graph.modify(
      graph,
      name,
      text(
        graph,
        title(target) |> IO.inspect,
        font_size: 22,
        translate: {10, 14},
        fill: :white
      )
    )
  end

  defp title(%{line: line, stop_id: stop_id, direction: direction}) do
    stop = MtaSubwayTime.Networking.Data.get(MtaSubwayTime.Networking.Data, line, stop_id, direction)

    title(
      stop
    )
  end

  @spec title(MtaSubwayTime.Models.SubwayLineStop) :: String
  defp title(stop) do
    "#{stop.line}: #{stop.stop_id} @ #{stop.arrivals |> hd()}"
  end
end