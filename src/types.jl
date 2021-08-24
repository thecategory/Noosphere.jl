mutable struct Duration
  start_day::Date
  end_day::Date
end

mutable struct Params
  year::Int64
  month::Int64
  day::Int64
  stime::String # Dates.Time
  etime::String # Dates.Time

  multiday::Bool
  duration::Duration
end

mutable struct Header
  samples_per_record::Int64
  seconds_per_record::Int64
  records_per_packet::Int64
  trial_size::Int64
  eggs_reporting::Int64
  start_time::DateTime
  end_time::DateTime
  seconds_of_data::Int64

  Header() = new()
end

mutable struct Result
  header::Header
  data::DataFrame
  raw::String
end