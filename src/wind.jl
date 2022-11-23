function update_wind(id::Int, relay::Bool)
    channel = id + 7
    msg = UInt8[0, relay, channel, 2]
    update_wind(msg, wind_arduino[])
end

function update_wind(id::Int, duty::Int)
    channel = id - 1
    msg = UInt8[0, duty, channel, 1]
    update_wind(msg, wind_arduino[])
end

# send duty to the correct serial port, checks to see if said port exists
function update_wind(d::Dict)
    update_wind(d["id"], d["duty"])
    update_wind(d["id"], d["relay"])
end

# a GUI widget to control one set of fans with ID `id`
function windwidget(id, off)
    title = label(string(id))
    relay = checkbox()
    duty = slider(0:100; value=0)
    on(x -> update_wind(id, round(Int, 2.54x)), duty)
    on(off) do _
        relay[] = false
    end
    on(x -> update_wind(id, x), relay)
    return title, relay, duty
end

# GUI window with all the fans' widgets
function build_winds_gui()
    win = Window("Winds") |> (g = Grid())
    off = button(; label="Off")
    g[1,1:3] = off
    for (i, txt) in enumerate(("Fan", "Relay", "Duty"))
        g[2, i] = label(txt)
    end
    for i in 1:nfans, (j, w) in enumerate(windwidget(i, off))
        g[i + 2, j] = w
    end
    Gtk.showall(win)
    return win, off
end

