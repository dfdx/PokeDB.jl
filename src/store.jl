

## Store

abstract Store

function Base.push!(store::Store, k::Key, v::Value)
    error("Method `push!` is not implemented for store of type $(typeof(store))")
end

function prepare!(store::Store)
    error("Method `prepare` is not implemented for store " *
          "of type $(typeof(store))")
end

function iterator(store::Store)
    error("Method `iterator` is not implemented for store " *
          "of type $(typeof(store))")
end

# MemStore

abstract MemStore <: Store

type ArrayMemStore <: MemStore
    data::Vector{PokeRecord}
    next_idx::Int    
    ArrayMemStore(capacity=1_000_000) = new(Array(PokeRecord, capacity), 1)
end

function Base.show(io::IO, store::ArrayMemStore)
    print(io, "ArrrayMemStore($(store.next_idx-1)/$(length(store.data)))")
end

function Base.push!(store::ArrayMemStore, k::Key, v::Value)
    store.data[store.next_idx] = PokeRecord(k, v)
    store.next_idx += 1    
end

function prepare!(store::ArrayMemStore)
    sort!(store.data)
end

function Base.start(store::ArrayMemStore)
    
    return start(store.data)
end

function Base.next(store::ArrayMemStore, s)
    
    return next(store.data, s)
end

function Base.done(store::ArrayMemStore, s)    
    return done(store.data, s)
end


function iterator(store::ArrayMemStore)
    return store.data  # TODO: distinct sorted
end


# FileStore

type FileStore <: Store
    path::AbstractString    
end

function Base.push!(store::FileStore)
    error("FileStore doesn't support direct pushing, " *
          "use `createdump` or `mergedump` instead")
end

function prepare!(store::FileStore)
    # do nothing
end

function iterator(store::FileStore)
    io = open(store.path)
    return PokeIterator(io)
end



function createdump(dumpf::IOStream, memstore::MemStore)
    for rec in iterator(memstore)
        writeobj(dumpf, rec)
    end
end

function mergedump(outf::IOStream, filestore::FileStore, memstore::MemStore)
    merged = mergesorted(iterator(memstore), iterator(filestore))  # important: memstore first
    for rec in merged
        write(outf, rec)
    end
end


# pre-allocated array of KV pairs: ~6s
# Dict: ~15s
# SortedDict: ~9s


function perf_test()
    N = 1_000_000
    println("$(N * 110 / 1024 / 1024) Mb")
    K = [rand(UInt8, 10) for i=1:N]
    V = [rand(UInt8, 100) for i=1:N]
    KV = collect(zip(K, V))        
    A = Array(Tuple{Vector{UInt8},Vector{UInt8}}, N)
    SD = create_memstore()
    @time @inbounds for i=1:N A[i] = KV[i] end
    @time sort(A, lt=(x,y) -> (bytestring(x[1]) < (bytestring(y[1]))))
    @time sort(A)
    @time @inbounds for i=1:N SD[K[i]] = V[i] end
    @time @inbounds for i=1:N SD[K[i]] = V[i] end
    @time collect(SD)
end


function main()
    memstore = ArrayMemStore()
    @time for i=1:1_000_000
        push!(memstore, rand(UInt8, 10), rand(UInt8, 100))
    end
    @time prepare!(memstore)
    @time open("/tmp/dump", "w") do dumpf
        createdump(dumpf, memstore)
    end
end
