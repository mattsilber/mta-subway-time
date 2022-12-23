defmodule MtaSubwayTime.Scene.Schedule do
  require Logger
  use Scenic.Scene
  alias Scenic.Graph
  alias Scenic.ViewPort
  import Scenic.Primitives
  import Scenic.Components

  @refresh_rate_ms 5 * 1000

  @graph Graph.build()
         |> rectangle(
              {400, 75},
              fill: {:color_rgb, {52, 73, 94}}
            )
         |> circle(
              100,
              fill: {:color_rgb, {52, 73, 94}},
              translate: {-42, 32},
              id: :line_background
            )
         |> text(
              "Loading schedule...",
              font_size: 42,
              translate: {16, 48},
              fill: {:color_rgb, {236, 240, 241}},
              id: :line_name
            )
         |> text(
              "",
              font_size: 28,
              translate: {72, 32},
              fill: {:color_rgb, {236, 240, 241}},
              id: :line_station_and_direction
            )
         |> text(
              "",
              font_size: 22,
              translate: {72, 56},
              fill: {:color_rgb, {236, 240, 241}},
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

    IO.inspect("Line #{target.line} | Stop #{target.stop_id} | Direction #{target.direction} | Trip #{arrival.trip_id} | Arrives #{arrival_time_remaining}")

    graph =
      scene.assigns.graph
      |> modify_line_color_background(scene, target)
      |> modify_line_name(scene, target)
      |> modify_line_station_and_direction(scene, target)
      |> modify_time_remaining(scene, arrival_time_remaining)

    state =
      scene
      |> assign(graph: graph)
      |> push_graph(graph)

    {:noreply, scene}
  end

  defp modify_line_color_background(graph, scene, target) do
    Graph.modify(
      graph,
      :line_background,
      &circle(
        &1,
        100,
        fill: target.color
      )
    )
  end

  defp modify_line_name(graph, scene, target) do
    Graph.modify(
      graph,
      :line_name,
      &text(
        &1,
        "#{target.line}"
      )
    )
  end

  defp modify_line_station_and_direction(graph, scene, target) do
    Graph.modify(
      graph,
      :line_station_and_direction,
      &text(
        &1,
        "To #{target.direction}"
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
    "~#{round(seconds_until_arrival / 60)} minutes away"
  end

end