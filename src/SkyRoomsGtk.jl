module SkyRoomsGtk

using TOML
using Gtk.ShortNames, GtkObservables, LibSerialPort
import Humanize.digitsep

export gui

const ledsperstrip = 150
const zenith = 71
const baudrate = 115200
const id_msg = UInt8[255, 0, 0, 0, 0, 0, 0]

function send(cardinality, elevation, radius, red::UInt8, green::UInt8, blue::UInt8, sunid, sp, cardinalities)
    start, len = start_length(cardinality, elevation, radius, cardinalities)
    bytes = reinterpret(UInt8, UInt16[start])
    write(sp, UInt8(sunid - 1), bytes..., UInt8(len), red, green, blue)
end

function start_length(cardinality, elevation, radius, cardinalities)
    i = findfirst(==(cardinality), cardinalities)
    issecondstrip = i > 2
    issecondhalf = iseven(i)
    center = ledsperstrip*issecondstrip + 2zenith*issecondhalf + (-1)^issecondhalf*elevation
    start = max(1 + ledsperstrip*issecondstrip, center - radius) - 1
    stop = min(2zenith - 1 + ledsperstrip*issecondstrip, center + radius)
    return start, stop - start
end

function sunwidget(id, sp, cardinalities, off)
    title = label(string(id))
    cardinality = dropdown(cardinalities; value=cardinalities[1])
    elevation = slider(1:zenith; value=zenith)
    radius = slider(0:10; value=0)
    red = slider(0x00:0xff; value=0x00)
    green = slider(0x00:0xff; value=0x00)
    blue = slider(0x00:0xff; value=0x00)
    onany(cardinality, elevation, radius, red, green, blue) do x...
        send(x..., id, sp, cardinalities)
    end
    on(off) do _
        red[] = 0x00
        sleep(0.1)
        green[] = 0x00
        sleep(0.1)
        blue[] = 0x00
    end
    return title, cardinality, elevation, radius, red, green, blue
end

function windwidget(fan, off)
    fansid = label(string(fan.id))
    duty = slider(0:254; value=0)
    rpm = label("0")
    on(duty) do duty
        write(fan.sp, UInt8(duty))
        speed = duty < 15 ? 0 : round(Int, 11500duty/254)
        rpm[] = digitsep(speed)
    end
    on(off) do _
        duty[] = 0
    end
    return fansid, duty, rpm
end


function _identify_arduino(port)
    sp = open(port, baudrate)
    # sleep(0)
    set_flow_control(sp)
    sleep(2)
    bytes = UInt8[]
    for _ in 1:10
        write(sp, id_msg)
        append!(bytes, read(sp))
        if !isempty(bytes)
            break
        end
    end
    id = Int(only(bytes))
    type = id < 128 ? :fans : :leds
    return (; sp, type, id)
end

function identify_arduino(port) 
    ntries = 5
    for i in 1:ntries
        try
            return _identify_arduino(port)
        catch ex
            # @warn "attempt $i of $(ntries - i) failed to connect to arduino"
        end
    end
    return nothing
end

function get_arduinos()
    arduinos = identify_arduino.(get_port_list())
    filter!(!isnothing, arduinos)
    ledsi = findfirst(x -> x.type == :leds, arduinos)
    fansi = findall(x -> x.type == :fans, arduinos)
    leds = arduinos[ledsi]
    fans = arduinos[fansi]
    sort!(fans; by=fan -> getfield(fan, :id))
    return leds, fans
end

turnoff(sp, cardinalities) = foreach(1:nsuns) do i
    send("NW", 1, 0, zeros(UInt8, 3)..., i, sp, cardinalities)
end

function build_leds_gui(leds, cardinalities, nsuns)
    win = Window("LEDs") |> (g = Grid())
    off = button("OFF")
    g[1,1:7] = off
    for (i, txt) in enumerate(("Sun", "Cardinality", "Elevation", "radius", "Red", "Green", "Blue"))
        g[2, i] = label(txt)
    end
    for i in 1:nsuns, (j, w) in enumerate(sunwidget(i, leds.sp, cardinalities, off))
        g[i + 2, j] = w
    end
    Gtk.showall(win)
    return win, off
end

function build_fans_gui(fans)
    win = Window("Fans") |> (g = Grid())
    off = button("OFF")
    g[1,1:3] = off
    for (i, txt) in enumerate(("Fan", "Duty", "RPM"))
        g[2, i] = label(txt)
    end
    for (i, fan) in enumerate(fans), (j, w) in enumerate(windwidget(fan, off))
        g[i + 2, j] = w
    end
    Gtk.showall(win)
    return win, off
end

function closeall(leds, _, win1, off1, ::Nothing, ::Nothing, c)
    signal_connect(win1, :destroy) do widget
        off1[] = off1[]
        close(leds.sp)
        notify(c)
    end
end

function closeall(leds, fans, win1, off1, win2, off2, c)
    signal_connect(win1, :destroy) do widget
        off1[] = off1[]
        close(leds.sp)
        off2[] = off2[]
        for fan in fans
            close(fan.sp)
        end
        Gtk.destroy(win2)
        notify(c)
    end
    signal_connect(win2, :destroy) do widget
        Gtk.destroy(win1)
    end
end

function gui(nsuns::Int = 4)
    @assert nsuns ≤ 80 "cannot have more than 80 suns"
    leds, fans = get_arduinos()
    cardinalities = leds.id == 255 ? ["NE", "SW", "SE", "NW"] : ["SE", "NW", "NE", "SW"] 
    win1, off1 = build_leds_gui(leds, cardinalities, nsuns)
    win2, off2 = isempty(fans) ? (nothing, nothing) : build_fans_gui(fans)
    c = Condition()
    closeall(leds, fans, win1, off1, win2, off2, c)
    @async Gtk.gtk_main()
    wait(c)
end









# function upload_setups(file, cardinalities)
#     @assert isfile(file) "file $file does not exist"
#
#     d = TOML.tryparsefile(file)
#
#     @assert !isa(d, TOML.ParserError) "bad TOML formatting"
#
#     @assert haskey(d, "setups") """no "setups" field"""
#
#     setups = d["setups"]
#
#     @assert !isempty(setups) "no setups"
#
#     foreach(setups) do setup
#         foreach(("label", "suns")) do key
#             @assert haskey(setup, key) "a setup is missing a $key field"
#             @assert !isempty(setup[key]) "the $key field in setup $(setup["label"]) is empty"
#         end
#         label = setup["label"]
#         @assert setup["label"] isa String "the label in setup $label is not a string"
#         @assert !isempty(setup["suns"]) "suns in setup $label are empty"
#         @assert length(setup["suns"]) ≤ nsuns "setup $label has more than $nsuns suns"
#         foreach(setup["suns"]) do sun
#             foreach(("cardinality", "blue", "radius", "green", "red", "elevation")) do key
#                 @assert haskey(sun, key) "the $key field is missing from one of the suns in setup $label"
#             end
#             @assert sun["cardinality"] ∈ cardinalities "cardinality in setup $label must be one of these: $cardinalities"
#             @assert 0 ≤ sun["blue"] ≤ 255 "blue in setup $label must be between 0 and 255"
#             @assert 0 ≤ sun["radius"] ≤ 255 "radius in setup $label must be between 0 and 255"
#             @assert 0 ≤ sun["green"] ≤ 255 "green in setup $label must be between 0 and 255"
#             @assert 0 ≤ sun["red"] ≤ 255 "red in setup $label must be between 0 and 255"
#             @assert 1 ≤ sun["elevation"] ≤ 71 "elevation in setup $label must be between 0 and 255"
#         end
#     end 
#
#     return d["setups"]
# end
#
#
# function get_window(sp, file::String, cardinalities)
#     win = Window("SkyRoom") |> (g = Grid())
#     setups = upload_setups(file, cardinalities)
#     n = length(setups)
#     wh = ceil(Int, sqrt(n))
#     for (i, setup) in enumerate(setups)
#         b = button(setup["label"])
#         on(b) do _
#             turnoff(sp, cardinalities)
#             for (sunid, sun) in enumerate(setup["suns"])
#                 send(sun["cardinality"], sun["elevation"], sun["radius"], UInt8(sun["red"]), UInt8(sun["green"]), UInt8(sun["blue"]), sunid, sp, cardinalities)
#             end
#         end
#         x, y = Tuple(CartesianIndices((wh, wh))[i])
#         g[x, y] = b
#     end
#     return win
# end
#
# sheldon(; file = missing) = main(["NE", "SW", "SE", "NW"]; file)
# nicolas(; file = missing) = main(["SE", "NW", "NE", "SW"]; file)

end
