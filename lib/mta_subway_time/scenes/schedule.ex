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
              "Loading schedule...",
              font_size: 28,
              translate: {12, 32},
              fill: :white,
              id: :line_name
            )
         |> text(
              "",
              font_size: 22,
              translate: {12, 56},
              fill: :white,
              id: :time_remaining
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

    target = Enum.at(MtaSubwayTime.subway_line_targets(), scene.assigns.target_index)

    current_date = DateTime.utc_now
    current_time_of_day_in_seconds = MtaSubwayTime.Networking.TimeConverter.date_to_seconds_in_day(current_date)

    arrival =
      MtaSubwayTime.Networking.StopTimes.next_stop_time_after_date(target.stop_id, current_date)
      |> MtaSubwayTime.Networking.StopTimes.subway_arrival(target)

    arrival_time_remaining =
      arrival
      |> (fn arrival -> seconds_until_arrival(arrival.arrival_time, current_time_of_day_in_seconds) end).()
      |> arrival_time_label

    IO.inspect("Line #{target.line} | Stop #{target.stop_id} | Trip #{arrival.trip_id} | Arrives #{arrival_time_remaining}")

    graph =
      scene.assigns.graph
      |> modify_line_name(scene, target)
      |> modify_time_remaining(scene, arrival_time_remaining)

    state =
      scene
      |> assign(graph: graph)
      |> push_graph(graph)

    {:noreply, scene}
  end

  defp modify_line_name(graph, scene, target) do
    Graph.modify(
      graph,
      :line_name,
      &text(
        &1,
        "#{target.line}: Stop ID #{target.stop_id}"
      )
    )
  end

  defp modify_time_remaining(graph, scene, arrival_time_remaining) do
    Graph.modify(
      graph,
      :time_remaining,
      &text(
        &1,
        "#{arrival_time_remaining}"
      )
    )
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
    "~#{seconds_until_arrival / 60} minutes away"
  end

end