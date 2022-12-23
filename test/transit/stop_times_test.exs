defmodule MtaSubwayTime.Networking.StopTimesTest do
  use ExUnit.Case, async: true

  test "includes stop times for stop ID" do
    date = Timex.parse!("12/23/2022 01:59:29", "%m/%d/%Y %T", :strftime)
    times_F24N = MtaSubwayTime.Networking.StopTimes.stop_times("F24N", date)

    # Really hoping 336 is the actual count for the Weekday schedule :sweat:
    assert 336 == Enum.count(times_F24N)

    assert times_F24N |> Enum.all?(fn time -> time[:stop_id] == "F24N" end)
  end

  test "does not include stop times for stop ID not in target list" do
    date = Timex.parse!("12/23/2022 01:59:29", "%m/%d/%Y %T", :strftime)
    times_N03R = MtaSubwayTime.Networking.StopTimes.stop_times("N03R", date)

    assert 0 == Enum.count(times_N03R)
  end

  test "transforms date to seconds in day" do
    date = Timex.parse!("12/23/2022 01:59:29", "%m/%d/%Y %T", :strftime)
    first_timeF24N = MtaSubwayTime.Networking.StopTimes.stop_times("F24N", date) |> hd()

    # I'm assuming the schedules are meant to wrap but have no idea :shrug:
    assert "24:05:00" == first_timeF24N[:arrival_time_raw]
    assert 300 == first_timeF24N[:arrival_time]
  end

  test "returns next stop time in future" do
    date = Timex.parse!("12/23/2022 23:55:29", "%m/%d/%Y %T", :strftime)
    next_stop_time = MtaSubwayTime.Networking.StopTimes.next_stop_time_after_date("F24N", date)

    assert "23:55:30" == next_stop_time[:arrival_time_raw]
    assert 86130 == next_stop_time[:arrival_time]
  end

  test "returns first stop time after last stop time" do
    date = Timex.parse!("12/23/2022 23:59:31", "%m/%d/%Y %T", :strftime)
    next_stop_time = MtaSubwayTime.Networking.StopTimes.next_stop_time_after_date("F24N", date)

    assert "24:05:00" == next_stop_time[:arrival_time_raw]
    assert 300 == next_stop_time[:arrival_time]
  end

  test "returns next stop times rolling over" do
    date = Timex.parse!("12/23/2022 23:55:29", "%m/%d/%Y %T", :strftime)
    next_stop_times = MtaSubwayTime.Networking.StopTimes.next_stop_times_after_date("F24N", date, 2)

    assert 2 == Enum.count(next_stop_times)

    assert 86130 == hd(next_stop_times)[:arrival_time]
    assert 300 == List.last(next_stop_times)[:arrival_time]
  end

  test "returns variable stop times" do
    date = Timex.parse!("12/23/2022 01:59:29", "%m/%d/%Y %T", :strftime)
    next_stop_times = MtaSubwayTime.Networking.StopTimes.next_stop_times_after_date("F24N", date, 10)

    assert 10 == Enum.count(next_stop_times)
  end
end
