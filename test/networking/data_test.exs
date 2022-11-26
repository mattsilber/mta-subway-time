defmodule MtaSubwayTime.Networking.DataTest do
  use ExUnit.Case, async: true

  setup do
    data = start_supervised!(MtaSubwayTime.Networking.Data)

    %{data: data}
  end

  test "stores values by key", %{data: data} do
    assert MtaSubwayTime.Networking.Data.get(data, "F", "0", -1) == nil

    MtaSubwayTime.Networking.Data.put(data, "F", "0", -1, :ok)

    assert MtaSubwayTime.Networking.Data.get(data, "F", "0", -1) == :ok
  end
end