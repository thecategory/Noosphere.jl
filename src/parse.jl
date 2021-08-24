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

# 12,"gmtime",,1,37,112,226,228,231,1070,1237,2028,2083,2178,2220,2232,2250,3002,3060,3101,3104,3106,4002,4234
# 13,1625097600,,105,106,93,98,106,95,94,,106,90,98,92,90,98,,104,106,94,101,110,110
# 13,1625097601,,94,111,103,97,97,104,99,,104,103,102,103,103,94,,95,109,106,104,113,91
# 13,1625097602,,101,114,102,108,101,97,97,,93,89,95,97,102,99,,102,117,100,102,103,112
# 13,1625097603,,94,112,94,95,106,103,107,,106,94,108,106,102,105,,114,101,106,101,84,98

function getdataframe(str, spl)
  datastr = str[spl[1] - 1:length(str)]
  df = CSV.File(IOBuffer(datastr), silencewarnings=true) |> DataFrame
  coalesce.(df, 0)

  for col in names(df)
      df[col] = Missings.coalesce.(df[col], 0)
  end

  return df
end

function splitheader(str)
  spl = findfirst("gmtime", str)
  return spl
end