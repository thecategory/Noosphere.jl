function getcache(dur)
  days = numofdays(dur)
  ret = Result[]

  for r in days
      p = "./_cache/" * Dates.format(r, "yyyy_mm_dd") * ".csv"
      if ispath(p) == false
          continue
      end
      println("reading " * p)
      raw = read(p, String)
      c = Result(raw)
      push!(ret, c)
  end

  return ret
end

function savecache(r)
  s = Dates.format(r.header.start_time, "yyyy_mm_dd") * ".csv"
  if ispath("_cache") == false
      mkdir("_cache")
  end
  p = "_cache/" * s
  if ispath(p) == false
      savetofile(r.raw, p)
  end
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