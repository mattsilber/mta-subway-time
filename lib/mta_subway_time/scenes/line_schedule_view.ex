defmodule MtaSubwayTime.Scene.LineScheduleView do
  require Logger
  use Scenic.Scene
  alias Scenic.Graph
  alias Scenic.ViewPort
  import Scenic.Primitives
  import Scenic.Components

  @circle_background_radius 26
  @content_x_offset 68

  def create_view(graph, line_background_id, index_id, line_id, station_name_id, direction_id, time_remaining_id, {offset_x, offset_y}) do
    graph
    |> circle(
         @circle_background_radius,
         fill: {:color_rgb, {52, 73, 94}},
         translate: {30 + offset_x, 32 + offset_y},
         id: line_background_id
       )
    |> text(
         "Loading...",
         font_size: 44,
         translate: {18 + offset_x, 48 + offset_y},
         fill: {:color_rgb, {236, 240, 241}},
         font: :roboto,
         id: line_id
       )
    |> text(
         "",
         font_size: 12,
         translate: {@content_x_offset + offset_x, 16 + offset_y},
         fill: {:color_rgb, {236, 240, 241}},
         font: :roboto,
         id: index_id
       )
    |> text(
         "",
         font_size: 12,
         translate: {@content_x_offset + offset_x, 16 + offset_y},
         fill: {:color_rgb, {236, 240, 241}},
         font: :roboto,
         id: station_name_id
       )
    |> text(
         "",
         font_size: 12,
         translate: {@content_x_offset + offset_x, 28 + offset_y},
         fill: {:color_rgb, {236, 240, 241}},
         font: :roboto,
         id: direction_id
       )
    |> text(
         "",
         font_size: 32,
         translate: {@content_x_offset + offset_x, 58 + offset_y},
         fill: {:color_rgb, {236, 240, 241}},
         font: :roboto,
         id: time_remaining_id
       )
  end

  def modify_view(
        graph,
        scene,
        target,
        arrivals,
        arrival_index,
        current_time_of_day_in_seconds,
        line_background_id,
        index_id,
        line_id,
        station_name_id,
        direction_id,
        time_remaining_id
      ) do

    arrival =
      arrivals
      |> Enum.at(arrival_index)
      |> MtaSubwayTime.Networking.StopTimes.subway_arrival(target)

    arrival_time_remaining =
      arrival
      |> (& seconds_until_arrival(&1.arrival_time, current_time_of_day_in_seconds)).()
      |> arrival_time_label

    stop = MtaSubwayTime.Networking.Stops.stop(target.stop_id)
    route = MtaSubwayTime.Networking.Routes.route(target.line)

    Logger.info(
      "Active Arrival Info:
      | Line #{target.line}
      | Station #{stop.stop_name}
      | Arrival Index #{arrival_index}
      | Stop #{target.stop_id}
      | Direction #{target.direction}
      | Trip #{arrival.trip_id}
      | Schedule Updated #{arrival.schedule_changed}, #{arrival.schedule_offset} seconds difference
      | #{arrival_time_remaining}"
    )

    graph
    |> modify_line_color_background(scene, route.route_color, line_background_id)
    |> modify_line_name(scene, target, line_id)
    |> modify_station_name(scene, stop, arrival_index, station_name_id)
    |> modify_direction(scene, target, direction_id)
    |> modify_time_remaining(scene, arrival_time_remaining, time_remaining_id)
  end

  defp modify_line_color_background(graph, scene, color, line_background_id) do
    Graph.modify(
      graph,
      line_background_id,
      &circle(
        &1,
        @circle_background_radius,
        fill: {:color_rgb, {color.r, color.g, color.b}}
      )
    )
  end

  defp modify_line_name(graph, scene, target, line_id) do
    Graph.modify(
      graph,
      line_id,
      &text(
        &1,
        "#{target.line}"
      )
    )
  end

  defp modify_station_name(graph, scene, stop, arrival_index, station_name_id) do
    Graph.modify(
      graph,
      station_name_id,
      &text(
        &1,
        "#{stop.stop_name} (#{arrival_index_label(arrival_index)})"
      )
    )
  end

  defp modify_direction(graph, scene, target, direction_id) do
    Graph.modify(
      graph,
      direction_id,
      &text(
        &1,
        "To #{target.direction}"
      )
    )
  end

  defp modify_time_remaining(graph, scene, arrival_time_remaining, time_remaining_id) do
    Graph.modify(
      graph,
      time_remaining_id,
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
    "Next Train"
  end

  defp arrival_index_label(index) when index == 1 do
    "Second Train"
  end

  defp arrival_index_label(index) when index == 2 do
    "Third Train"
  end

  defp arrival_index_label(index) do
    "Train #{index + 1}"
  end

end
