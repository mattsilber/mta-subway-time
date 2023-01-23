defmodule MtaSubwayTime.Scene.Schedule do
  require Logger
  use Scenic.Scene
  alias Scenic.Graph
  alias Scenic.ViewPort
  import Scenic.Primitives
  import Scenic.Components

  @refresh_rate_ms 1000

  @stops_per_target 4
  @stops_refresh_rate_seconds 10

  @targets_refresh_rate_seconds 20

  @graph Graph.build()
         |> rectangle(
              {400, 70},
              fill: {:color_rgb, {52, 73, 94}}
            )
         |> MtaSubwayTime.Scene.LineScheduleView.create_view(
              :line_background_1,
              :arrival_index_1,
              :line_name_1,
              :station_and_direction_1,
              :time_remaining_1,
              {0, 0}
            )
         |> MtaSubwayTime.Scene.LineScheduleView.create_view(
              :line_background_2,
              :arrival_index_2,
              :line_name_2,
              :station_and_direction_2,
              :time_remaining_2,
              {0, 72}
            )

  def init(scene, _params, _options) do
    Logger.info("Scene init...")

    {:ok, refresh_timer} = :timer.send_interval(@refresh_rate_ms, :refresh)

    scene =
      scene
      |> assign(
           graph: @graph,
           target_index: 0,
           target_count: MtaSubwayTime.subway_line_targets() |> Enum.count,
           secondary_stop_index: 0,
           last_target_change_seconds: DateTime.utc_now |> DateTime.to_unix(:second),
           last_stop_change_seconds: DateTime.utc_now |> DateTime.to_unix(:second),
           refresh_timer: refresh_timer
         )
      |> push_graph(@graph)

    {:ok, scene}
  end

  @spec handle_info(:refresh, Scenic.Scene) :: {:no_reply, Scenic.Scene}
  def handle_info(:refresh, scene) do
    target = Enum.at(MtaSubwayTime.subway_line_targets(), scene.assigns.target_index)

    current_date = Timex.to_datetime(DateTime.utc_now, MtaSubwayTime.transit_data_timezone())
    current_time_of_day_in_seconds = MtaSubwayTime.Networking.TimeConverter.date_to_seconds_in_day(current_date)

    arrivals = MtaSubwayTime.Networking.StopTimes.next_stop_times_after_date(target, current_date, @stops_per_target)

    # Note the `secondary_stop_index + 1` is 0 based off `@stops_per_target - 1`
    graph =
      scene.assigns.graph
      |> MtaSubwayTime.Scene.LineScheduleView.modify_view(
           scene,
           target,
           arrivals,
           0,
           current_time_of_day_in_seconds,
           :line_background_1,
           :arrival_index_1,
           :line_name_1,
           :station_and_direction_1,
           :time_remaining_1
         )
      |> MtaSubwayTime.Scene.LineScheduleView.modify_view(
           scene,
           target,
           arrivals,
           scene.assigns.secondary_stop_index + 1,
           current_time_of_day_in_seconds,
           :line_background_2,
           :arrival_index_2,
           :line_name_2,
           :station_and_direction_2,
           :time_remaining_2
         )

    state =
      scene
      |> assign(graph: graph)
      |> assign_current_or_next_target_index(current_date)
      |> assign_current_or_next_stop_index(current_date)
      |> push_graph(graph)

    {:noreply, state}
  end

  defp assign_current_or_next_target_index(scene, date) do
    cond do
      DateTime.to_unix(date, :second) < scene.assigns.last_target_change_seconds + @targets_refresh_rate_seconds ->
        assign(
          scene,
          target_index: scene.assigns.target_index
        )
      true ->
        assign(
          scene,
          target_index: rem(scene.assigns.target_index + 1, scene.assigns.target_count),
#          secondary_stop_index: 0,
          last_target_change_seconds: DateTime.to_unix(date, :second),
          last_stop_change_seconds: DateTime.to_unix(date, :second)
        )
    end
  end

  defp assign_current_or_next_stop_index(scene, date) do
    cond do
      DateTime.to_unix(date, :second) < scene.assigns.last_stop_change_seconds + @stops_refresh_rate_seconds ->
        assign(
          scene,
          secondary_stop_index: scene.assigns.secondary_stop_index
        )
      true ->
        assign(
          scene,
          secondary_stop_index: rem(scene.assigns.secondary_stop_index + 1, @stops_per_target - 1),
          last_stop_change_seconds: DateTime.to_unix(date, :second)
        )
    end
  end

end