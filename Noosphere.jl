using HTTP
using StringEncodings
using CSV
using DataFrames
using Missings
using URIs
using PlotlyJS
using DataFrames

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

mutable struct Header
  samples_per_record::Int64
  seconds_per_record::Int64
  records_per_packet::Int64
  trial_size::Int64
  eggs_reporting::Int64
  start_time::String
  end_time::String
  seconds_of_data::Int64
  
  Header() = new()
end

params = Dict(
    "z" => "1",
    "year" => "2021",
    "month" => "8",
    "day" => "1",
    "stime" => "00:00:00",
    "etime" => "00:10:00",
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
    uri_withparam = uri * getparams(params)
    println("getting " * uri_withparam)
    r = HTTP.get(uri_withparam)
    str = decode(r.body, enc"ASCII")
    savetofile(str)
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

# 10,1,10,"Samples per record"
# 10,2,10,"Seconds per record"
# 10,3,30,"Records per packet"
# 10,4,200,"Trial size"
# 11,1,21,"Eggs reporting"
# 11,2,1627776000,"Start time",2021-08-01 00:00:00
# 11,3,1627776060,"End time",2021-08-01 00:01:00
# 11,4,61,"Seconds of data"

function getheader(str, spl)  
  headerstr = str[1:spl[1] - 5]
  spl = split(headerstr, ",")
  println(spl)
  header = Header()
  header.samples_per_record =  parse(Int64, strip(String(spl[3]), "\\n"))
  header.seconds_per_record = parse(Int64, strip(String(spl[7]), "\\n"))
  header.records_per_packet = parse(Int64, spl[11])
  header.trial_size = parse(Int64, spl[15])
  header.eggs_reporting = parse(Int64, spl[19])
  header.start_time = spl[23]
  header.end_time = spl[28]
  return header
end

function getdf(str, spl)
  datastr = str[spl[1] - 1:length(str)]
  df = CSV.File(IOBuffer(datastr), silencewarnings=true) |> DataFrame
  println(df)
  return df
end

function test()
  str = get()
  spl = splitheader(str)
  # header = getheader(str, spl)
  # println(header)
  df = getdf(str, spl)
  for col in names(df)
    df[col] = Missings.coalesce.(df[col], 0)
  end

  data = AbstractTrace[]
  for col in names(df)[2:end]
    if col == "Column2"
      continue
    end
    push!(data, scatter(x=:gmtime, y=df[col], mode="lines", name=col))
  end

  layout = Layout(title="Egg Data",  
                width=1000,
                height=700)

  p = plot(data, layout)

  savefig(p, "p.html")

end

function testplot()
  #names!(df, Symbol.(replace.(string.(names(df)), Ref(r"\s"=>""))))
  # df = CSV.read("data.csv", DataFrame)
  # println(df)
  # unicodeplots()
  # plot(df.gmtime, [df[2:end]])
   # savefig(p, "data.png")
end

#testplot()

test()