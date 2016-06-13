
using Iterators
import Iterators: PeekIter
import Base: start, next, done

immutable UniqueIter
    inner::PeekIter
    UniqueIter(inner::PeekIter) = new(inner)
    UniqueIter(inner) = new(PeekIter(inner))
end

# TODO: eltype, iteratorsize, length, size

function start(it::UniqueIter)
    return start(it.inner)
end

function next(it::UniqueIter, s)
    hd, s = next(it.inner, s)
    while !done(it.inner, s) && hd == get(peek(it.inner, s)) 
        hd, s = next(it.inner, s)
    end
    return hd, s
end

function done(it::UniqueIter, s)
    return done(it.inner, s)
end

function unique(it)
    UniqueIter(it)
end
