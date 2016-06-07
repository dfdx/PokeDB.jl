
import Base: show, push!, start, next, done

## Store

abstract Store

function push!(store::Store, k::Key, v::Value)
    error("Method `push!` is not implemented for store of type $(typeof(store))")
end

function prepare!(store::Store)
    error("Method `prepare` is not implemented for store " *
          "of type $(typeof(store))")
end

function start(store::Store)
    error("Iteration is not implemented for store " *
          "of type $(typeof(store))")
end


# MemStore

abstract MemStore <: Store

type ArrayMemStore <: MemStore
    data::Vector{PokeRecord}
    next_idx::Int
    ArrayMemStore(capacity=1_000_000) = new(Array(PokeRecord, capacity), 1)
end

function show(io::IO, store::ArrayMemStore)
    print(io, "ArrrayMemStore($(store.next_idx-1)/$(length(store.data)))")
end

function push!(store::ArrayMemStore, k::Key, v::Value)
    store.data[store.next_idx] = PokeRecord(k, v)
    store.next_idx += 1
end

function prepare!(store::ArrayMemStore)
    sort!(store.data)
end

function start(store::ArrayMemStore)
    it = uniquesorted(store.data)
    s = start(it)
    return (it, s)  # note: putting both - iterator and actual state into
                    # ArrayMemStore's "state"
end

function next(store::ArrayMemStore, state)
    it, s = state
    x, new_s = next(it, s)
    return x, (it, new_s)
end

function done(store::ArrayMemStore, state)
    it, s = state
    return done(it, s)
end


# FileStore

type FileStore <: Store
    path::AbstractString
end

function push!(store::FileStore)
    error("FileStore doesn't support direct pushing, " *
          "use `createdump` or `mergedump` instead")
end

function prepare!(store::FileStore)
    # do nothing
end


function start(store::FileStore)
    # TODO: we open file, but don't close in iterator
    # need to handle it somehow
    io = open(store.path)
    it = PokeIterator(io)
    s = start(it)
    return (it, s)
end

function next(store::FileStore, iter_state::Tuple)
    it, s = iter_state
    x, new_s = next(it, s)
    return x, (it, new_s)
end

function done(store::FileStore, iter_state::Tuple)
    it, s = iter_state
    return done(it, s)
end




function createdump(dumpf::IOStream, memstore::MemStore)
    for rec in memstore
        writeobj(dumpf, rec)
    end
end

function mergedump(outf::IOStream, filestore::FileStore, memstore::MemStore)
    # important: memstore first since it has more recent records
    merged = mergesorted(memstore, filestore)
    for rec in merged
        writeobj(outf, rec)
    end
end


# TODO:
# 1) block read for PokeIterator
# 2) mergesorted for multiple iterators (min(map(head, iterators)); move that iter; if done, remove from list)



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

    fstore = FileStore("/tmp/new_dump")
    @time open("/tmp/dump", "w") do new_dumpf
        @profile mergedump(new_dumpf, fstore, memstore)
    end
end
