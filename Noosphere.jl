using HTTP
using StringEncodings
using CSV
using DataFrames
using Missings
using PlotlyJS
using DataFrames
using StatsBase
using DelimitedFiles
using Dates

uri = "https://global-mind.org/cgi-bin/eggdatareq.pl"

mutable struct Params
  z::Int
  year::Int64
  month::Int64
  day::Int64
  stime::String
  etime::String
  gzip::String
  idate::String
end

# default values of 10 minute egg data
function Params()
  Params(1, 2021, 8, 1, "00:00:00", "00:10:00", "No", "Yes")
end

mutable struct Header
  samples_per_record::Int64
  seconds_per_record::Int64
  records_per_packet::Int64
  trial_size::Int64
  eggs_reporting::Int64
  start_time::Int64
  end_time::Int64
  seconds_of_data::Int64
  
  Header() = new()
end

mutable struct Results
  header::Header
  data::DataFrame
end

function getrequestparams(params)
  return  "?z=" * string(params.z) *
          "&year=" * string(params.year) *
          "&month=" * string(params.month) *
          "&day=" * string(params.day) *
          "&stime=" * params.stime *
          "&etime=" * params.etime *
          "&gzip" * params.gzip *
          "&idate" * params.idate
end

function get(params)
    uri_withparam = uri * getrequestparams(params)
    println("getting " * uri_withparam)
    r = HTTP.get(uri_withparam)
    str = decode(r.body, enc"ASCII")
    savetofile(str)
    return Results(str)
end

function savetofile(str)
    f = open("data.csv", "w")
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
      header.start_time = val
    elseif i == 7
      header.end_time = val
    elseif i == 8
      header.seconds_of_data = val
    end
    i = i + 1
  end

  return header
end

function getdf(str, spl)
  datastr = str[spl[1] - 1:length(str)]
  df = CSV.File(IOBuffer(datastr), silencewarnings=true) |> DataFrame
  for col in names(df)
    df[col] = Missings.coalesce.(df[col], 0)
  end

  return df
end

function rms(A)
  s = 0.0
  for a in A
     s += a*a
  end
  return sqrt(s / length(A))
end

function saveplot(results)
  header = results.header
  df = results.data

  res = []

  for row in eachrow(df[3:end])
    push!(res, rms(Array(row)))
  end

  s = scatter(x=:gmtime, y=res, mode="lines")

  layout = Layout(title="Egg Data (Root Mean Square) for " * 
                Dates.format(Dates.unix2datetime(header.start_time), "yyyy-mm-dd HH:MM:SS") * " - " *
                Dates.format(Dates.unix2datetime(header.end_time), "yyyy-mm-dd HH:MM:SS") * " (" *
                string(header.eggs_reporting) * " Eggs Reporting)", 
                width=1000,
                height=700)

  p = plot(s, layout)

  savefig(p, "p.html")
end

function Results(str)
  spl = splitheader(str)
  header = getheader(str, spl)
  df = getdf(str, spl)
  Results(header, df)
end

function test()
  params = Params()
  
  results = get(params)

  saveplot(results)
end

test()