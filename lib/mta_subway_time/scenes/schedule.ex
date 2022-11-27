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

  @spec handle_info(:refresh, Scenic.Scene) :: {:no_reply, Scenic.Scene}
  def handle_info(:refresh, scene) do
    Logger.info("Refreshing...")

    graph =
      scene.assigns.graph
      |> modify_title(:name_1, scene)

    state =
      scene
      |> assign(graph: graph)
      |> push_graph(graph)

    {:noreply, scene}
  end

  @spec modify_title(Scenic.Graph, atom(), Scenic.Scene) :: Scenic.Graph
  defp modify_title(graph, name, scene) do
    target = Enum.at(MtaSubwayTime.subway_line_targets(), scene.assigns.target_index)

    Graph.modify(
      graph,
      name,
      &text(
        &1,
        title(target) |> IO.inspect,
        font_size: 22,
        translate: {10, 14},
        fill: :white
      )
    )
  end

  defp title(%{line: line, stop_id: stop_id, direction: direction}) do
    case MtaSubwayTime.Networking.Data.get(line, stop_id, direction) do
      nil ->
        "Loading train schedule..."
      stop ->
        title(stop)
    end
  end

  @spec title(MtaSubwayTime.Models.SubwayLineStop) :: String
  defp title(stop) do
    "#{stop.line}: #{stop.stop_id} @ #{stop.arrivals |> hd()}"
  end
end