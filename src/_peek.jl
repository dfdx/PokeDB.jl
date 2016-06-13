
import Base: eltype, iteratorsize, iteratoreltype, start, next, done, SizeUnknown, length, size, show


## immutable PeekIter{I}
##     it::I
## end

## peekiter(itr) = PeekIter(itr)

## eltype{I}(::Type{PeekIter{I}}) = eltype(I)
## iteratorsize{I}(::Type{PeekIter{I}}) = iteratorsize(I)
## iteratoreltype{I}(::Type{PeekIter{I}}) = iteratoreltype(I)
## length(f::PeekIter) = length(f.it)
## size(f::PeekIter) = size(f.it)

## function start{I}(f::PeekIter{I})
##     s = start(f.it)
##     E = eltype(I)
##     if done(f.it, s)
##         val = Nullable{E}()
##     else
##         el, s = next(f.it, s)
##         val = Nullable{E}(el)
##     end
##     return s, val, done(f.it, s)
## end

## function next(f::PeekIter, state)
##     s, val, last = state
##     last && return get(val), (s, val, true)
##     el, s = next(f.it, s)
##     return get(val), (s, Nullable(el), done(f.it, s))
## end

## @inline function done(f::PeekIter, state)
##     s, el, last = state
##     return done(f.it, s) && last
## end

## peek{I}(f::PeekIter{I}, state) = state[3] ? Nullable{eltype(I)}() : Nullable{eltype(I)}(state[2])


## using Base.Test

## function test()
##     @test [x for x in peekiter(1:10)] == collect(1:10)
##     @test [x for x in peekiter([])] == collect([])

##     it = peekiter(1:10)
##     s = start(it)
##     @test get(peek(it, s)) == 1

##     it = peekiter([])
##     s = start(it)
##     @test isnull(peek(it, s))
## end






## type MergedIter
##     it1::PeekIter   # iterator 1
##     it2::PeekIter   # iterator 2
##     lt::Function    # custom `<` operator to compare elements of 2 iterators
## end

## type MergedState
##     s1::Tuple
##     s2::Tuple
## end

## function start(it::MergedIter)
##     s1 = start(it.it1)
##     s2 = start(it.it2)
##     return MergedState(s1, s2)
## end


using Iterators
import Iterators: PeekIter, peek


type MergeIter{T}
    iterators::Vector{PeekIter}
    lt::Function
end

function show{T}(io::IO, merged::MergeIter{T})
    print(io, "MergeIter{$T}($(length(merged.iterators)))")
end

length(it::MergeIter) = sum(map(iteratorsize, it.iterators))
size(it::MergeIter) = (length(it),)

function start(merged::MergeIter)
    states = Array(Tuple, length(merged.iterators))
    for i in eachindex(merged.iterators)
        states[i] = start(merged.iterators[i])
    end
    return states
end

function smaller_iter_state(merged::MergeIter, states::Vector{Tuple},
                            i::Int, j::Int)    
    lt = merged.lt
    hd1 = get(peek(merged.iterators[i], states[i]))
    hd2 = get(peek(merged.iterators[j], states[j]))
    return lt(hd1, hd2) ? i : j
end

function move_iterators{T}(merged::MergeIter{T}, states::Vector{Tuple}, hd::T)
    iters = merged.iterators
    new_states = copy(states)
    for i in eachindex(states)
        while (!done(iters[i], new_states[i]) &&
               get(peek(iters[i], new_states[i])) == hd)
            _, new_states[i] = next(iters[i], new_states[i])
        end
    end
    return new_states
end

function next{T}(merged::MergeIter{T}, states::Vector{Tuple})
    active_idxs::Vector{Int} = filter(i -> !done(merged.iterators[i], states[i]),
                                      1:length(merged.iterators))
    @assert length(active_idxs) != 0
    min_idx::Int = reduce((i, j) -> smaller_iter_state(merged, states, i, j),
                          active_idxs)
    min_it = merged.iterators[min_idx]
    min_s = states[min_idx]
    hd::T = convert(T, get(peek(min_it, min_s)))
    new_states = move_iterators(merged, states, hd)
    return hd, new_states
end

function done(merged::MergeIter, states::Vector{Tuple})
    return all([done(it, s) for (it, s) in zip(merged.iterators, states)])
end

function peek{T}(merged::MergeIter{T}, states::Vector{Tuple})
    active_idxs::Vector{Int} = filter(i -> !done(merged.iterators[i], states[i]),
                                      1:length(merged.iterators))
    if length(active_idxs) != 0
        min_idx::Int = reduce((i, j) -> smaller_iter_state(merged, states, i, j),
                              active_idxs)
        min_it = merged.iterators[min_idx]
        min_s = states[min_idx]
        hd::T = convert(T, get(peek(min_it, min_s)))
        return Nullable{T}(hd)
    else
        return Nullable{T}()
    end
end


"""
Merge sorted iterators. Comparison is done using `lt` option that
defaults to `isless` function.
"""
function mergesorted(iterators...; lt = isless)
    T = promote_type(map(eltype, iterators)...)
    peek_iterators = [PeekIter(it) for it in iterators]    
    return MergeIter{T}(peek_iterators, lt)
end
