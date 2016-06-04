
immutable PokeRecord
    key::Vector{UInt8}
    value::Vector{UInt8}
end

new_cache() = SortedDict((Dict{Vector{UInt8}, Vector{UInt8}}()), Base.Forward)
