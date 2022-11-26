defmodule MtaSubwayTime.Networking.Data do
  use Agent

  def start_link(_opts) do
    Agent.start_link(fn -> %{} end)
  end

  def get(bucket, line, stop_id, direction) do
    Agent.get(bucket, &Map.get(&1, key(line, stop_id, direction)))
  end

  def put(bucket, line, stop_id, direction, value) do
    Agent.update(bucket, &Map.put(&1, key(line, stop_id, direction), value))
  end

  defp key(line, stop_id, direction) do
    "#{line} #{stop_id} }#{direction}"
  end
end