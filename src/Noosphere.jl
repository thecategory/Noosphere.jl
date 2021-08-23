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
# using MarketData

include("src/util.jl")

REQ_URI = "https://global-mind.org/cgi-bin/eggdatareq.pl"

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

# function DefParams(;year::Int64=2018,month::Int64=1,day::Int64=1,stime::String="00:00:00",etime::String="00:00:00",multiday::Bool=false,duration::Duration=Duration(Date(2018,8,1), Date(2018,8,3)))
function Params(;kwargs...)  
  kwargs_dict = Dict(kwargs)

  if haskey(kwargs_dict, :duration) == true
    Params(0, 0, 0, 
           "", "", 
           true, kwargs[:duration])
  else
    Params(kwargs[:year],kwargs[:month],kwargs[:day],
          kwargs[:stime],kwargs[:etime],
          false, Duration(Date(1970,1,1), Date(1970,1,1)))
  end
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
end

function getduration(dur)
    start_day = dur.start_day
    end_day = dur.end_day

    duration = start_day:Day(1):end_day

    return collect(duration)
end

# function getrequestparams(params)
#   return getrequestparams(params.year, params.month, params.day, params.stime, params.etime)
# end

function getrequestparams(params)
  return getrequestparams(params.year, params.month, params.day, params.stime, params.etime)
end

function getrequestparams(year, month, day, stime, etime)
    "?z=1" *
    "&year=" * string(year) *
    "&month=" * string(month) *
    "&day=" * string(day) *
    "&stime=" * stime * # Dates.format(params.stime, "HH:MM:SS") *
    "&etime=" * etime * # Dates.format(params.etime, "HH:MM:SS") *
    "&gzip=Yes" * # (params.gzip ? "Yes" : "No") *
    "&idate=No"
end

function get(params)
    if params.multiday == true
        dur = getduration(params.duration)
        results = Result[]

        for day in dur
            req = getrequestparams(Dates.year(day), Dates.month(day), Dates.day(day), 
                                  "00:00:00", "23.59.59")
            uri_withparam = REQ_URI * req
            println("getting " * uri_withparam)
            ret = httpgetgzip(uri_withparam)
            res = Result(ret)
            push!(results, res)
        end

        return results
    else
        uri_withparam = REQ_URI * getrequestparams(params)
        println("getting " * uri_withparam)
        ret = httpgetgzip(uri_withparam)
        return Result(ret)
    end


    # else
    #   str = decode(r.body, enc"ASCII")
    # end

    # savetofile(str)


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
                  Dates.format(header.end_time, "HH:MM:SS") *
                  " (" * string(header.eggs_reporting) * " Eggs Reporting)",
                  width=1200,
                  height=700)

    p = plot(s, layout)

    savefig(p, "out/p.html")
end

function Result(str)
    spl = splitheader(str)
    header = getheader(str, spl)
    df = getdataframe(str, spl)
    Result(header, df)
end

function test()
    # start_day = Date(2021, 8, 1)
    # end_day = Date(2021, 8, 3)
    # dur = Duration(start_day, end_day)

    # params = Params(duration=dur)
    # res = get(params)


    params = Params(year=2021, month=8, day=1, stime="00:00:00", etime="23:59:59")
    res = get(params)
    saveplot(res)

    # start = DateTime(2021, 8, 1)
    # YahooOpt(period1 = start)

    # df = yahoo("^DJI") |> DataFrame
    # println(df)

end

test()

# end # module