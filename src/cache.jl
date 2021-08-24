const CACHE_DIR = "../_cache/"

function getcache(dur)
  days = numofdays(dur)
  res = Result[]

  for day in days
      p = daycachefilename(day)
      if ispath(p) == false
          continue
      end
      println("reading " * p)
      raw = read(p, String)
      c = Result(raw)
      push!(res, c)
  end

  return res
end

function savecache(res)
  if ispath(CACHE_DIR) == false
      mkdir(CACHE_DIR)
  end
  p = rescachefilename(res)
  if ispath(p) == false
      savetofile(res.raw, p)
  end
end

function daycachefilename(day)
  return CACHE_DIR * Dates.format(day, "yyyy_mm_dd") * ".csv"
end

function rescachefilename(res)
  return CACHE_DIR * Dates.format(res.header.start_time, "yyyy_mm_dd") * ".csv"
end

function findday(results, day)
  for res in results
      d = Date(Dates.year(res.header.start_time), 
      Dates.month(res.header.start_time),
      Dates.day(res.header.start_time))
      if d == day
          return res
      end
  end

  return false
end