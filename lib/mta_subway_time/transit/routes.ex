NimbleCSV.define(RoutesCSVParser, separator: ",")

defmodule MtaSubwayTime.Networking.Routes do

  @routes "#{MtaSubwayTime.google_transit_data_directory()}/routes.txt"
         |> File.stream!(read_ahead: 100_000)
         |> RoutesCSVParser.parse_stream
         |> Stream.map(
              fn [route_id, agency_id, route_short_name, route_long_name, route_desc, route_type, route_url, route_color, route_text_color] ->
                color = Chameleon.convert("##{route_color}", Chameleon.RGB)

                %{
                  route_id: route_id,
                  agency_id: agency_id,
                  route_short_name: route_short_name,
                  route_long_name: route_long_name,
                  route_desc: route_desc,
                  route_type: route_type,
                  route_url: route_url,
                  route_color: color,
                  route_text_color: route_text_color,
                }
              end
            )
         |> Stream.filter(
              fn route ->
                targets = MtaSubwayTime.subway_line_targets()

                targets
                |> Enum.any?(& &1[:line] == route[:route_id])
              end
            )
         |> Enum.to_list

  def route(line) do
    @routes
    |> Enum.find(& &1.route_id == line)
  end

end