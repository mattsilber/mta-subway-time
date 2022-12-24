defmodule MtaSubwayTime.Networking.DataTest do
  use ExUnit.Case, async: true

  test "stores values by key" do
    assert MtaSubwayTime.Networking.Data.get("F", "0") == nil

    MtaSubwayTime.Networking.Data.put("F", "0", :ok)

    assert MtaSubwayTime.Networking.Data.get("F", "0") == :ok
  end
end