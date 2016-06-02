
# mostly copied from Kafka.jl
# primitives, strings and arrays

writeobj(io::IO, n::Integer) = write(io, hton(n))
readobj{T<:Integer}(io::IO, ::Type{T}) = ntoh(read(io, T))

function writeobj(io::IO, s::ASCIIString)
    len = Int16(length(s))
    writeobj(io, len > 0 ? len : -1)
    write(io, s)
end
function readobj(io::IO, ::Type{ASCIIString})
    len = readobj(io, Int16)
    return len > 0 ? bytestring(readbytes(io, len)) : ""
end

function writeobj{T}(io::IO, arr::Vector{T})
    len = Int32(length(arr))
    writeobj(io, len)
    for x in arr
        writeobj(io, x)
    end
end
function readobj{T}(io::IO, ::Type{Vector{T}})
    len = readobj(io, Int32)
    arr = Array(T, len)
    for i=1:len
        arr[i] = readobj(io, T)
    end
    return arr
end

# composite types
function writeobj(io::IO, o)
    for f in fieldnames(o)
        writeobj(io, getfield(o, f))
    end
end
function readobj{T}(io::IO, ::Type{T})
    vals = Array(Any, length(T.types))
    for (i, t) in enumerate(T.types)
        vals[i] = readobj(io, t)
    end
    return T(vals...)
end
