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

include("src/util.jl")
include("src/cache.jl")
include("src/parse.jl")
include("src/plot.jl")
include("src/request.jl")

function test()
    start_day = Date(2021, 7, 1)
    end_day = Date(2021, 7, 2)

    dur = Duration(start_day, end_day)

    params = Params(duration=dur)
    res = get(params)

    df = DataFrame()
    for r in res
        df = vcat(df, r.data, cols=:union)
    end

    header = Header()

    header.start_time = res[1].header.start_time
    header.end_time = res[end].header.end_time
    header.eggs_reporting = res[end].header.eggs_reporting

    out = Result(header, df, "")
    saveplot(out)

    # params = Params(year=2021, month=8, day=1, stime="00:00:00", etime="23:59:59")
    # res = get(params)
    # saveplot(res)
end

test()

# end # module