struct Wind
    id::Int
    relay::Bool
    duty::Int
end

Wind(id) = Wind(id, false, 0) # convenience constructor for zero wind
Wind(d::Dict) = Wind(d["id"], false, d["duty"]) # convenience constructor from a dictionary

function set_relay(id, relay)
    channel = id + 7
    msg = UInt8[0, relay, channel, 2]
    send(msg)
end

function set_speed(id, duty)
    channel = id - 1
    msg = UInt8[0, duty, channel, 1]
    send(msg)
end

function send(msg, sp, nbytes)
    buff = zeros(UInt8, nbytes)
    for i in 1:10
        write(sp, msg)
        sleep(0.1)
        if bytesavailable(sp) == nbytes
            read!(sp, buff)
            if buff[1] == 1
                return buff
            end
        else
            read(wind_arduino[])
        end
        @info "attempted $i times..."
    end
    @error SystemError "failed to send data to the arduino!"
end

# send duty to the correct serial port, checks to see if said port exists
function send(w::Wind)
    set_speed(w.id, w.duty, wind_arduino[])
    set_relay(w.id, w.relay, wind_arduino[])
end

# a GUI widget to control one set of fans with ID `id`
function windwidget(id, off)
    title = label(string(id))
    duty = slider(0:255; value=0)
    on(duty) do x
        set_speed(id, x)
    end
    on(off) do relay
        set_relay(id, relay)
    end
    return title, duty
end

# GUI window with all the fans' widgets
function build_winds_gui()
    win = Window("Winds") |> (g = Grid())
    off = button("OFF")
    g[1,1:3] = off
    for (i, txt) in enumerate(("Fan", "Duty", "RPM"))
        g[2, i] = label(txt)
    end
    for i in sort(collect(keys(winds_arduinos[]))), (j, w) in enumerate(windwidget(i, off))
        g[i + 2, j] = w
    end
    Gtk.showall(win)
    return win, off
end

