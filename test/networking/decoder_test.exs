defmodule MtaSubwayTime.Networking.DecoderTest do
  use ExUnit.Case, async: true

  test "reduces and sorts groups and stops by id and line" do
    message = %TransitRealtime.FeedMessage{
      entity: [
        %TransitRealtime.FeedEntity{
          trip_update: %TransitRealtime.TripUpdate{
            trip: %TransitRealtime.TripDescriptor{
              route_id: "A"
            },
            stop_time_update: [
              %TransitRealtime.TripUpdate.StopTimeUpdate{
                stop_id: "0",
                arrival: %TransitRealtime.TripUpdate.StopTimeEvent{
                  time: 20
                }
              }
            ]
          }
        },
        %TransitRealtime.FeedEntity{
          trip_update: %TransitRealtime.TripUpdate{
            trip: %TransitRealtime.TripDescriptor{
              route_id: "A"
            },
            stop_time_update: [
              %TransitRealtime.TripUpdate.StopTimeUpdate{
                stop_id: "0",
                arrival: %TransitRealtime.TripUpdate.StopTimeEvent{
                  time: 10
                }
              },
              %TransitRealtime.TripUpdate.StopTimeUpdate{
                stop_id: "0",
                arrival: %TransitRealtime.TripUpdate.StopTimeEvent{
                  time: 30
                }
              }
            ]
          }
        }
      ]
    }

    result = MtaSubwayTime.Networking.Decoder.subway_line_stops(message, "A", "0", -1, 0)

    assert result.line == "A"
    assert result.stop_id == "0"
    assert result.arrivals == [10, 20, 30]
  end

  test "returns feed message entities for line" do
    message = %TransitRealtime.FeedMessage{
      entity: [
        %TransitRealtime.FeedEntity{
          trip_update: %TransitRealtime.TripUpdate{
            trip: %TransitRealtime.TripDescriptor{
              route_id: "F"
            }
          }
        }
      ]
    }

    count = Enum.count(
      MtaSubwayTime.Networking.Decoder.filter_entities_for_line(message, "F")
    )

    assert count == 1
  end

  test "does not return feed message entities for other lines" do
    message = %TransitRealtime.FeedMessage{
      entity: [
        %TransitRealtime.FeedEntity{
          trip_update: %TransitRealtime.TripUpdate{
            trip: %TransitRealtime.TripDescriptor{
              route_id: "F"
            }
          }
        }
      ]
    }

    count = Enum.count(
      MtaSubwayTime.Networking.Decoder.filter_entities_for_line(message, "B")
    )

    assert count == 0
  end

  test "does not return feed message entities for empty trip updates" do
    message = %TransitRealtime.FeedMessage{
      entity: [
        %TransitRealtime.FeedEntity{
          trip_update: nil,
        },
        %TransitRealtime.FeedEntity{
          trip_update: %TransitRealtime.TripUpdate{
            trip: %TransitRealtime.TripDescriptor{
              route_id: "F"
            }
          }
        }
      ]
    }

    count = Enum.count(
      MtaSubwayTime.Networking.Decoder.filter_entities_for_line(message, "F")
    )

    assert count == 1
  end

  test "returns stop times for in ascending order" do
    stop_times = [
      %TransitRealtime.TripUpdate.StopTimeUpdate{
        stop_id: "A",
        arrival: %TransitRealtime.TripUpdate.StopTimeEvent{
          time: 20
        }
      },
      %TransitRealtime.TripUpdate.StopTimeUpdate{
        stop_id: "A",
        arrival: %TransitRealtime.TripUpdate.StopTimeEvent{
          time: 10
        }
      }
    ]

    results = MtaSubwayTime.Networking.Decoder.stop_times_after_ascending(stop_times, "A", 9)
    first_result = results |> hd()

    assert Enum.count(results) == 2
    assert first_result.arrival.time == 10
  end

  test "does not return stop times for other stops" do
    stop_times = [
      %TransitRealtime.TripUpdate.StopTimeUpdate{
        stop_id: "A",
        arrival: %TransitRealtime.TripUpdate.StopTimeEvent{
          time: 20
        }
      },
      %TransitRealtime.TripUpdate.StopTimeUpdate{
        stop_id: "A",
        arrival: %TransitRealtime.TripUpdate.StopTimeEvent{
          time: 10
        }
      }
    ]

    results = MtaSubwayTime.Networking.Decoder.stop_times_after_ascending(stop_times, "B", 0)

    assert Enum.count(results) == 0
  end

  test "does not return stop times below threshold" do
    stop_times = [
      %TransitRealtime.TripUpdate.StopTimeUpdate{
        stop_id: "A",
        arrival: %TransitRealtime.TripUpdate.StopTimeEvent{
          time: 20
        }
      },
      %TransitRealtime.TripUpdate.StopTimeUpdate{
        stop_id: "A",
        arrival: %TransitRealtime.TripUpdate.StopTimeEvent{
          time: 10
        }
      }
    ]

    results = MtaSubwayTime.Networking.Decoder.stop_times_after_ascending(stop_times, "A", 10)
    first_result = results |> hd()

    assert Enum.count(results) == 1
    assert first_result.arrival.time == 20
  end

  test "maps stop times to epoch values ascending" do
    stop_times = [
      %TransitRealtime.TripUpdate.StopTimeUpdate{
        arrival: %TransitRealtime.TripUpdate.StopTimeEvent{
          time: 20
        }
      },
      %TransitRealtime.TripUpdate.StopTimeUpdate{
        arrival: %TransitRealtime.TripUpdate.StopTimeEvent{
          time: 10
        }
      }
    ]

    results = MtaSubwayTime.Networking.Decoder.stop_time_epochs_ascending(stop_times)
    first_result = results |> hd()

    assert Enum.count(results) == 2
    assert first_result == 10
  end
end