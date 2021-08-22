# Noosphere.jl

Library for accessing the [Global Conciousness Project](https://noosphere.princeton.edu/index.html) data in [Julia](https://julialang.org/).

# Running (currently v0.1 is not a package)

```julia
  # create new Params object with time period
  params = Params(2021, 8, 1, "00:00:00", "00:10:00", true)
  
  # get results
  res = get(params)

  # do something with header ...
  println(header.eggs_reporting)

  # do something with results dataframe
  for row in eachrow(res.data[3:end])
    push!(res.data, rootmeansquare(Array(row)))
  end

  # output sample plot
  saveplot(res)
```

# Output plot (using PlotlyJS)

![plot](https://github.com/thecategory/Noosphere.jl/blob/main/out/p.jpeg)
