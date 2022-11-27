defmodule MtaSubwayTime.Networking.Api do
  require Logger
  require NervesTime
  use GenServer

  def start_link(opts) do
    opts = Keyword.merge([name: __MODULE__], opts)

    GenServer.start_link(__MODULE__, :ok, opts)
  end

  @impl true
  def init(args) do
#    check_network(Nerves.Network.status(network_interface_name()))
#    check_time_synchronized()

    schedule_next_mta_request_loop(1)

    {:ok, args}
  end

  @impl true
  def handle_info(:request_updates, state) do
    request_mta_info()
    schedule_next_mta_request_loop(5 * 60 * 60)

    {:noreply, state}
  end

  @impl true
  def handle_info(term, state) do
    {:noreply, state}
  end

  @impl true
  def handle_call(request, from, state) do
    {:reply, "", state}
  end

  @impl true
  def handle_cast(request, state) do
    {:noreply, state}
  end

  defp check_network(%{ipv4_address: ip}) do
    Logger.info("Network connected")
  end

  defp check_network(_) do
    Logger.info("Awaiting network connection")

    # Takes a moment for connection to be established
    Process.sleep(1000)

    network_interface_name()
    |> Nerves.Network.status
    |> Logger.info
    |> check_network()
  end

  defp network_interface_name do
    Application.get_env(:mta_subway_time, :network_interface_name)
  end

  defp check_time_synchronized do
    if !NervesTime.synchronized?() do
      Process.sleep(1000)

      check_time_synchronized()
    end
  end

  def request_mta_info() do
    MtaSubwayTime.subway_line_targets()
    |> api_routes
    |> Enum.each(&request_mta_info/1)

    {:ok, {}}
  end

  def lines(subway_lines) do
    Enum.map(subway_lines, fn %{line: line} -> line end)
    |> Enum.uniq
  end

  def stop_identifiers(subway_lines) do
    Enum.map(subway_lines, fn %{stop_id: stop_id} -> stop_id end)
    |> Enum.uniq
  end

  def api_routes(subway_lines) do
    subway_lines
    |> lines
    |> Enum.map(&api_route/1)
    |> Enum.uniq
  end

  @doc """
  Endpoints can be found at:
  http://mtadatamine.s3-website-us-east-1.amazonaws.com/#/subwayRealTimeFeeds
  """
  def api_route(line) do
    cond do
      Enum.any?(["A", "C", "E"], & &1 == line) ->
        {:ok, "https://api-endpoint.mta.info/Dataservice/mtagtfsfeeds/nyct%2Fgtfs-ace"}
      Enum.any?(["B", "D", "F", "M"], & &1 == line) ->
        {:ok, "https://api-endpoint.mta.info/Dataservice/mtagtfsfeeds/nyct%2Fgtfs-bdfm"}
      Enum.any?(["G"], & &1 == line) ->
        {:ok, "https://api-endpoint.mta.info/Dataservice/mtagtfsfeeds/nyct%2Fgtfs-g"}
      Enum.any?(["N", "Q", "R", "W"], & &1 == line) ->
        {:ok, "https://api-endpoint.mta.info/Dataservice/mtagtfsfeeds/nyct%2Fgtfs-nqrw"}
      Enum.any?(["1", "2", "3", "4", "5", "6", "7"], & &1 == line) ->
        {:ok, "https://api-endpoint.mta.info/Dataservice/mtagtfsfeeds/nyct%2Fgtfs"}
      true ->
        {:error, nil}
    end
  end

  defp request_mta_info({:ok, url}) do
    Logger.info("Requesting info for #{url}")

    headers = [
      "x-api-key": Application.get_env(:mta_subway_time, :gtfs_api_key)
    ]

    HTTPoison.get(url, headers, [])
    |> handle_mta_response
  end

  defp request_mta_info({:error, _}) do
    Logger.error("Undefined route!")
  end

  defp handle_mta_response({:ok, %{status_code: 200, body: body}}) do
    handle_mta_feed_message(
      TransitRealtime.FeedMessage.decode(body),
      MtaSubwayTime.subway_line_targets(),
      :os.system_time(:second)
    )
  end

  defp handle_mta_response({:ok, %{status_code: status_code, body: body}}) do
    Logger.error("Unhandled status code: #{status_code}")

    {:ok, {}}
  end

  defp handle_mta_response({:error, %HTTPoison.Error{reason: reason}}) do
    Logger.error("Failed to load MTA info: #{reason}!")

    {:ok, {}}
  end

  def handle_mta_feed_message(message, line_targets, epoch_time) do
    {
      :ok,
      {
        line_targets
        |> Enum.map(
             fn %{line: line, stop_id: stop_id, direction: direction} ->
               MtaSubwayTime.Networking.Decoder.subway_line_stops(message, line, stop_id, direction, epoch_time)
             end
           )
        |> Enum.filter(& !Enum.empty?(&1.arrivals))
        |> Enum.each(& MtaSubwayTime.Networking.Data.put(&1.line, &1.stop_id, &1.direction, &1))
      }
    }
  end

  defp schedule_next_mta_request_loop(duration_seconds) do
    Logger.info("Scheduling info request loop in #{duration_seconds} seconds")

    Process.send_after(self(), :request_updates, duration_seconds * 1000)
  end

  @impl true
  def terminate(reason, state) do
    :ok
  end
end