defmodule MtaSubwayTime.Scene.LineScheduleView do
  require Logger
  use Scenic.Scene
  alias Scenic.Graph
  alias Scenic.ViewPort
  import Scenic.Primitives
  import Scenic.Components

  @circle_background_radius 22

  @content_x_offset 80
  @content_text_color {236, 240, 241}

  def create_view(graph, line_background_id, index_id, line_id, station_and_direction_id, time_remaining_id, {offset_x, offset_y}) do
    graph
    |> circle(
         @circle_background_radius,
         fill: {:color_rgb, {52, 73, 94}},
         translate: {50 + offset_x, 34 + offset_y},
         id: line_background_id
       )
    |> text(
         "Loading...",
         font_size: 38,
         translate: {40 + offset_x, 48 + offset_y},
         fill: {:color_rgb, @content_text_color},
         id: line_id
       )
    |> text(
         "",
         font_size: 22,
         translate: {6 + offset_x, 48 + offset_y},
         fill: {:color_rgb, @content_text_color},
         id: index_id
       )
    |> text(
         "",
         font_size: 12,
         translate: {@content_x_offset + offset_x, 22 + offset_y},
         fill: {:color_rgb, @content_text_color},
         id: station_and_direction_id
       )
    |> text(
         "",
         font_size: 32,
         translate: {@content_x_offset + offset_x, 52 + offset_y},
         fill: {:color_rgb, @content_text_color},
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
        station_and_direction_id,
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
    |> modify_arrival_index(scene, arrival_index, index_id)
    |> modify_station_and_direction(scene, target, stop, station_and_direction_id)
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

  defp modify_arrival_index(graph, scene, arrival_index, index_id) do
    Graph.modify(
      graph,
      index_id,
      &text(
        &1,
        arrival_index_label(arrival_index)
      )
    )
  end

  defp modify_station_and_direction(graph, scene, target, stop, station_and_direction_id) do
    Graph.modify(
      graph,
      station_and_direction_id,
      &text(
        &1,
        "#{stop.stop_name} to #{target.direction}"
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

  defp arrival_index_label(index) do
    "#{index + 1}."
  end

end
