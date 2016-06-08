
import Base: eltype, iteratorsize, iteratoreltype, start, next, done, SizeUnknown, length, size


immutable PeekIter{I}
    it::I
end

peekiter(itr) = PeekIter(itr)

eltype{I}(::Type{PeekIter{I}}) = eltype(I)
iteratorsize{I}(::Type{PeekIter{I}}) = iteratorsize(I)
iteratoreltype{I}(::Type{PeekIter{I}}) = iteratoreltype(I)
length(f::PeekIter) = length(f.it)
size(f::PeekIter) = size(f.it)

function start{I}(f::PeekIter{I})
    s = start(f.it)
    E = eltype(I)
    if done(f.it, s)
        val = Nullable{E}()
    else
        el, s = next(f.it, s)
        val = Nullable{E}(el)
    end
    return s, val, done(f.it, s)
end

function next(f::PeekIter, state)
    s, val, last = state
    last && return get(val), (s, val, true)
    el, s = next(f.it, s)
    return get(val), (s, Nullable(el), done(f.it, s))
end

@inline function done(f::PeekIter, state)
    s, el, last = state
    return done(f.it, s) && last
end

peek{I}(f::PeekIter{I}, state) = state[3] ? Nullable{eltype(I)}() : Nullable{eltype(I)}(state[2])


using Base.Test

function test()
    @test [x for x in peekiter(1:10)] == collect(1:10)
    @test [x for x in peekiter([])] == collect([])

    it = peekiter(1:10)
    s = start(it)
    @test get(peek(it, s)) == 1

    it = peekiter([])
    s = start(it)
    @test isnull(peek(it, s))
end






type MergedIter
    it1::PeekIter   # iterator 1
    it2::PeekIter   # iterator 2
    lt::Function    # custom `<` operator to compare elements of 2 iterators
end

type MergedState
    s1::Tuple
    s2::Tuple
end


function start(it::MergedIter)
    s1 = start(it.it1)
    s2 = start(it.it2)
    return MergedState(s1, s2)
end

function next(it::MergedIter, s::MergedState)
    lt = it.lt
    it1 = it.it1; it2 = it.it2; s1 = s.s1; s2 = s.s2
    while (!done(it1, s1) && !done(it2, s2) &&
           get(peek(it1, s1)) == get(peek(it2, s2)))
        # move second iterator till heads are different or iterator is done
        _, s2 = next(it2, s2)
    end
    hd1 = peek(it1, s1); hd2 = peek(it2, s2)
    if done(it1, s1) && done(it2, s2)
        throw(InvalidStateException("Calling next on iterator that id done"))
    elseif done(it1, s1)        
        _, next_s2 = next(it2, s2)
        return get(hd2), MergedState(s1, next_s2)
    elseif done(it2, s2)
        _, next_s1 = next(it1, s1)
        return get(hd1), MergedState(next_s1, s2)
    elseif lt(get(hd1), get(hd2))  # hd1 < hd2
        _, next_s1 = next(it1, s1)
        return get(hd1), MergedState(next_s1, s2)
    else # hd2 < hd1
        _, next_s2 = next(it2, s2)
        return get(hd2), MergedState(s1, next_s2)
    end
end

function done(it::MergedIter, s::MergedState)
    return done(it.it1, s.s1) && done(it.it2, s.s2)
end

"""
Merge 2 sorted iterators. Let `hd1` be a head of 1st iterator and `hd2` -
a head of 2nd iterator. Then merged iterator works as follows:

 * if hd1 < hd2, hd1 is emitted
 * if hd1 > hd2, hd2 is emitted
 * if hd1 == hd2, hd1 is emitted and hd2 is discarded (so no duplicates
                  are produced)
 * if one of iterators is done, tail of another is taken

Comparison is done using `lt` option that defaults to `isless` function.
"""
function mergesorted(it1, it2; lt = isless)
    return MergedIter(PeekIter(it1), PeekIter(it2), lt)
end
