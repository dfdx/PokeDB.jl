

using DataStructures
using Iterators

include("common.jl")
include("record.jl")
include("io.jl")
include("protocol.jl")
include("unique.jl")
include("store.jl")
include("server.jl")


sample_request = PokeRequest(1, [PokeRecord(b"12345", b"old dog"),
                                 PokeRecord(b"54321", b"new tricks")])
