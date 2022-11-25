defmodule MtaSubwayTime.Networking.Data do
  use Agent

  def start_link(_opts) do
    Agent.start_link(fn -> %{} end)
  end

  def get(bucket, line, direction) do
    Agent.get(bucket, &Map.get(&1, key(line, direction)))
  end

  def put(bucket, line, direction, value) do
    Agent.update(bucket, &Map.put(&1, key(line, direction), value))
  end

  defp key(line, direction) do
    "#{line} #{direction}"
  end
end