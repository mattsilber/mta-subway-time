defmodule MtaSubwayTime.Networking.TimeConverter do

  def time_to_seconds_in_day(time) do
    case String.split(time, ":") do
      [hours, minutes, seconds] ->
        hoursInSeconds = String.to_integer(hours) * 60 * 60
        minutesInSeconds = String.to_integer(minutes) * 60

        rem(hoursInSeconds + minutesInSeconds + String.to_integer(seconds), 86_400)
      nil ->
        -1
    end
  end

  def date_to_seconds_in_day(date) do
    date
    |> Calendar.strftime("%H:%M:%S")
    |> time_to_seconds_in_day
  end

end