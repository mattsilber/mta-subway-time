defmodule MtaSubwayTime do
  @moduledoc """
  Documentation for MtaSubwayTime.
  """

  @doc """
  Hello world.

  ## Examples

      iex> MtaSubwayTime.hello
      :world

  """
  def hello do
    :world
  end

  def subway_line_targets do
    Application.get_env(:mta_subway_time, :subway_lines)
  end

  def google_transit_data_directory do
    Application.get_env(:mta_subway_time, :google_transit_data)
  end
end
