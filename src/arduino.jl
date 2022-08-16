function identify_arduino(port)
    sp = open(port, baudrate)
    sleep(1)
    set_flow_control(sp)
    sleep(1)
    bytes = UInt8[]
    for _ in 1:10
        sleep(0.1)
        write(sp, UInt8[255, 0, 0, 0, 0, 0, 0])
        append!(bytes, read(sp))
        if !isempty(bytes)
            break
        end
    end
    id = Int(only(bytes))
    if id > 128
        suns_arduino[] = sp
        cardinalities[] = id == 255 ? ["NE", "SW", "SE", "NW"] : ["SE", "NW", "NE", "SW"] 
        @info "found LED arduino"
    else
        winds_arduinos[][id] = sp
        @info "found wind $id arduino"
    end
end

function populate_arduinos()
    ntries = 5
    for port in get_port_list()
        for i in 1:ntries
            try
                return identify_arduino(port)
            catch ex
                # @warn "attempt $i of $(ntries - i) failed to connect to arduino"
            end
        end
        identify_arduino(port)
    end
end


