defmodule MtaSubwayTime.Networking.ApiTest do
  use ExUnit.Case, async: true

  test "collects unique stop identifiers" do
    subway_lines = [
      %{line: "F", stop_id: "0", direction: -1},
      %{line: "G", stop_id: "0", direction: -1},
      %{line: "G", stop_id: "1", direction: -1}
    ]

    assert ["0", "1"] == MtaSubwayTime.Networking.Api.stop_identifiers(subway_lines)
  end

  test "collects unique lines" do
    subway_lines = [
      %{line: "F", stop_id: "0", direction: -1},
      %{line: "G", stop_id: "0", direction: -1},
      %{line: "G", stop_id: "1", direction: -1}
    ]

    assert ["F", "G"] == MtaSubwayTime.Networking.Api.lines(subway_lines)
  end

  test "collects unique api_routes" do
    subway_lines = [
      %{line: "F", stop_id: "0", direction: -1},
      %{line: "A", stop_id: "0", direction: -1},
      %{line: "C", stop_id: "1", direction: -1}
    ]

    expected = [
      {:ok, "https://api-endpoint.mta.info/Dataservice/mtagtfsfeeds/nyct%2Fgtfs-bdfm"},
      {:ok, "https://api-endpoint.mta.info/Dataservice/mtagtfsfeeds/nyct%2Fgtfs-ace"}
    ]

    assert expected == MtaSubwayTime.Networking.Api.api_routes(subway_lines)
  end

  test "api route for ACE lines" do
    Enum.each(
      ["A", "C", "E"],
      fn line ->
        {:ok, url} = MtaSubwayTime.Networking.Api.api_route(line)

        assert "https://api-endpoint.mta.info/Dataservice/mtagtfsfeeds/nyct%2Fgtfs-ace" == url
      end
    )
  end

  test "api route for BDFM lines" do
    Enum.each(
      ["B", "D", "F", "M"],
      fn line ->
        {:ok, url} = MtaSubwayTime.Networking.Api.api_route(line)

        assert "https://api-endpoint.mta.info/Dataservice/mtagtfsfeeds/nyct%2Fgtfs-bdfm" == url
      end
    )
  end

  test "api route for G line" do
    Enum.each(
      ["G"],
      fn line ->
        {:ok, url} = MtaSubwayTime.Networking.Api.api_route(line)

        assert "https://api-endpoint.mta.info/Dataservice/mtagtfsfeeds/nyct%2Fgtfs-g" == url
      end
    )
  end

  test "api route for NQRW lines" do
    Enum.each(
      ["N", "Q", "R", "W"],
      fn line ->
        {:ok, url} = MtaSubwayTime.Networking.Api.api_route(line)

        assert "https://api-endpoint.mta.info/Dataservice/mtagtfsfeeds/nyct%2Fgtfs-nqrw" == url
      end
    )
  end

  test "api route for 1-7 lines" do
    Enum.each(
      ["1", "2", "3", "4", "5", "6", "7"],
      fn line ->
        {:ok, url} = MtaSubwayTime.Networking.Api.api_route(line)

        assert "https://api-endpoint.mta.info/Dataservice/mtagtfsfeeds/nyct%2Fgtfs" == url
      end
    )
  end

  test "api route for undefined lines" do
    Enum.each(
      ["NOT-A-LINE"],
      fn line ->
        assert match?({:error, nil}, MtaSubwayTime.Networking.Api.api_route(line))
      end
    )
  end
end