using PokeDB
using Base.Test

# mergesorted
it1 = mergesorted(1:10, 5:15)
@assert collect(it1) == [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]

it2 = mergesorted(5:15, 1:10)
@assert collect(it2) == [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]

it3 = mergesorted([:a, :c, :d, :f], [:b, :c, :d, :e])
@assert collect(it3) == [:a, :b, :c, :d, :e, :f]

it4 = mergesorted([], ["aaa", "bbb", "ccc"])
@assert collect(it4) == ["aaa", "bbb", "ccc"]

it5 = mergesorted(["aaa", "bbb", "ccc"], [])
@assert collect(it5) == ["aaa", "bbb", "ccc"]

it6 = mergesorted([], [])
@assert collect(it6) == []
