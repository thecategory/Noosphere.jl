const REQ_URI = "https://global-mind.org/cgi-bin/eggdatareq.pl"

function Params(;kwargs...)
    kwargs_dict = Dict(kwargs)

    if haskey(kwargs_dict, :duration) == true
        Params(0, 0, 0,
           "", "",
           true, kwargs[:duration])
    else
        Params(kwargs[:year],kwargs[:month],kwargs[:day],
          kwargs[:stime],kwargs[:etime],
          false, Duration(Date(1970, 1, 1), Date(1970, 1, 1)))
    end
end

function Result(str)
    spl = splitheader(str)
    header = getheader(str, spl)
    df = getdataframe(str, spl)
    Result(header, df, str)
end

function numofdays(dur)
    start_day = dur.start_day
    end_day = dur.end_day

    duration = start_day:Day(1):end_day

    return collect(duration)
end

function getrequestparams(params)
    return getrequestparams(params.year, params.month, params.day, params.stime, params.etime)
end

function getrequestparams(year, month, day, stime, etime)
    "?z=1" *
    "&year=" * string(year) *
    "&month=" * string(month) *
    "&day=" * string(day) *
    "&stime=" * stime * # Dates.format(params.stime, "HH:MM:SS") *
    "&etime=" * etime * # Dates.format(params.etime, "HH:MM:SS") *
    "&gzip=Yes" * # (params.gzip ? "Yes" : "No") *
    "&idate=No"
end

function get(params)
    results = Result[]
    cache = getcache(params.duration)

    if params.multiday == true
        days = numofdays(params.duration)


        for day in days
            c = findday(cache, day)
            if c != false
                push!(results, c)
                continue
            end
            req = getrequestparams(Dates.year(day),
                                  Dates.month(day), 
                                  Dates.day(day),
                                  "00:00:00", "23.59.59")
            uri_withparam = REQ_URI * req
            println("getting " * uri_withparam)
            ret = httpgetgzip(uri_withparam)
            res = Result(ret)
            push!(results, res)
            savecache(res)
        end

        return results
    else
        uri_withparam = REQ_URI * getrequestparams(params)
        println("getting " * uri_withparam)
        ret = httpgetgzip(uri_withparam)
        res = Result(ret)
        push!(results, res)

        return results
    end
end