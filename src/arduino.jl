# try to identify if a port is connected to an Arduino, and if so, which one is it
function identify_arduino(port)
    sp = open(port, baudrate)
    sleep(1)
    set_flow_control(sp) # necessary for macs
    sleep(1)
    bytes = UInt8[]
    for _ in 1:10 # 10 attempts because communication is very brittle
        sleep(0.1)
        write(sp, UInt8[255, 0, 0, 0, 0, 0, 0]) # 255 signals to the arduino that we want its ID
        append!(bytes, read(sp))
        if !isempty(bytes) # ah! We got a response
            break 
        end
    end
    id = Int(only(bytes))
    if id > 128 # LED strips have high ID numbers
        suns_arduino[] = sp # stow this serial port
        cardinalities[] = id == 255 ? ["NE", "SW", "SE", "NW"] : ["SE", "NW", "NE", "SW"] # due to differences in how the strips are wired we have some discrepancies in their cardinality. The first one is Sheldon, the second is Nicolas
        @info "found LED arduino"
    else
        winds_arduinos[][id] = sp # stow the fans' serial port
        @info "found wind $id arduino"
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
        end
    end
    @assert isassigned(suns_arduino) "failed to find the LEDs arduino"

end


