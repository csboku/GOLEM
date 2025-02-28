using Rasters,Shapefile,Plots,CSV,DataFrames,Statistics,DelimitedFiles,ProgressMeter

datadir = "/home/cschmidt/data/attain/countymapped"
cd(@__DIR__)
@__DIR__
inp_files = readdir(datadir)
inp_f = readdir(datadir,join =true)

mda_f = inp_f[occursin.("mda8.csv",inp_f)]
mda_exc_f = inp_f[occursin.("mda8_exc",inp_f)]

mda_files = inp_files[occursin.("mda8.csv",inp_files)]
mda_exc_fiels = inp_files[occursin.("mda8_exc",inp_files)]

shp_in_dist = Shapefile.Table("/home/cschmidt/data/shp/OGDEXT_POLBEZ_1_STATISTIK_AUSTRIA_20210101/STATISTIK_AUSTRIA_POLBEZ_20210101.shp")

shp_in_munic = Shapefile.Table("/home/cschmidt/data/shp/OGDEXT_GEM_1_STATISTIK_AUSTRIA_20210101/STATISTIK_AUSTRIA_GEM_20210101.shp")



munic_id = shp_in_munic.id
dist_id = shp_in_dist.id

munic_id
munic_id = first.(munic_id,3)


dist_id[dist_id .∉ Ref(munic_id)]
shp_in_dist.name[dist_id .∉ Ref(munic_id)]

#### Code 900; Wien (Stadt nicht in dem county file)

dist_names = shp_in_dist.name

dist_names = dist_names[dist_id .∈ Ref(munic_id)]



mlength = length(unique(munic_id))

munic_dist_id = unique(munic_id)

munic_id .== munic_dist_id[2]



@showprogress for f in eachindex(mda_f)
    csv_f = CSV.File(mda_f[f])

    csv_f.names
    csv_f.Column1
    csv_f.Date

    csv_in = readdlm(mda_f[f],',')

    csv_data = csv_in[2:end,3:end]

    tlength = length(csv_f.Date)
    outmat = zeros(tlength,mlength)

    for i in eachindex(munic_dist_id)
        println(i)
        outmat[:,i] = mean(csv_data[:,munic_id .== munic_dist_id[i]],dims=2)
    end
    
    outdf = DataFrame(outmat,:auto)
    rename!(outdf,dist_names)
    insertcols!(outdf,1,:Date => csv_f.Date)   
    CSV.write(mda_files[f][1:end-21]*"districtmapped_mda8.csv", outdf)
end


##### FUNKTIONIERT SO NICHT
## Zuerst mda8 mappen und dann die Überschreitungen zählen

@showprogress for f in each
    vindex(mda_exc_f)
    csv_f = CSV.File(mda_exc_f[f])

    csv_f.names
    csv_f.Column1
    csv_f["csv_in.Date"]

    csv_in = readdlm(mda_exc_f[f],',')

    csv_data = csv_in[2:end,3:end]

    tlength = length(csv_f["csv_in.Date"])
    outmat = zeros(tlength,mlength)

    for i in eachindex(munic_dist_id)
        #println(i)
        outmat[:,i] = sum(csv_data[:,munic_id .== munic_dist_id[i]],dims=2)
    end
    
    outdf = DataFrame(outmat,:auto)
    rename!(outdf,dist_names)
    insertcols!(outdf,1,:Date =>  csv_f["csv_in.Date"])   
    CSV.write(mda_exc_fiels[f][1:end-25]*"districtmapped_mda8_exc.csv", outdf)
end



