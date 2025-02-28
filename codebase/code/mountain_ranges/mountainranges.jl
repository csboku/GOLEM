using Shapefile,Plots,Statistics


mntr = Shapefile.Table("/home/cschmidt/data/geo/GMBA_Inventory_v2.0_standard/GMBA_Inventory_v2.0_standard.shp")


mntr

aut_idx = mntr.Countries .== "Austria" 

aut_idx[ismissing.(aut_idx)] .= false

aut_idx =BitArray(aut_idx)


aut_geoms = mntr.geometry[aut_idx]


mntr.Name_DE[aut_idx] |> println
mntr.Name_EN[aut_idx] |> println

mntr.Elev_High[aut_idx] |> println