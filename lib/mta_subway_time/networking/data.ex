defmodule MtaSubwayTime.Networking.Data do
  use Agent

  def start_link(_opts) do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  def get(line, stop_id, direction) do
    Agent.get(__MODULE__, &Map.get(&1, key(line, stop_id, direction)))
  end

  def put(line, stop_id, direction, value) do
    Agent.update(__MODULE__, &Map.put(&1, key(line, stop_id, direction), value))
  end

  defp key(line, stop_id, direction) do
    "#{line} #{stop_id} }#{direction}"
  end
end