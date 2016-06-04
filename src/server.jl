
import Base.TCPServer

type PokeServer
    socket::TCPServer
    cache::SortedDict{Vector{UInt8}, Vector{UInt8}}
    cache_size::Int64
    dump_path::UTF8String
end


function startserver(port::Int, dump_path::AbstractString)
    server_socket = listen(port)
    pserv = PokeServer(server_socket, new_cache(), 0, dump_path)
    task = @async begin
        try
            while true
                sock = accept(server_socket)
                serve_conn(pserv, sock)
            end
        catch ex
            if !isa(ex, InterruptException)
                throw(e)
            end
        finally
            close(server_socket)
        end
    end
    return task, pserv  # TODO: return pserv instead
end


function stopserver(server_task::Task)
    Base.throwto(server_task, InterruptException())
end


function serve_conn(poke_server::PokeServer, sock::TCPSocket)
    while true
        req = readobj(sock, PokeRequest)
        println(req)
        for (k, v) in req.data
            cache[k] = v
        end
        # TODO: check if size of cache is large enough to start merge
        write(RequestResponse(req.id, 0, ""))
    end
end


function Base.isless(x::Vector{UInt8}, y::Vector{UInt8})
    return isless(bytestring(x), bytestring(y))
end


function merge()

end

function mergedump(dump_path::AbstractString, cache::Associative)
    if isfile(dump_path)
        # create

    else
        # merge
        dumpf = open(dump_path)
        temp_path, tempf = mktemp()
        try

        finally
            close(dumpf)
            close(tempf)
            rm(tempf)
        end
    end
end

