using HTTP
using StringEncodings
using CSV
using DataFrames
using Missings
using URIs
using Plots
# using StatsPlots
using UnicodePlots

uri = "https://global-mind.org/cgi-bin/eggdatareq.pl"

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

function getparams(params)
  return "?z=" * params["z"] *
  "&year=" * params["year"] * 
  "&month=" * params["month"] * 
  "&day=" * params["day"] * 
  "&stime=" * params["stime"] * 
  "&etime=" * params["etime"] * 
  "&gzip" * params["gzip"] *
  "&idate" * params["idate"]
end

function get()
    uri_withparam = URI(uri * getparams(params))
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

function splitheader(str)
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
  df = dropmissing(CSV.File(IOBuffer(datastr), silencewarnings=true) |> DataFrame)
  return df
end

function test()
  str = get()
  spl = splitheader(str)
  headerdf = getheaderdf(str, spl)
  println(headerdf)
  df = getdf(str, spl)
  println(df)
end

function testplot()
  df = CSV.read("data.csv", DataFrame)

  unicodeplots()
  plot(df.gmtime, [df[:2], df[:3], df[:4], df[:5]])
   # savefig(p, "data.png")
end

testplot()

# test()