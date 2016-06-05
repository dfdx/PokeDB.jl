
type PokeRecord
    key::Vector{UInt8}
    value::Vector{UInt8}
end




function createdump(dumpf::IOStream, memstore::SortedDict)
    for (k, v) in memstore
        writeobj(dumpf, PokeRecord(k, v))
    end
end


function mergedump(outf::IOStream, dumpf::IOStream, memstore::SortedDict)
    state = start(memstore)
    while !eof(dumpf) && !done(memstore)

    end
    if !done(memstore)

    end
end


type PokeIterator
    io::IO
end

function Base.start(pit::PokeIterator)
    return nothing
end

function Base.next(pit::PokeIterator, s)
    return readobj(pit.io, PokeRecord)
end

function Base.done(pit::PokeIterator, s)
    return eof(pit.io)
end


## type MergedState
##     s1    # (next) state of iterator 1
##     s2    # (next) state of iterator 2
##     x1    # current head of iterator 1
##     x2    # current head of iterator 2
## end

## type MergedIter
##     it1
##     it2
## end


## function mergesorted(it1, it2)
##     return MergedIter(it1, it2)
## end


## function Base.start(mit::MergedIter)
##     # assuming both iterations have at least 1 element
##     x1, s1 = next(mit.it1, start(mit.it1))
##     x2, s2 = next(mit.it2, start(mit.it2))
##     return MergedState(s1, s2, x1, x2)
## end


## function Base.next(mit::MergedIter, s::MergedState)
##     # todo: handle case when mergeiter is done
##     if done(mit.it1, s.s1)        
##         if s.x1 != nothing
##             # we have one more "cached element"            
##             return s.x1, MergedState(s.s1, s.s2, nothing, s.x2)
##         else
##             nx2, ns2 = next(mit.it2, s.s2)
##             return s.x2, MergedState(s.s1, ns2, s.x1, nx2)
##         end        
##     elseif done(mit.it2, s.s2)
##         if s.x1 != nothing
##             # we have one more "cached element"            
##             return s.x2, MergedState(s.s1, s.s2, s.x1, nothing)
##         else
##             nx1, ns1 = next(mit.it1, s.s1)
##             return s.x1, MergedState(ns1, s.s2, nx1, s.x2)
##         end
##     elseif s.x1 > s.x2
##         # return 2nd, move 2nd
##         nx2, ns2 = next(mit.it2, s.s2)
##         return s.x2, MergedState(s.s1, ns2, s.x1, nx2)
##     elseif s.x1 < s.x2
##         # return 1st, move 1st
##         nx1, ns1 = next(mit.it1, s.s1)
##         return s.x1, MergedState(ns1, s.s2, nx1, s.x2)
##     else
##         # elements are equal, return 1st, move both
##         nx1, ns1 = next(mit.it1, s.s1)
##         nx2, ns2 = next(mit.it2, s.s2)
##         return s.x1, MergedState(ns1, ns2, nx1, nx2)
##     end
## end

## function Base.done(mit::MergedIter, s::MergedState)
##     return (done(mit.it1, s.s1) && s.x1 == nothing && 
##             done(mit.it2, s.s2) && s.x2 == nothing)
## end





function main()
    memstore = new_cache()
    @time for i=1:1_000_000
        memstore[rand(UInt8, 10)] = rand(UInt8, 100)
    end
    @time open("/tmp/dump") do dumpf
        createdump(dumpf, memstore)
    end
end
