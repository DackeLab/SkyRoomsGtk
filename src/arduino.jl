const ROOM = Ref{String}()

function safe_open(port, baudrate)
    try
        sp = open(port, baudrate)
        return sp
    catch ex
        return nothing
    end
end

function try_sun(port)
    sp = safe_open(port, baudrate)
    isnothing(sp) && return false
    # @info "found viable port: $port"
    sleep(2)
    msg = UInt8[255, 0, 0, 0, 0, 0, 0]
    for i in 1:5
        flush(sp)
        sleep(0.1)
        write(sp, msg)
        # @info "attempt #$i..."
        if bytesavailable(sp) == 1
            id = only(read(sp))
            # @info "arduino responded"
            if id > 128
                suns_arduino[] = sp # stow this serial port
                cardinalities[] = id == 255 ? ["NE", "SW", "SE", "NW"] : ["SE", "NW", "NE", "SW"] # due to differences in how the strips are wired we have some discrepancies in their cardinality. The first one is Sheldon, the second is Nicolas
                @info "found LEDs arduino in port $port"
                ROOM[] = id == 255 ? "Sheldon" : id == 254 ? "Nicolas" : "unknown"
                return true
            end
        end
    end
    close(sp)
    return false
end

function update_wind(msg::Vector{UInt8}, sp::SerialPort)
    buff = zeros(UInt8, 4)
    for i in 1:5
        write(sp, msg)
        sleep(0.01)
        if bytesavailable(sp) == 4
            read!(sp, buff)
            if buff[1] == 1
                return true
            end
        else
            sp_flush(sp, SP_BUF_BOTH)
            @warn "$i failed attempt/s"
        end
    end
    return false
end

function try_wind(port)
    sp = safe_open(port, baudrate)
    isnothing(sp) && return false
    # @info "found viable port: $port"
    sleep(2)
    msg = UInt8[0, 0, 0, 3]
    if update_wind(msg, sp)
        wind_arduino[] = sp # stow this serial port
        @info "found wind arduino in port $port"
        return true
    end
    close(sp)
    return false
end

function populate_arduinos()
    @suppress_out begin
        ports = reverse(get_port_list())
        tokill = 1
        if !isassigned(suns_arduino)
            for (i, port) in enumerate(ports)
                if try_sun(port)
                    tokill = i
                    continue
                end
            end
        else
            if !isopen(suns_arduino[])
                open(suns_arduino[])
            end
        end
        @assert isassigned(suns_arduino) && isopen(suns_arduino[]) "failed to find the LEDs arduino"
        # deleteat!(ports, tokill)
        if !isassigned(wind_arduino)
            for port in ports
                if try_wind(port)
                    continue
                end
            end
        else
            if !isopen(wind_arduino[])
                open(wind_arduino[])
            end
        end
        if !isassigned(wind_arduino) && ROOM[] == "Nicolas"
            @warn "we are in Nicolas, yet no wind arduino was detected"
        end
    end
end
