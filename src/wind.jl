using Gtk.ShortNames, GtkObservables, LibSerialPort

const baudrate = 115200
const id_msg = UInt8[255, 0, 0, 0, 0, 0, 0]

function _identify_arduino(port)
    sp = open(port, baudrate)
    sleep(0.5)
    write(sp, id_msg)
    sleep(0.5)
    id = Int(only(read(sp)))
    close(sp)
    type = id < 128 ? :fans : :leds
    return (; port, type, id)
end
function identify_arduino(port) 
    ntries = 10
    for i in 1:ntries
        try
            return _identify_arduino(port)
        catch ex
            @warn "attempt #$i failed to get fan group ID, $(ntries-i) attempts left"
        end
    end
    return nothing
end

arduinos = identify_arduino.(get_port_list())
ledsi = findfirst(x -> x.type == :leds, arduinos)
fansi = findall(x -> x.type == :fans, arduinos)

leds = arduinos[ledsi]
fans = arduinos[fansi]

win = Window("SkyRoom") |> (bx = Box(:v))
for (port, _, id) in fans
    bxh = Box(:h)
    sp = open(port, baudrate)
    fansid = label(string("Fan group ", id))
    duty = slider(0:254; value=0)
    rpm = label("0 RPM")
    on(duty) do duty
        write(sp, UInt8(duty))
        speed = duty < 15 ? 0 : round(Int, 11500duty/254)
        rpm[] = string(digitsep(speed), " RPM")
    end
    push!(bxh, fansid, duty, rpm)
    push!(bx, bxh)
end
Gtk.showall(win)






# todo:
# test together



#
# using Statistics
# using Gtk.ShortNames, GtkObservables, LibSerialPort
# using DataStructures
# import Humanize.digitsep
#
# const levels = 0:230:11500
#
# function categiroze(x)
#     i = findfirst(>(x), midpoints(levels))
#     isnothing(i) ? levels[end] : levels[i]
# end
# function opensp(sp)
#     if isopen(sp)
#         close(sp)
#         sleep(1)
#     end
#     port = only(get_port_list())
#     baudrate = 115200
#     sp = open(port, baudrate)
#     return sp
# end
# cb = CircularBuffer{Int}(100)
# win = Window("SkyRoom") |> (bx = Box(:h))
# duty = slider(0x00:0x64; value=0)
# on(duty) do duty
#     write(sp, duty)
#     empty!(cb)
# end
# push!(bx, duty)
# rpm = label("0 RPM")
# sp = opensp(sp)
# t = @async while isopen(sp)
#     write(sp, 0x65)
#     sleep(0.01)
#     bytes = read(sp)
#     if length(bytes) == 2
#         y = only(Int.(reinterpret(UInt16, bytes)))
#         expected = 115*duty[]
#         if 0.5expected ≤ y ≤ 1.5expected
#             v = categiroze(y)
#             rpm[] = string(digitsep(v), " RPM")
#         end
#     end
# end
# push!(bx, rpm)
# Gtk.showall(win)
#
#
#
