defmodule MtaSubwayTime.Networking.Data do
  require Logger
  use Agent

  def start_link(_opts) do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  def get(target) do
    get(target.line, target.stop_id)
  end

  def get(line, stop_id) do
    Agent.get(__MODULE__, &Map.get(&1, key(line, stop_id)))
  end

  def put(line, stop_id, value) do
    Agent.update(__MODULE__, &Map.put(&1, key(line, stop_id), value))
  end

  defp key(line, stop_id) do
    "#{line} #{stop_id} }"
  end
end