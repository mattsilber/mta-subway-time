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

  defp title(%{line: line, stop_id: stop_id, direction: direction} = target) do
    current_date = DateTime.utc_now
    current_time_of_day_in_seconds = MtaSubwayTime.Networking.TimeConverter.date_to_seconds_in_day(current_date)

    arrival = MtaSubwayTime.Networking.StopTimes.next_stop_time_after_date(stop_id, current_date)
    |> MtaSubwayTime.Networking.StopTimes.subway_arrival(target)

    arrival_time_remaining =
      arrival
      |> (fn arrival -> seconds_until_arrival(arrival.arrival_time, current_time_of_day_in_seconds) end).()
      |> arrival_time_label

    "#{line}: #{stop_id} for #{arrival.trip_id} @ #{arrival_time_remaining}"
  end

  defp seconds_until_arrival(arrival_time, now) when now < arrival_time do
    arrival_time - now
  end

  defp seconds_until_arrival(arrival_time, now) do
    (86_400 - now) + arrival_time
  end

  defp arrival_time_label(seconds_until_arrival) when seconds_until_arrival < 61 do
    "#{seconds_until_arrival} seconds away"
  end

  defp arrival_time_label(seconds_until_arrival) when seconds_until_arrival < 121 do
    "Less than 2 minutes away"
  end

  defp arrival_time_label(seconds_until_arrival) do
    "~#{rem(seconds_until_arrival, 60)} minutes away"
  end

end