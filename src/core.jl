
using DataStructures

include("io.jl")
include("protocol.jl")
include("server.jl")


sample_request = PokeRequest(1, KVPair[(b"12345", b"old dog"),
                                       (b"54321", b"new tricks")])
