
import Base: <, ==, isless

## PokeRecord

"""
Main record type. May also be used as a pair of Key and Value separately
"""
immutable PokeRecord
    key::Key
    value::Value
end

function Base.show(io::IO, rec::PokeRecord)
    print(io, "PokeRecord($(bytestring(rec.key)))")
end

==(rec1::PokeRecord, rec2::PokeRecord) = rec1.key == rec2.key
<(rec1::PokeRecord, rec2::PokeRecord) = rec1.key < rec2.key
isless(rec1::PokeRecord, rec2::PokeRecord) = rec1 < rec2


## PokeIterator


# TODO: move / create FileStore poke iterator
"""Iterator that reads data from IO one by one"""
type PokeIterator
    io::IO
end

function Base.start(pit::PokeIterator)
    return nothing
end

function Base.next(pit::PokeIterator, s::Void)
    return readobj(pit.io, PokeRecord), nothing
end

function Base.done(pit::PokeIterator, s)
    return eof(pit.io)
end


