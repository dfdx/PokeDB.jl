
type MergedIter
    it1   # iterator 1
    it2   # iterator 2
    lt    # custom `<` operator to compare elements of 2 iterators
    MergeIter(it1, it2) = new(it1, it2, lt)
end

type MergedState
    hd1   # current head of 1st iterator
    hd2   # current head of 2nd iterator
    s1    # current state of 1st iterator
    s2    # current state of 2nd iterator
end


function Base.start(it::MergedIter)
    s1 = start(it.it1)
    s2 = start(it.it2)
    # doing 1 step ahead and caching next element of each iter
    hd1, s1 = safenext(it.it1, s1)
    hd2, s2 = safenext(it.it2, s2)
    return MergedState(hd1, hd2, s1, s2)
end

"""
Like `next`, but may be called on iterator that is already done. In this case
new item is `nothing` and new state is the same as previous. 
"""
function safenext(it, s)
    if done(it, s)
        return nothing, s
    else
        return next(it, s)
    end
end

function Base.next(it::MergedIter, s::MergedState)
    lt = it.lt
    if done(it, s) throw(ArgumentError("Iterator is done")) end
    it1 = it.it1; it2 = it.it2; hd1 = s.hd1; hd2 = s.hd2; s1 = s.s1; s2 = s.s2
    while hd1 == hd2 && hd2 != nothing
        # move second iterator till heads are different or iterator is done
        hd2, s2 = safenext(it2, s2)
    end
    if complete(it1, s1, hd1)
        # 1st iterator is done, but we have one save value in hd1    
        if hd1 == nothing || lt(hd2, hd1) # hd1 > hd2
            next_hd2, next_s2 = safenext(it2, s2)
            return hd2, MergedState(hd1, next_hd2, s1, next_s2)
        else  # hd1 cached and hd1 < hd2 
            return hd1, MergedState(nothing, hd2, s1, s2)
        end
    elseif complete(it2, s2, hd2)
        # 2st iterator is done, but we have one save value in hd2
        if hd2 == nothing || lt(hd1, hd2) # hd2 > hd1
            next_hd1, next_s1 = safenext(it1, s1)
            return hd1, MergedState(next_hd1, hd2, next_s1, s2)
        else  # hd2 cached and hd2 < hd1
            return hd2, MergedState(hd1, nothing, s1, s2)
        end
    elseif lt(hd1, hd2) # hd1 < hd2
        next_hd1, next_s1 = safenext(it1, s1)
        return hd1, MergedState(next_hd1, hd2, next_s1, s2)        
    else
        next_hd2, next_s2 = safenext(it2, s2)
        return hd2, MergedState(hd1, next_hd2, s1, next_s2)
    end
end

"""
Check if iterator is done and no head doesn't contain a cached value.
"""
function complete(it, s, hd)
    return done(it, s) && hd == nothing
end

function Base.done(it::MergedIter, s::MergedState)
    return (done(it.it1, s.s1) && done(it.it2, s.s2) &&
            s.hd1 == nothing && s.hd2 == nothing)
end

"""
Merge 2 sorted iterators. Let `hd1` be a head of 1st iterator and `hd2` -
a head of 2nd iterator. Then merged iterator works as follows: 

 * if hd1 < hd2, hd1 is emitted
 * if hd1 > hd2, hd2 is emitted
 * if hd1 == hd2, hd1 is emitted and hd2 is discarded (so no duplicates
                  is produced)
 * if one of iterators is done, tail of another is taken

Comparison is done using `lt` option that defaults to `isless` function. 
"""
function mergesorted(it1, it2; lt = isless)
    return MergedIter(it1, it2, lt)
end

