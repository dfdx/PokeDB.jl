
immutable PokeRecord
    key::Vector{UInt8}
    value::Vector{UInt8}
end

function Base.show(io::IO, rec::PokeRecord)
    print(io, "PokeRecord($(bytestring(rec.key)))")
end

create_memstore() =
    SortedDict((Dict{Vector{UInt8}, Vector{UInt8}}()), Base.Forward)
