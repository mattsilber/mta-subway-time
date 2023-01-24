defmodule MtaSubwayTime.Networking.StopTimesTest do
  use ExUnit.Case, async: true

  @test_target %{
    line: "0",
    stop_id: "F24N",
  }

  test "includes stop times for stop ID" do
    # Friday
    date = Timex.parse!("12/23/2022 01:59:29", "%m/%d/%Y %T", :strftime)
    times_F24N = MtaSubwayTime.Networking.StopTimes.stop_times(@test_target, date)

    # Really hoping 901 is the actual count for the Weekday + Weekday + Saturday schedule :sweat:
    assert 901 == Enum.count(times_F24N)

    assert times_F24N |> Enum.all?(fn time -> time[:stop_id] == "F24N" end)
  end

  test "does not include stop times for stop ID not in target list" do
    not_a_target = %{
      line: "0",
      stop_id: "N03R",
    }

    # Friday
    date = Timex.parse!("12/23/2022 01:59:29", "%m/%d/%Y %T", :strftime)
    times_N03R = MtaSubwayTime.Networking.StopTimes.stop_times(not_a_target, date)

    assert 0 == Enum.count(times_N03R)
  end

  test "transforms date to seconds in day" do
    # Last F24N Weekday Stops: 26:05:30 = Saturday 02:05:30

    # Saturday
    date = Timex.parse!("12/24/2022 02:05:29", "%m/%d/%Y %T", :strftime)
    first_timeF24N = MtaSubwayTime.Networking.StopTimes.stop_times(@test_target, date) |> Enum.find(& &1[:arrival_time] > 0)

    # Saturday, but rollover from Weekday schedule
    assert "24:05:00" == first_timeF24N[:arrival_time_raw]
    assert 300 == first_timeF24N[:arrival_time]
  end

  test "returns next stop time in future" do
    # Last F24N Weekday Stops: 26:05:30 = Saturday 02:05:30
    # Next F24N Saturday Stop: 02:09:30

    # Saturday
    date = Timex.parse!("12/24/2022 02:05:29", "%m/%d/%Y %T", :strftime)
    current_seconds_in_day = MtaSubwayTime.Networking.TimeConverter.date_to_seconds_in_day(date)
    stop_times_for_id = MtaSubwayTime.Networking.StopTimes.stop_times(@test_target, date)
    next_stop_time = MtaSubwayTime.Networking.StopTimes.next_stop_time_after_second_in_day(@test_target, stop_times_for_id, current_seconds_in_day)

    # Saturday, but Weekday schedule
    assert "26:05:30" == next_stop_time[:arrival_time_raw]
    assert 7530 == next_stop_time[:arrival_time]
  end

  test "returns first stop time after last stop time" do
    # Last F24N Weekday Stops: 26:05:30 = Saturday 02:05:30
    # Next F24N Saturday Stop: 02:09:30

    # Saturday
    date = Timex.parse!("12/24/2022 02:05:31", "%m/%d/%Y %T", :strftime)
    current_seconds_in_day = MtaSubwayTime.Networking.TimeConverter.date_to_seconds_in_day(date)
    stop_times_for_id = MtaSubwayTime.Networking.StopTimes.stop_times(@test_target, date)
    next_stop_time = MtaSubwayTime.Networking.StopTimes.next_stop_time_after_second_in_day(@test_target, stop_times_for_id, current_seconds_in_day)

    # Saturday
    assert "02:09:30" == next_stop_time[:arrival_time_raw]
    assert 7770 == next_stop_time[:arrival_time]
  end

  test "returns next stop times rolling over" do
    # Last F24N Weekday Stops: 26:05:30 = Saturday 02:05:30
    # Next F24N Saturday Stop: 02:09:30

    # Saturday
    date = Timex.parse!("12/24/2022 02:05:29", "%m/%d/%Y %T", :strftime)
    next_stop_times = MtaSubwayTime.Networking.StopTimes.next_stop_times_after_date(@test_target, date, 2)

    assert 2 == Enum.count(next_stop_times)

    # Weekday Schedule
    assert 7530 == hd(next_stop_times)[:arrival_time]

    # Saturday Schedule
    assert 7770 == List.last(next_stop_times)[:arrival_time]
  end

  test "returns variable stop times" do
    # Friday
    date = Timex.parse!("12/23/2022 01:59:29", "%m/%d/%Y %T", :strftime)
    next_stop_times = MtaSubwayTime.Networking.StopTimes.next_stop_times_after_date(@test_target, date, 10)

    assert 10 == Enum.count(next_stop_times)
  end

  test "does not return any stop times in the past" do
    # Friday
    date = Timex.parse!("12/23/2022 01:59:29", "%m/%d/%Y %T", :strftime)
    current_seconds_in_day = MtaSubwayTime.Networking.TimeConverter.date_to_seconds_in_day(date)
    next_stop_times = MtaSubwayTime.Networking.StopTimes.next_stop_times_after_date(@test_target, date, 10)

    assert !Enum.any?(next_stop_times, & (&1[:arrival_time] < current_seconds_in_day))
  end

  test "returns next stop time in future accounting for feed offsets" do
    # Last F24N Weekday Stops: 26:05:30 = Saturday 02:05:30
    # Next F24N Saturday Stop: 02:09:30

    message = %TransitRealtime.FeedMessage{
      entity: [
        %TransitRealtime.FeedEntity{
          trip_update: %TransitRealtime.TripUpdate{
            trip: %TransitRealtime.TripDescriptor{
              trip_id: "BFA22GEN-F076-Weekday-00_154150_F..N69R",
              route_id: @test_target.line
            },
            stop_time_update: [
              %TransitRealtime.TripUpdate.StopTimeUpdate{
                stop_id: @test_target.stop_id,
                arrival: %TransitRealtime.TripUpdate.StopTimeEvent{
                  time: 1671847560
                }
              }
            ]
          }
        }
      ]
    }

    {:ok, result} = MtaSubwayTime.Networking.Api.handle_mta_feed_message(message, [@test_target], 0)

    # Saturday
    date = Timex.parse!("12/24/2022 02:05:31", "%m/%d/%Y %T", :strftime)
    current_seconds_in_day = MtaSubwayTime.Networking.TimeConverter.date_to_seconds_in_day(date)
    stop_times_for_id = MtaSubwayTime.Networking.StopTimes.stop_times(@test_target, date)
    next_stop_time = MtaSubwayTime.Networking.StopTimes.next_stop_time_after_second_in_day(@test_target, stop_times_for_id, current_seconds_in_day)

    MtaSubwayTime.Networking.Data.put(@test_target.line, @test_target.stop_id, nil)

    # Saturday, but Weekday schedule - should still have original raw time; adjusted seconds
    assert "26:05:30" == next_stop_time[:arrival_time_raw]

    # Offset 7530 by 30 seconds from feed
    assert 7560 == next_stop_time[:arrival_time]
    assert 30 == next_stop_time[:schedule_offset]
    assert next_stop_time[:schedule_changed]
  end
end
