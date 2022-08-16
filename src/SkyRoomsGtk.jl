module SkyRoomsGtk

using TOML
using Gtk.ShortNames, GtkObservables, LibSerialPort, StaticArrays
import Humanize.digitsep

export gui, from_file

const cardinalities = Ref{Vector{String}}()
const suns_arduino = Ref{SerialPort}()
const winds_arduinos = Ref{Dict{Int, SerialPort}}(Dict{Int, SerialPort}())

const max_suns = 80
const ledsperstrip = 150
const zenith = 71
const baudrate = 115200

include("arduino.jl")
include("wind.jl")
include("sun.jl")


function closeall(win1, off1, ::Nothing, ::Nothing, c)
    signal_connect(win1, :destroy) do widget
        off1[] = off1[]
        close(suns_arduino[])
        notify(c)
    end
end

function closeall(win1, off1, win2, off2, c)
    signal_connect(win1, :destroy) do widget
        off1[] = off1[]
        close(suns_arduino[])
        off2[] = off2[]
        close.(values(winds_arduinos[]))
        Gtk.destroy(win2)
        notify(c)
    end
    signal_connect(win2, :destroy) do widget
        Gtk.destroy(win1)
    end
end

function gui(nsuns::Int = 4)
    @assert nsuns ≤ max_suns "cannot have more than $max_suns suns"
    populate_arduinos()
    win1, off1 = build_suns_gui(nsuns)
    win2, off2 = isempty(winds_arduinos[]) ? (nothing, nothing) : build_winds_gui()
    c = Condition()
    closeall(win1, off1, win2, off2, c)
    @async Gtk.gtk_main()
    wait(c)
end

function find_first_toml_file() 
    home = homedir()
    for file in readdir(home; join=true)
        _, ext = splitext(file)
        if ext == ".toml"
            @info "found $file"
            return file
        end
    end
    error("didn't find any toml files in $home")
end

function from_file(file::String=find_first_toml_file())
    populate_arduinos()
    setups = upload_setups(file)
    n = length(setups)
    wh = ceil(Int, sqrt(n))
    win = Window("SkyRoom") |> (g = Grid())
    chars = Dict{Char, GtkObservables.Observable}()
    for (i, (label, setup)) in enumerate(setups)
        b = button(label)
        on(b) do _
            for _ in 1:3
                send.(setup.suns)
                send.(setup.winds)
                # sleep(0.1)
            end
        end
        chars[setup.key] = observable(b)
        x, y = Tuple(CartesianIndices((wh, wh))[i])
        g[x, y] = b
    end
    signal_connect(win, "key-press-event") do widget, event
        k = Char(event.keyval)
        if haskey(chars, k)
            notify(chars[k])
        end
    end
    Gtk.showall(win)
    c = Condition()
    signal_connect(win, :destroy) do widget
        setup = last(first(setups))
        for _ in 1:3
            send.(setup.suns)
            send.(setup.winds)
            # sleep(0.1)
        end
        close(suns_arduino[])
        close.(values(winds_arduinos[]))
        notify(c)
    end
    @async Gtk.gtk_main()
    wait(c)
end

function verify(file)
    sorted_cardinalities = ["NE", "NW", "SE", "SW"]
    @assert isfile(file) "file $file does not exist"
    d = TOML.tryparsefile(file)
    @assert !isa(d, TOML.ParserError) "bad TOML formatting"
    @assert haskey(d, "setups") """no "setups" field"""
    setups = d["setups"]
    @assert !isempty(setups) "no setups"
    @assert length(setups) ≤ 26 "can't have more than 26 setups in one file"
    foreach(setups) do setup
        @assert haskey(setup, "label") "a setup is missing a label"
        label = setup["label"]
        @assert !isempty(label) "one of the labels is empty/missing"
        @assert setup["label"] isa String "the label in setup $label is not a string"
        @assert any(key -> haskey(setup, key), ("suns", "winds")) "setup $label has neither a suns nor winds section?"
        if haskey(setup, "suns")
            @assert !isempty(setup["suns"]) "suns in setup $label are empty"
            @assert length(setup["suns"]) ≤ max_suns "setup $label has more than $max_suns suns"
            foreach(setup["suns"]) do sun
                foreach(("cardinality", "blue", "radius", "green", "red", "elevation")) do key
                    @assert haskey(sun, key) "the $key field is missing from one of the suns in setup $label"
                end
                @assert sun["cardinality"] ∈ sorted_cardinalities "cardinality in setup $label must be one of these: $sorted_cardinalities"
                @assert 0 ≤ sun["blue"] ≤ 255 "blue in setup $label must be between 0 and 255"
                @assert 0 ≤ sun["radius"] ≤ 255 "radius in setup $label must be between 0 and 255"
                @assert 0 ≤ sun["green"] ≤ 255 "green in setup $label must be between 0 and 255"
                @assert 0 ≤ sun["red"] ≤ 255 "red in setup $label must be between 0 and 255"
                @assert 1 ≤ sun["elevation"] ≤ zenith "elevation in setup $label must be between 1 and $zenith"
            end
        else
            setup["suns"] = Dict{String, Union{String, Int}}[]
        end
        if haskey(setup, "winds")
            @assert !isempty(setup["winds"]) "winds in setup $label are empty"
            @assert length(setup["winds"]) ≤ 5 "setup $label has more than 5 winds"
            foreach(setup["winds"]) do wind
                foreach(("id", "duty")) do key
                    @assert haskey(wind, key) "the $key field is missing from one of the winds in setup $label"
                end
                @assert wind["id"] ∈ 1:5 "wind ID must be one of: 1, 2, 3, 4, or 5"
                @assert 0 ≤ wind["duty"] ≤ 100 "wind duty in setup $label must be between 0 and 100"
            end
        else 
            setup["winds"] = Dict{String, Int}[]
        end
    end 
    @assert allunique([setup["label"] for setup in setups]) "all setups must have a unique label"
    return setups
end

function upload_setups(file)
    setups = verify(file)
    nsuns = maximum(setup -> haskey(setup, "suns") ? length(setup["suns"]) : 0, setups)
    d = Pair[]
    push!(d, "a: Off" => (key = 'a', suns = Sun.(1:nsuns), winds = Wind.(1:5)))
    for (key, setup) in zip('b':'z', setups)
        suns = [Sun(id, sun) for (id, sun) in enumerate(setup["suns"])]
        for id in length(suns) + 1:nsuns
            push!(suns, Sun(id))
        end
        winds = Wind.(setup["winds"])
        ids = (wind.id for wind in winds)
        for id in 1:5
            if id ∉ ids
                push!(winds, Wind(id))
            end
        end
        push!(d, string(key, ": ",setup["label"]) => (; key, suns, winds))
    end
    return d
end

end
