defmodule MtaSubwayTime.Scene.Schedule do
  require Logger
  use Scenic.Scene
  alias Scenic.Graph
  alias Scenic.ViewPort
  import Scenic.Primitives
  import Scenic.Components

  @refresh_rate_ms 1000

  @stops_per_target 2
  @stops_refresh_rate_seconds 10

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
              "Loading...",
              font_size: 48,
              translate: {16, 52},
              fill: {:color_rgb, {236, 240, 241}},
              font: :roboto,
              id: :line_name
            )
         |> text(
              "",
              font_size: 12,
              translate: {74, 16},
              fill: {:color_rgb, {236, 240, 241}},
              font: :roboto,
              id: :station_name
            )
         |> text(
              "",
              font_size: 12,
              translate: {74, 28},
              fill: {:color_rgb, {236, 240, 241}},
              font: :roboto,
              id: :direction
            )
         |> text(
              "",
              font_size: 32,
              translate: {74, 58},
              fill: {:color_rgb, {236, 240, 241}},
              font: :roboto,
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
           stop_index: 0,
           last_subway_line_update_seconds: DateTime.utc_now |> DateTime.to_unix(:second),
           last_stop_change_seconds: DateTime.utc_now |> DateTime.to_unix(:second),
           refresh_timer: refresh_timer
         )
      |> push_graph(@graph)

    {:ok, scene}
  end

  @spec handle_info(:refresh, Scenic.Scene) :: {:no_reply, Scenic.Scene}
  def handle_info(:refresh, scene) do
    target = Enum.at(MtaSubwayTime.subway_line_targets(), scene.assigns.target_index)

    current_date = DateTime.utc_now
    current_time_of_day_in_seconds = MtaSubwayTime.Networking.TimeConverter.date_to_seconds_in_day(current_date)

    stop = MtaSubwayTime.Networking.Stops.stop(target.stop_id)
    route = MtaSubwayTime.Networking.Routes.route(target.line)

    arrival =
      MtaSubwayTime.Networking.StopTimes.next_stop_times_after_date(target.stop_id, current_date, @stops_per_target)
      |> Enum.at(scene.assigns.stop_index)
      |> MtaSubwayTime.Networking.StopTimes.subway_arrival(target)

    arrival_time_remaining =
      arrival
      |> (& seconds_until_arrival(&1.arrival_time, current_time_of_day_in_seconds)).()
      |> arrival_time_label

    Logger.info(
      "Active Arrival Info:
      | Line #{target.line}
      | Station #{stop.stop_name}
      | Index #{scene.assigns.stop_index}
      | Stop #{target.stop_id}
      | Direction #{target.direction}
      | Trip #{arrival.trip_id}
      | #{arrival_time_remaining}"
    )

    graph =
      scene.assigns.graph
      |> modify_line_color_background(scene, route.route_color)
      |> modify_line_name(scene, target)
      |> modify_station_name(scene, stop)
      |> modify_direction(scene, target)
      |> modify_time_remaining(scene, arrival_time_remaining)

    state =
      scene
      |> assign(graph: graph)
      |> assign_current_or_next_stop_index(current_date)
      |> push_graph(graph)

    {:noreply, state}
  end

  defp modify_line_color_background(graph, scene, color) do
    Graph.modify(
      graph,
      :line_background,
      &circle(
        &1,
        100,
        fill: {:color_rgb, {color.r, color.g, color.b}}
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

  defp modify_station_name(graph, scene, stop) do
    Graph.modify(
      graph,
      :station_name,
      &text(
        &1,
        "#{stop.stop_name} (#{arrival_index_label(scene.assigns.stop_index)})"
      )
    )
  end

  defp modify_direction(graph, scene, target) do
    Graph.modify(
      graph,
      :direction,
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

  defp arrival_time_label(seconds_until_arrival) when seconds_until_arrival < 91 do
    "~1 minute away"
  end

  defp arrival_time_label(seconds_until_arrival) when seconds_until_arrival < 121 do
    "~2 minutes away"
  end

  defp arrival_time_label(seconds_until_arrival) do
    "#{round(seconds_until_arrival / 60)} minutes away"
  end

  defp arrival_index_label(index) when index == 0 do
    "First Train"
  end

  defp arrival_index_label(index) when index == 1 do
    "Second Train"
  end

  defp arrival_index_label(index) do
    "Train #{index + 1}"
  end

  defp assign_current_or_next_stop_index(scene, date) do
    cond do
      DateTime.to_unix(date, :second) < scene.assigns.last_stop_change_seconds + @stops_refresh_rate_seconds ->
        assign(
          scene,
          stop_index: scene.assigns.stop_index
        )
      true ->
        assign(
          scene,
          stop_index: rem(scene.assigns.stop_index + 1, @stops_per_target),
          last_stop_change_seconds: DateTime.to_unix(date, :second)
        )
    end
  end

end