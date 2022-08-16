struct Sun
    id::Int
    cardinality::String
    elevation::Int
    radius::Int
    red::Int
    green::Int
    blue::Int
end
Sun(id) = Sun(id, cardinalities[][1], 1, 0, 0, 0, 0)
Sun(id, d::Dict) = Sun(id, d["cardinality"], d["elevation"], d["radius"], d["red"], d["green"], d["blue"])

function sun2msg(s::Sun)
    start, length = start_length(s.cardinality, s.elevation, s.radius)
    start1, start2 = reinterpret(UInt8, UInt16[start])
    SVector{7, UInt8}(s.id, start1, start2, length, s.red, s.green, s.blue)
end

function start_length(cardinality, elevation, radius)
    i = findfirst(==(cardinality), cardinalities[])
    issecondstrip = i > 2
    issecondhalf = iseven(i)
    center = ledsperstrip*issecondstrip + 2zenith*issecondhalf + (-1)^issecondhalf*elevation
    start = max(1 + ledsperstrip*issecondstrip, center - radius) - 1
    stop = min(2zenith - 1 + ledsperstrip*issecondstrip, center + radius)
    len = stop - start
    return start, len
end

send(s::Sun) = write(suns_arduino[], sun2msg(s))

function sunwidget(id, off)
    title = label(string(id))
    cardinality = dropdown(cardinalities[]; value=cardinalities[][1])
    elevation = slider(1:zenith; value=zenith)
    radius = slider(0:10; value=0)
    red = slider(0:255; value=0)
    green = slider(0:255; value=0)
    blue = slider(0:255; value=0)
    onany(cardinality, elevation, radius, red, green, blue) do x...
        sun = Sun(id, x...)
        send(sun)
    end
    on(off) do _
        send(Sun(id))
    end
    return title, cardinality, elevation, radius, red, green, blue
end

function build_suns_gui(nsuns)
    win = Window("Suns") |> (g = Grid())
    off = button("Off")
    g[1,1:7] = off
    for (i, txt) in enumerate(("Sun", "Cardinality", "Elevation", "radius", "Red", "Green", "Blue"))
        g[2, i] = label(txt)
    end
    for i in 1:nsuns, (j, w) in enumerate(sunwidget(i, off))
        g[i + 2, j] = w
    end
    Gtk.showall(win)
    return win, off
end
