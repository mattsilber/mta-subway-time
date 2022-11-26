defmodule MtaSubwayTime.Networking.Decoder do

  def subway_line_stops(feed_message, line, stop_id, _direction, epoch_seconds) do
    arrivals = feed_message
               |> filter_entities_for_line(line)
               |> Enum.map(& &1.trip_update.stop_time_update)
               |> Enum.flat_map(& stop_times_after_ascending(&1, stop_id, epoch_seconds))
               |> stop_time_epochs_ascending

    %MtaSubwayTime.Models.SubwayLineStop{
      line: line,
      stop_id: stop_id,
      arrivals: arrivals
    }
  end

  def filter_entities_for_line(%TransitRealtime.FeedMessage{entity: entities}, line) do
    entities
    |> Enum.filter(& is_correct_route(line, &1))
  end

  defp is_correct_route(line, %{trip_update: nil}) do
    false
  end

  defp is_correct_route(line, %{trip_update: trip_update}) do
    is_correct_route(line, trip_update)
  end

  defp is_correct_route(line, %{trip: nil}) do
    false
  end

  defp is_correct_route(line, %{trip: trip}) do
    trip.route_id == line
  end

  @spec stop_times_after_ascending([TransitRealtime.TripUpdate.StopTimeUpdate], String, integer) :: [TransitRealtime.TripUpdate.StopTimeUpdate]
  def stop_times_after_ascending(stop_times, stop_id, epoch_seconds) do
    stop_times
    |> Enum.filter(& &1.stop_id == stop_id)
    |> Enum.filter(& &1.arrival.time > epoch_seconds)
    |> Enum.sort(& &1.arrival.time < &2.arrival.time)
  end

  @spec stop_time_epochs_ascending([TransitRealtime.TripUpdate.StopTimeUpdate]) :: [integer]
  def stop_time_epochs_ascending(stop_times) do
    stop_times
    |> Enum.map(& &1.arrival.time)
    |> Enum.sort(& &1 < &2)
  end

end