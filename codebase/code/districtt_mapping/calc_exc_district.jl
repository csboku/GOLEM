using DelimitedFiles,CSV,Plots,Statistics,DataFrames

datadir = "/home/cschmidt/data/attain/district_mapped/mda8/"

inp_files = readdir(datadir)
inp_f = readdir(datadir,join=true)

outputdir = "/home/cschmidt/data/attain/district_mapped/exc/"

csv_f = CSV.File(inp_f[1])

csv_f.names
csv_f.Date

csv_in = readdlm(inp_f[1],',')[2:end,2:end]


csv_in[csv_in .< 120] .= 0
csv_in[csv_in .> 120] .= 1

csv_out = DataFrame(csv_in,:auto)
insertcols!(csv_out,1,:Date => csv_f.Date)   
rename!(csv_out,csv_f.names)




for i in eachindex(inp_f)
    csv_f = CSV.File(inp_f[i])
    csv_f.names
    csv_f.Date

    csv_in = readdlm(inp_f[i],',')[2:end,2:end]


    csv_in[csv_in .< 120] .= 0
    csv_in[csv_in .> 120] .= 1

    csv_out = DataFrame(csv_in,:auto)
    insertcols!(csv_out,1,:Date => csv_f.Date)   
    rename!(csv_out,csv_f.names)
    CSV.write(outputdir*inp_files[i][1:end-8]*"exc.csv", csv_out)
end


