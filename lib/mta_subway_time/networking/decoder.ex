defmodule MtaSubwayTime.Networking.Decoder do

  def subway_line_stops(feed_message, line, stop_id, _direction, epoch_seconds) do
    arrivals =
      feed_message
#      |> IO.inspect
      |> filter_entities_for_line(line)
      |> flatten_trip_with_stop_times
      |> Enum.filter(& &1.stop_id == stop_id)
      |> Enum.filter(& &1.arrival_time > epoch_seconds)
      |> Enum.sort(& &1.arrival_time < &2.arrival_time)

    %MtaSubwayTime.Models.SubwayLineFeedUpdate{
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

  defp flatten_trip_with_stop_times(stop_times) do
    stop_times
    |> Enum.flat_map(& map_trip_to_arrival_feed_update/1)
  end

  defp map_trip_to_arrival_feed_update(stop_time) do
    stop_time.trip_update.stop_time_update
    |> Enum.map(
         fn time_update ->
           %MtaSubwayTime.Models.SubwayArrivalFeedUpdate{
             stop_id: time_update.stop_id,
             trip_id: stop_time.trip_update.trip.trip_id,
             arrival_time: time_update.arrival.time
           }
         end
       )
  end

end