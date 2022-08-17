using DataFrames, PrettyTables

zenith = 71
leds = 1:zenith
elevations(led) = 90(led - 1)/(zenith - 1)

df = DataFrame(LED = leds, Elevation = string.(round.(elevations.(leds), digits=2), "°"))
open("elevations.md", "w") do io
    pretty_table(io, df; nosubheader=true)
end

duties = 0:100
rpm(duty) = 11500duty/100

df = DataFrame(Duty = duties, RPM = string.(round.(Int, rpm.(duties)), " rpm"))
open("rpms.md", "w") do io
    pretty_table(io, df; nosubheader=true)
end
