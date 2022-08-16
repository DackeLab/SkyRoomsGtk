struct Wind
    id::Int
    duty::Int
end

Wind(id) = Wind(id, 0) # convenience constructor for zero wind
Wind(d::Dict) = Wind(d["id"], d["duty"]) # convenience constructor from a dictionary

# send duty to the correct serial port, checks to see if said port exists
send(w::Wind) = haskey(winds_arduinos[], w.id) && write(winds_arduinos[][w.id], round(UInt8, 254w.duty/100))

# a GUI widget to control one set of fans with ID `id`
function windwidget(id, off)
    title = label(string(id))
    duty = slider(0:100; value=0)
    on(duty) do x
        wind = Wind(id, x)
        send(wind)
    end
    on(off) do _
        duty[] = 0
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

