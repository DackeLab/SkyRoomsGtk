function is_sun(sp)
    msg = UInt8[255, 0, 0, 0, 0, 0, 0]
    for i in 1:5
        write(sp, msg)
        sleep(0.1)
        if bytesavailable(sp) == 1
            b = first(read(sp))
            if b > 128
                return true
            end
        else
            read(sp)
        end
    end
    return false
end

function get_sun_id(sp)
    msg = UInt8[255, 0, 0, 0, 0, 0, 0]
    for i in 1:5
        write(sp, msg)
        sleep(0.1)
        if bytesavailable(sp) == 1
            b = first(read(sp))
            return b
        else
            read(sp)
        end
    end
end

function is_wind(sp)
    msg = UInt8[0,0,0,3]
    buff = zeros(UInt8, 4)
    for i in 1:5
        write(sp, msg)
        sleep(0.1)
        if bytesavailable(sp) == 4
            read!(sp, buff)
            if buff[1] == 1
                return true
            end
        else
            read(sp)
        end
    end
    return false
end

# try to identify if a port is connected to an Arduino, and if so, which one is it
function identify_arduino(port)
    sp = open(port, baudrate)
    sleep(0.1)
    # set_flow_control(sp; rts=SP_RTS_ON, dtr=SP_DTR_ON) # necessary for macs
    # sleep(0.1)
    if is_sun(sp)
        suns_arduino[] = sp # stow this serial port
        id = get_sun_id(sp)
        cardinalities[] = id == 255 ? ["NE", "SW", "SE", "NW"] : ["SE", "NW", "NE", "SW"] # due to differences in how the strips are wired we have some discrepancies in their cardinality. The first one is Sheldon, the second is Nicolas
        @info "found LED arduino"
    elseif is_wind(sp)
        wind_arduino[] = sp # stow the fan's serial port
        @info "found wind arduino"
    else
        @info "found another serial port"
    end
end

function populate_arduinos()
    ntries = 5
    for port in get_port_list()
        for i in 1:ntries
            try # when opening "bad" ports (blue tooth modules etc) this will error, so  wrapped it in a try/catch thing
                identify_arduino(port)
                break
            catch ex
                # @warn "attempt $i of $(ntries - i) failed to connect to arduino"
            end
            sleep(0.1)
        end
    end
    @assert isassigned(suns_arduino) "failed to find the LEDs arduino"
end


