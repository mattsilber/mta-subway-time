defmodule MtaSubwayTime.Networking.DecoderTest do
  use ExUnit.Case, async: true

  test "reduces and sorts groups and stops by id and line" do
    message = %TransitRealtime.FeedMessage{
      entity: [
        %TransitRealtime.FeedEntity{
          trip_update: %TransitRealtime.TripUpdate{
            trip: %TransitRealtime.TripDescriptor{
              trip_id: "0",
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
              trip_id: "1",
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

    result = MtaSubwayTime.Networking.Decoder.subway_line_stops(message, "A", "0", 0)

    expected_arrivals = [
      %MtaSubwayTime.Models.SubwayArrivalFeedUpdate{
        stop_id: "0",
        trip_id: "1",
        arrival_time: 10
      },
      %MtaSubwayTime.Models.SubwayArrivalFeedUpdate{
        stop_id: "0",
        trip_id: "0",
        arrival_time: 20
      },
      %MtaSubwayTime.Models.SubwayArrivalFeedUpdate{
        stop_id: "0",
        trip_id: "1",
        arrival_time: 30
      },
    ]

    assert result.line == "A"
    assert result.stop_id == "0"
    assert result.arrivals == expected_arrivals
  end

  test "returns feed message entities for line" do
    message = %TransitRealtime.FeedMessage{
      entity: [
        %TransitRealtime.FeedEntity{
          trip_update: %TransitRealtime.TripUpdate{
            trip: %TransitRealtime.TripDescriptor{
              trip_id: "0",
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
              trip_id: "0",
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
              trip_id: "0",
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

end