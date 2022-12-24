defmodule MtaSubwayTime.Models.SubwayArrival do
  defstruct line: "", trip_id: "", stop_id: "", direction: "", arrival_time: 0, schedule_changed: false, schedule_offset: 0
end