function saveplot(res)
  header = res.header
  df = res.data

  res = []
  
  for col in names(df)
      df[col] = Missings.coalesce.(df[col], 0)
  end

  for row in eachrow(df[3:end])
      push!(res, rootmeansquare(Array(row)))
  end

  s = scatter(x=:gmtime, y=res, mode="lines")

  layout = Layout(title="Egg Data (Root Mean Square) for " *
                Dates.format(header.start_time, "yyyy-mm-dd HH:MM:SS") * " - " *
                Dates.format(header.end_time, "yyyy-mm-dd HH:MM:SS") *
                " (" * string(header.eggs_reporting) * " Eggs Reporting)",
                width=1200,
                height=700)

  p = plot(s, layout)

  savefig(p, "./out/p.html")
end

function saveplotmultiday(res)
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
end