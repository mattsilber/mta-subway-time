NimbleCSV.define(StopsCSVParser, separator: ",")

defmodule MtaSubwayTime.Networking.Stops do

  @stops "#{MtaSubwayTime.google_transit_data_directory()}/stops.txt"
         |> File.stream!(read_ahead: 100_000)
         |> StopsCSVParser.parse_stream
         |> Stream.map(
              fn [stop_id, stop_code, stop_name, stop_desc, stop_lat, stop_lon, zone_id, stop_url, location_type, parent_station] ->
                %{
                  stop_id: stop_id,
                  stop_code: stop_code,
                  stop_name: stop_name,
                  stop_desc: stop_desc,
                  stop_lat: stop_lat,
                  stop_lon: stop_lon,
                  zone_id: zone_id,
                  stop_url: stop_url,
                  location_type: location_type,
                  parent_station: parent_station,
                }
              end
            )
         |> Stream.filter(
              fn stop ->
                targets = MtaSubwayTime.subway_line_targets()

                targets
                |> Enum.any?(& &1[:stop_id] == stop[:stop_id])
              end
            )
         |> Enum.to_list

  def stop(stop_id) do
    @stops
    |> Enum.find(& &1.stop_id == stop_id)
  end

end