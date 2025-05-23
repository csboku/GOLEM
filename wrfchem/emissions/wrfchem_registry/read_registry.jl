using DelimitedFiles,CSV

setwd(@__DIR__)

emiss_opt = readdlm("./emiss_opt")

emiss_opt[:,2] |> unique |> println

mech_nr = size(emiss_opt)[1]

emiss_opt[1,2]

emiss_opt[3,5]




for i in 1:mech_nr
    CSV.write("$(emiss_opt[i,2]).csv",split(emiss_opt[i,5],",")[2:end])
end


