
type MergedIter
    it1
    it2
end

type MergedState
    hd1   # current head of 1st iterator
    hd2   # current head of 2nd iterator
    s1    # current state of 1st iterator
    s2    # current state of 2nd iterator
    # ns1   # next state of 1st iterator
    # ns2   # next state of 2nd iterator
end


function Base.start(it::MergedIter)
    # assuming both iterations have at least 1 element
    s1 = start(it.it1)
    s2 = start(it.it2)
    # doing 1 step ahead and caching next element of each iter
    hd1, s1 = next(it.it1, s1)
    hd2, s2 = next(it.it2, s2)
    return MergedState(hd1, hd2, s1, s2)
end

function safenext(it, s)
    if done(it, s)
        return nothing, s
    else
        return next(it, s)
    end
end
    
function Base.next(it::MergedIter, s::MergedState)
    if done(it, s) throw(ArgumentError("Iterator is done")) end
    it1 = it.it1; it2 = it.it2; hd1 = s.hd1; hd2 = s.hd2; s1 = s.s1; s2 = s.s2
    while hd1 == hd2 && !done(it2, s2)
        # move second iterator till heads are different or iterator is done
        hd2, s2 = next(it2, s2)
    end
    if done(it1, s1)
        # 1st iterator is done, but we have one save value in hd1
        # TODO: hd2 == nothing
        if hd1 == nothing || hd1 > hd2
            next_hd2, next_s2 = safenext(it2, s2)
            return hd2, MergedState(hd1, next_hd2, s1, next_s2)
        else  # hd1 cached and hd1 < hd2 
            return hd1, MergedState(nothing, hd2, s1, s2)
        end
    elseif done(it2, s2)
        # 2st iterator is done, but we have one save value in hd2
        if hd2 == nothing || hd2 > hd1
            next_hd1, next_s1 = safenext(it1, s1)
            return hd1, MergedState(next_hd1, hd2, next_s1, s2)
        else  # hd2 cached and hd2 < hd1
            return hd2, MergedState(hd1, nothing, s1, s2)
        end
    elseif hd1 < hd2
        next_hd1, next_s1 = safenext(it1, s1)
        return hd1, MergedState(next_hd1, hd2, next_s1, s2)        
    else
        next_hd2, next_s2 = safenext(it2, s2)
        return hd2, MergedState(hd1, next_hd2, s1, next_s2)
    end
end


function Base.done(it::MergedIter, s::MergedState)
    return (done(it.it1, s.s1) && done(it.it2, s.s2) &&
            s.hd1 == nothing && s.hd2 == nothing)
end



function main()
    it = MergedIter(5:15, 1:10)
    s = start(it)
    x, s = next(it, s)
    collect(it)
end
