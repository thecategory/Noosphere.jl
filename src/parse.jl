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