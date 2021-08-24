macro optstruct(s)
  if s.head !== :struct 
      error("Not a struct def")
  end 

  ismutable = s.args[1]
  if !ismutable
      error("Not mutable")
  end
  
  name = s.args[2]
  body = s.args[3]    

  ctor = :(function $(name)(;kwargs...)
              K = new()
              for (key, value) in kwargs
                  field_type_key = typeof(getfield(K,key))
                  setfield!(K, key, convert(field_type_key, value))
              end
              return K
          end)
          
  newbody = [body.args; ctor]
  
  return Expr(s.head, ismutable, name, Expr(body.head, newbody...))
end

function rootmeansquare(A)
  s = 0.0
  for a in A
     s += a * a
  end
  return sqrt(s / length(A))
end

function httpgetgzip(uri)
  r = HTTP.get(uri)
  io = TranscodingStream(GzipDecompressor(), IOBuffer(r.body))
  str = read(io, String)

  return str
end

function savetofile(str, path)
  f = open(path, "w")
  write(f, str)
  close(f)
end