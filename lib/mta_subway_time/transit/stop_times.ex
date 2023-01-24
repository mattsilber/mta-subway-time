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
                       shape_dist_traveled: shape_dist_traveled,
                       schedule_changed: false,
                       schedule_offset: 0,
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

  def stop_times(target, date) do
    # Include yesterday's, today's, and tomorrow's schedules with offsets
    # to sort rollovers
    stop_times(target, date, 2, 0)
    |> List.flatten
    |> Enum.map(& adjusted_stop_time_with_feed_data(&1, MtaSubwayTime.Networking.Data.get(target)))
    |> Enum.sort_by(& &1[:arrival_time])
  end

  defp stop_times(target, date, count_indexed, 0) do
    [stop_times(target, date |> Timex.shift(days: -1), -86_400) | stop_times(target, date, count_indexed, 1)]
  end

  defp stop_times(target, date, count_indexed, index) when index < count_indexed do
    [stop_times(target, date |> Timex.shift(days: index - 1), 86_400 * (index - 1)) | stop_times(target, date, count_indexed, index + 1)]
  end

  defp stop_times(target, date, count_indexed, index) do
    [stop_times(target, date |> Timex.shift(days: index - 1), 86_400 * (index - 1))]
  end

  defp stop_times(target, date, arrival_offset) do
    day_of_week_filter = case Date.day_of_week(date) do
      7 -> "Sunday"
      6 -> "Saturday"
      _ -> "Weekday"
    end

    @stop_times
    |> Enum.filter(& &1[:stop_id] == target.stop_id)
    |> Enum.filter(& String.contains?(&1[:trip_id], day_of_week_filter))
    |> Enum.map(& %{&1 | :arrival_time => &1[:arrival_time] + arrival_offset})
  end

  def next_stop_time_after_second_in_day(target, stop_times_for_id, seconds_in_day) do
    # stop_times should return yesterday's, today's and tomorrow's schedule,
    # but need to account for the feed updates for a line, if they're available
    stop_times_for_id
    |> Enum.sort_by(& &1[:arrival_time])
    |> Enum.find(& (seconds_in_day < &1[:arrival_time]))
  end

  defp adjusted_stop_time_with_feed_data(stop_time, nil) do
    stop_time
  end

  defp adjusted_stop_time_with_feed_data(stop_time, data) do
    # I'm assuming we won't have feed updates for tomorrow's schedules, but that's probably wrong
    arrival_time =
      data
      |> feed_data_arrival(stop_time)
      |> stop_time_from_feed_arrival(stop_time)

    offset = arrival_time - stop_time[:arrival_time]
    changed = offset != 0

    %{stop_time | :arrival_time => arrival_time, :schedule_changed => changed, :schedule_offset => offset}
  end

  defp feed_data_arrival(data, stop_time) do
    data.arrivals
    |> Enum.find(& &1.trip_id == stop_time.trip_id)
  end

  defp stop_time_from_feed_arrival(nil, stop_time) do
    stop_time.arrival_time
  end

  defp stop_time_from_feed_arrival(arrival, stop_time) do
    arrival.arrival_time
    |> DateTime.from_unix!(:second)
    |> MtaSubwayTime.Networking.TimeConverter.date_to_seconds_in_day
  end

  def next_stop_times_after_date(target, date, count) do
    current_seconds_in_day = MtaSubwayTime.Networking.TimeConverter.date_to_seconds_in_day(date)

    stop_times_for_id = Enum.filter(
      stop_times(target, date),
      & (current_seconds_in_day < &1[:arrival_time])
    )

    next_stop_times_after_seconds_in_day(target, stop_times_for_id, current_seconds_in_day, count - 1, 0)
  end

  defp next_stop_times_after_seconds_in_day(target, stop_times_for_id, seconds_in_day, count, 0) do
    current_next_stop_time = next_stop_time_after_second_in_day(target, stop_times_for_id, seconds_in_day)
    upcoming_stop_times = next_stop_times_after_seconds_in_day(target, stop_times_for_id, current_next_stop_time[:arrival_time] + 1, count, 1)

    [current_next_stop_time | upcoming_stop_times]
  end

  defp next_stop_times_after_seconds_in_day(target, stop_times_for_id, seconds_in_day, count_indexed, index) when index < count_indexed do
    current_next_stop_time = next_stop_time_after_second_in_day(target, stop_times_for_id, seconds_in_day)
    last_stop_time = Enum.at(stop_times_for_id, index)
    upcoming_stop_times = next_stop_times_after_seconds_in_day(target, stop_times_for_id, last_stop_time[:arrival_time] + 1, count_indexed, index + 1)

    [current_next_stop_time | upcoming_stop_times]
  end

  defp next_stop_times_after_seconds_in_day(target, stop_times_for_id, seconds_in_day, count_indexed, index) do
    [next_stop_time_after_second_in_day(target, stop_times_for_id, seconds_in_day)]
  end

  def subway_arrival(stop_time, target) do
    %MtaSubwayTime.Models.SubwayArrival{
      line: target.line,
      trip_id: stop_time.trip_id,
      stop_id: target.stop_id,
      direction: target.direction,
      arrival_time: stop_time.arrival_time,
      schedule_changed: stop_time.schedule_changed,
      schedule_offset: stop_time.schedule_offset
    }
  end

end