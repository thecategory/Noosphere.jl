# module Noosphere

using StatsBase
using PlotlyJS
using DataFrames
using HTTP
using StringEncodings
using CSV
using DelimitedFiles
using Missings
using Dates
using TranscodingStreams
using CodecZlib

REQ_URI = "https://global-mind.org/cgi-bin/eggdatareq.pl"

export Params

mutable struct Params
    year::Int64
    month::Int64
    day::Int64
    stime::String #Dates.Time
    etime::String #Dates.Time
    gzip::Bool
end

# default values of 10 minute egg data
function Params()
    # stime = Dates.Time(t -> Dates.minute(t) == 00, 00)
    # etime = Dates.Time(t -> Dates.minute(t) == 10, 00)

    Params(2021, 8, 1, "00:00:00", "00:10:00", true)
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

mutable struct Results
    header::Header
    data::DataFrame
end

function getrequestparams(params)
    "?z=1" *
    "&year=" * string(params.year) *
    "&month=" * string(params.month) *
    "&day=" * string(params.day) *
    "&stime=" * params.stime * # Dates.format(params.stime, "HH:MM:SS") *
    "&etime=" * params.etime * #Dates.format(params.etime, "HH:MM:SS") *
    "&gzip=" * (params.gzip ? "Yes" : "No") *
    "&idate=No"
end

function get(params)
    uri_withparam = REQ_URI * getrequestparams(params)
    println("getting " * uri_withparam)
    r = HTTP.get(uri_withparam)

    str = ""
    if params.gzip == true
      io = TranscodingStream(GzipDecompressor(), IOBuffer(r.body))
      str = read(io, String)
    else
      str = decode(r.body, enc"ASCII")
    end

    #savetofile(str)

    return Results(str)
end

function savetofile(str)
    f = open("out/data.csv", "w")
    write(f, str)
    close(f)
end

function splitheader(str)
    spl = findfirst("gmtime", str)
    return spl
end

# 10,1,10,"Samples per record"
# 10,2,10,"Seconds per record"
# 10,3,30,"Records per packet"
# 10,4,200,"Trial size"
# 11,1,21,"Eggs reporting"
# 11,2,1627776000,"Start time",2021-08-01 00:00:00
# 11,3,1627776600,"End time",2021-08-01 00:10:00
# 11,4,601,"Seconds of data"

function getheader(str, spl)  
  headerstr = str[1:spl[1] - 5]

  header = Header()
  i = 1

  for line in eachline(IOBuffer(headerstr))
    val = readdlm(IOBuffer(line), ',')[:3]

    if i == 1
      header.samples_per_record =  val
    elseif i == 2
      header.seconds_per_record = val
    elseif i == 3
      header.records_per_packet = val
    elseif i == 4
      header.trial_size = val
    elseif i == 5
      header.eggs_reporting = val
    elseif i == 6
      header.start_time = Dates.unix2datetime(val)
    elseif i == 7
      header.end_time =  Dates.unix2datetime(val)
    elseif i == 8
      header.seconds_of_data = val
    end
    i = i + 1
  end

  return header
end

function getdataframe(str, spl)
  datastr = str[spl[1] - 1:length(str)]
  df = CSV.File(IOBuffer(datastr), silencewarnings=true) |> DataFrame
  for col in names(df)
    df[col] = Missings.coalesce.(df[col], 0)
  end

  return df
end

function rootmeansquare(A)
  s = 0.0
  for a in A
     s += a * a
  end
  return sqrt(s / length(A))
end

function saveplot(res)
  header = res.header
  df = res.data

  res = []

  for row in eachrow(df[3:end])
    push!(res, rootmeansquare(Array(row)))
  end

  s = scatter(x=:gmtime, y=res, mode="lines")

  layout = Layout(title="Egg Data (Root Mean Square) for " * 
                  Dates.format(header.start_time, "yyyy-mm-dd HH:MM:SS") * " - " *
                  Dates.format(header.end_time, "yyyy-mm-dd HH:MM:SS") *
                  " (" * string(header.eggs_reporting) * " Eggs Reporting)", 
                  width=1200,
                  height=700)

  p = plot(s, layout)

  savefig(p, "out/p.html")
end

function Results(str)
  spl = splitheader(str)
  header = getheader(str, spl)
  df = getdataframe(str, spl)
  Results(header, df)
end

function test()
  params = Params()
  
  res = get(params)

  saveplot(res)
end

test()

# end # module