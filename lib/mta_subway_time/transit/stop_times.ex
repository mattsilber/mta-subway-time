NimbleCSV.define(StopTimesCSVParser, separator: ",")

defmodule MtaSubwayTime.Networking.StopTimes do

  @stop_times "#{MtaSubwayTime.google_transit_data_directory()}/stop_times.txt"
              |> File.stream!(read_ahead: 100_000)
              |> StopTimesCSVParser.parse_stream
              |> Stream.map(
                   fn [trip_id, arrival_time, departure_time, stop_id, stop_sequence, stop_headsign, pickup_type, drop_off_type, shape_dist_traveled] ->
                     %{
                       trip_id: trip_id,
                       arrival_time_raw: arrival_time,
                       arrival_time: arrival_time |> MtaSubwayTime.Networking.TimeConverter.time_to_seconds_in_day,
                       departure_time_raw: departure_time,
                       departure_time: departure_time |> MtaSubwayTime.Networking.TimeConverter.time_to_seconds_in_day,
                       stop_id: stop_id,
                       stop_sequence: stop_sequence,
                       stop_headsign: stop_headsign,
                       pickup_type: pickup_type,
                       drop_off_type: drop_off_type,
                       shape_dist_traveled: shape_dist_traveled
                     }
                   end
                 )
              |> Stream.filter(& Map.has_key?(&1, :stop_id))
              |> Stream.filter(& &1[:stop_id])
              |> Stream.filter(& !is_nil(&1[:stop_id]))
              |> Stream.filter(
                   fn stop_time ->
                     targets = MtaSubwayTime.subway_line_targets()

                     targets
                     |> Enum.any?(& &1[:stop_id] == stop_time[:stop_id])
                   end
                 )
              |> Enum.to_list
              |> Enum.sort_by(& &1[:arrival_time])

  def stop_times(stop_id, date) do
    day_of_week_filter = case Date.day_of_week(date) do
      7 -> "Sunday"
      6 -> "Saturday"
      _ -> "Weekday"
    end

    @stop_times
    |> Enum.filter(& &1[:stop_id] == stop_id)
    |> Enum.filter(& String.contains?(&1[:trip_id], day_of_week_filter))
  end

  def next_stop_time_after_date(stop_id, date) do
    current_seconds_in_day = MtaSubwayTime.Networking.TimeConverter.date_to_seconds_in_day(date)
    stop_times_for_id = stop_times(stop_id, date)

    next_stop_time_after_second_in_day(stop_times_for_id, current_seconds_in_day)
  end

  defp next_stop_time_after_second_in_day(stop_times_for_id, seconds_in_day) do
    Enum.find(stop_times_for_id, & (seconds_in_day < &1[:arrival_time]))
    || stop_times_for_id |> hd()
  end

  def next_stop_times_after_date(stop_id, date, count) do
    current_seconds_in_day = MtaSubwayTime.Networking.TimeConverter.date_to_seconds_in_day(date)
    stop_times_for_id = stop_times(stop_id, date)

    next_stop_times_after_seconds_in_day(stop_times_for_id, current_seconds_in_day, count - 1, 0)
  end

  defp next_stop_times_after_seconds_in_day(stop_times_for_id, seconds_in_day, count, 0) do
    current_next_stop_time = next_stop_time_after_second_in_day(stop_times_for_id, seconds_in_day)
    upcoming_stop_times = next_stop_times_after_seconds_in_day(stop_times_for_id, current_next_stop_time[:arrival_time] + 1, count, 1)

    [current_next_stop_time | upcoming_stop_times]
  end

  defp next_stop_times_after_seconds_in_day(stop_times_for_id, seconds_in_day, count_indexed, index) when index < count_indexed do
    current_next_stop_time = next_stop_time_after_second_in_day(stop_times_for_id, seconds_in_day)
    last_stop_time = Enum.at(stop_times_for_id, index)
    upcoming_stop_times = next_stop_times_after_seconds_in_day(stop_times_for_id, last_stop_time[:arrival_time] + 1, count_indexed, index + 1)

    [current_next_stop_time | upcoming_stop_times]
  end

  defp next_stop_times_after_seconds_in_day(stop_times_for_id, seconds_in_day, count_indexed, index) when index > 0 do
    [next_stop_time_after_second_in_day(stop_times_for_id, seconds_in_day)]
  end

  def subway_arrival(stop_time, target) do
    subway_arrival(
      stop_time,
      target,
      updates_for_stop_time(stop_time, target)
    )
  end

  defp updates_for_stop_time(stop_time, target) do
    updates_for_stop_time(
      stop_time,
      target,
      MtaSubwayTime.Networking.Data.get(target.line, target.stop_id, target.direction)
    )
  end

  defp updates_for_stop_time(stop_time, target, nil) do
    []
  end

  defp updates_for_stop_time(stop_time, target, feed_date) do
    feed_date
    |> Enum.flat_map(& &1.arrivals)
    |> Enum.filter(& &1.trip_id == stop_time.trip_id)
  end

  defp subway_arrival(stop_time, target, arrival_updates) when length(arrival_updates) > 0 do
    # TODO: Actually use updates
    %MtaSubwayTime.Models.SubwayArrival{
      line: target.line,
      trip_id: stop_time.trip_id,
      stop_id: target.stop_id,
      direction: target.direction,
      arrival_time: stop_time.arrival_time
    }
  end

  defp subway_arrival(stop_time, target, arrival_updates) do
    %MtaSubwayTime.Models.SubwayArrival{
      line: target.line,
      trip_id: stop_time.trip_id,
      stop_id: target.stop_id,
      direction: target.direction,
      arrival_time: stop_time.arrival_time
    }
  end

end