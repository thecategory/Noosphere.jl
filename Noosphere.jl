using HTTP
using StringEncodings
using CSV
using DataFrames
using Missings
using URIs
using StatsPlots

uri = "https://global-mind.org/cgi-bin/eggdatareq.pl"
headers = Dict("User-Agent" => "HTTP.jl")

function getrequestparams(params)
  return "?z=1&year=" * params["year"] * 
  "&month=" * params["month"] * 
  "&day=" * params["day"] * 
  "&stime=" * params["stime"] * 
  "&etime=" * params["etime"] * 
  "&gzip=No&idate=Yes"
end

params = Dict(
    "z" => "1",
    "year" => "2021",
    "month" => "8",
    "day" => "1",
    "stime" => "00:00:00",
    "etime" => "00:01:00",
    "gzip" =>"No",
    "idate"=>"Yes"
)

function getrequestbodystr()
    uri_withparam = URI(uri * getrequestparams(params))
    r = HTTP.get(uri_withparam)
    str = decode(r.body, enc"ASCII")
    return str
end

function savetofile(str)
    println(str)
    f = open("data.csv", "w")
    write(f, str)
    close(f)
end

function getheaderdatasplit(str)
  spl = findfirst("gmtime", str)
  return spl
end

function getheaderdf(str, spl)
  faux_cols = "c1, c2, c3, c4\n"
  headerstr = faux_cols * str[1:spl[1] - 5]
  headerdf = dropmissing(CSV.File(IOBuffer(headerstr), silencewarnings=true) |> DataFrame)
  return headerdf
end

function getdf(str, spl)
  datastr = str[spl[1] - 1:length(str)]
  df = CSV.File(IOBuffer(datastr), silencewarnings=true) |> DataFrame
end

function test()
  str = getrequestbodystr()
  spl = getheaderdatasplit(str)
  headerdf = getheaderdf(str, spl)
  # println(headerdf)
  df = getdf(str, spl)
  println(df)

end

function testplot()
  datastr = read("data.csv", String)
  df = CSV.File(IOBuffer(datastr), silencewarnings=true) |> DataFrame
  # @df df plot(:x, cols(propertynames(df)[2:end]))
end


# testplot()

test()