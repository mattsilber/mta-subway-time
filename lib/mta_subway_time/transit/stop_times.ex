NimbleCSV.define(StopTimesCSVParser, separator: ",")

defmodule MtaSubwayTime.Networking.Data do
  use Agent

  @stop_times google_transit_data_file()
              |> File.read!
              |> StopTimesCSVParser.parse_string
              |> Enum.map(
                   fn [trip_id, arrival_time, departure_time, stop_id, stop_sequence, stop_headsign, pickup_type, drop_off_type, shape_dist_traveled] ->
                     %{
                       trip_id: trip_id,
                       arrival_time: arrival_time,
                       departure_time: departure_time,
                       stop_id: stop_id,
                       stop_sequence: stop_sequence,
                       stop_headsign: stop_headsign,
                       pickup_type: pickup_type,
                       drop_off_type: drop_off_type,
                       shape_dist_traveled: shape_dist_traveled
                     }
                   end
                 )
              |> IO.inspect
#              |> filter_by_target_stop_id()

  def start_link(_opts) do
    @stop_times |> IO.inspect

    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  defp get(stop_id) do
    Agent.get(__MODULE__, &Map.get(&1, stop_id))
  end

  defp put(stop_id, value) do
    Agent.update(__MODULE__, &Map.put(&1, stop_id, value))
  end

  defp google_transit_data_file do
    "#{MtaSubwayTime.google_transit_data_directory()}/stop_times.txt"
  end

  defp filter_by_target_stop_id(stop_times) do
    targets = MtaSubwayTime.subway_line_targets()

    stop_times
    |> Enum.filter(& is_stop_id_included(targets, &1))
  end

  defp is_stop_id_included(targets, stop_time) do
    targets
    |> Enum.any(& &1.stop_id == stop.stop_id)
  end
end