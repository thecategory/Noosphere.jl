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

include("types.jl")
include("util.jl")
include("cache.jl")
include("parse.jl")
include("plot.jl")
include("request.jl")

function test()
    start_day = Date(2021, 7, 1)
    end_day = Date(2021, 7, 2)

    dur = Duration(start_day, end_day)

    params = Params(duration=dur)
    res = get(params)

    saveplotmultiday(res)

    # params = Params(year=2021, month=8, day=1, stime="00:00:00", etime="23:59:59")
    # res = get(params)
    # saveplot(res)
end

test()

# end # module