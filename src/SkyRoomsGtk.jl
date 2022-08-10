module SkyRoomsGtk

using TOML
using Gtk.ShortNames, GtkObservables, LibSerialPort

export main

const nsuns = 4
const ledsperstrip = 150
const zenith = 71
const cardinalities = ["NE", "SW", "SE", "NW"]
const baudrate = 115200

good_port(port) = try
    sp = open(port, baudrate)
    # sleep(0.1)
    good = true#occursin(r"arduino"i, LibSerialPort.sp_get_port_usb_manufacturer(sp))
    close(sp)
    return good
catch ex
    return false
end

function get_port()
    ports = get_port_list()
    i = findfirst(good_port, ports)
    isnothing(i) && throw("No LED strip found, did you forget to plug it in?")
    ports[i]
end


function send(cardinality, elevation, radius, red::UInt8, green::UInt8, blue::UInt8, sunid, sp)
    start, len = start_length(cardinality, elevation, radius)
    bytes = reinterpret(UInt8, UInt16[start])
    write(sp, UInt8(sunid - 1), bytes..., UInt8(len), red, green, blue)
end

function start_length(cardinality, elevation, radius)
    i = findfirst(==(cardinality), cardinalities)
    issecondstrip = i > 2
    issecondhalf = iseven(i)
    center = ledsperstrip*issecondstrip + 2zenith*issecondhalf + (-1)^issecondhalf*elevation
    start = max(1 + ledsperstrip*issecondstrip, center - radius) - 1
    stop = min(2zenith - 1 + ledsperstrip*issecondstrip, center + radius)
    return start, stop - start
end

function sunwidget(id, sp)
    title = label(string(id))
    cardinality = dropdown(cardinalities; value=cardinalities[1])
    elevation = slider(1:zenith; value=zenith)
    radius = slider(0:10; value=0)
    red = slider(0x00:0xff; value=0x00)
    green = slider(0x00:0xff; value=0x00)
    blue = slider(0x00:0xff; value=0x00)
    onany(cardinality, elevation, radius, red, green, blue) do x...
        send(x..., id, sp)
    end
    return title, cardinality, elevation, radius, red, green, blue
end


function get_window(sp, ::Missing)
    win = Window("SkyRoom") |> (g = Grid())
    for (i, txt) in enumerate(("Sun", "Cardinality", "Elevation", "radius", "Red", "Green", "Blue"))
        g[1, i] = label(txt)
    end
    for i in 1:nsuns, (j, w) in enumerate(sunwidget(i, sp))
        g[i + 1, j] = w
    end
    return win
end

function upload_setups(file)
    @assert isfile(file) "file $file does not exist"

    d = TOML.tryparsefile(file)

    @assert !isa(d, TOML.ParserError) "bad TOML formatting"

    @assert haskey(d, "setups") """no "setups" field"""

    setups = d["setups"]

    @assert !isempty(setups) "no setups"

    foreach(setups) do setup
        foreach(("label", "suns")) do key
            @assert haskey(setup, key) "a setup is missing a $key field"
            @assert !isempty(setup[key]) "the $key field in setup $(setup["label"]) is empty"
        end
        label = setup["label"]
        @assert setup["label"] isa String "the label in setup $label is not a string"
        @assert !isempty(setup["suns"]) "suns in setup $label are empty"
        @assert length(setup["suns"]) ≤ nsuns "setup $label has more than $nsuns suns"
        foreach(setup["suns"]) do sun
            foreach(("cardinality", "blue", "radius", "green", "red", "elevation")) do key
                @assert haskey(sun, key) "the $key field is missing from one of the suns in setup $label"
            end
            @assert sun["cardinality"] ∈ cardinalities "cardinality in setup $label must be one of these: $cardinalities"
            @assert 0 ≤ sun["blue"] ≤ 255 "blue in setup $label must be between 0 and 255"
            @assert 0 ≤ sun["radius"] ≤ 255 "radius in setup $label must be between 0 and 255"
            @assert 0 ≤ sun["green"] ≤ 255 "green in setup $label must be between 0 and 255"
            @assert 0 ≤ sun["red"] ≤ 255 "red in setup $label must be between 0 and 255"
            @assert 1 ≤ sun["elevation"] ≤ 71 "elevation in setup $label must be between 0 and 255"
        end
    end 

    return d["setups"]
end

turnoff(sp) = foreach(1:nsuns) do i
    send(cardinalities[1], 1, 0, zeros(UInt8, 3)..., i, sp)
end

function get_window(sp, file::String)
    win = Window("SkyRoom") |> (g = Grid())
    setups = upload_setups(file)
    n = length(setups)
    wh = ceil(Int, sqrt(n))
    for (i, setup) in enumerate(setups)
        b = button(setup["label"])
        on(b) do _
            turnoff(sp)
            for (sunid, sun) in enumerate(setup["suns"])
                send(sun["cardinality"], sun["elevation"], sun["radius"], UInt8(sun["red"]), UInt8(sun["green"]), UInt8(sun["blue"]), sunid, sp)
            end
        end
        x, y = Tuple(CartesianIndices((wh, wh))[i])
        g[x, y] = b
    end
    return win
end

function main(; file::Union{Missing, String} = missing)
    port = get_port()
    sp = open(port, baudrate)
    win = get_window(sp, file)
    Gtk.showall(win)
    c = Condition()
    signal_connect(win, :destroy) do widget
        close(sp)
        notify(c)
    end
    @async Gtk.gtk_main()
    wait(c)
end

end
