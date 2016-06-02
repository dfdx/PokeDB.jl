
import Base.TCPServer

type PokeServer
    socket::TCPServer
    cache::SortedDict{Vector{UInt8}, Vector{UInt8}}
    cache_size::Int64
    dump_file::UTF8String
end

new_cache() = SortedDict((Dict{Vector{UInt8}, Vector{UInt8}}()), Base.Forward)

function startserver(port::Int, dump_file::AbstractString)
    task = @async begin
        server_socket = TCPServer()        
        try
            server_socket = listen(port)
            pserv = PokeServer(server_socket, new_cache(), 0, dump_file)
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
    return task  # TODO: return pserv instead
end


function stopserver(server_task::Task)
    Base.throwto(server_task, InterruptException())
end


function serve_conn(poke_server::PokeServer, sock::TCPSocket)
    while true
        req = readobj(sock, PokeRequest)
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
