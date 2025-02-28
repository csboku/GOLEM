cd(@__DIR__)

walkdir("/home/cschmidt/projects/future_capacity/")

for (root, dirs, files) in walkdir("/home/cschmidt/projects/future_capacity/")
    for file in files
        if occursin.(".png",file)
            cp(joinpath(root, file),"/home/cschmidt/projects/future_capacity/all_plots/"*file,force=true)
        end
    end
end


