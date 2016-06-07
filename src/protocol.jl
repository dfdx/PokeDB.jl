
immutable PokeRequest
    rid::Int64                 # request id
    data::Vector{PokeRecord}   # data  
end

immutable PokeResponse
    rid::Int64                 # id of corresponding request
    status::Int16              # request status code
    message::ASCIIString       # human-readable error message (if any)
end



