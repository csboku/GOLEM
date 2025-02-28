using ArchGDAL

shp_in = ArchGDAL.read("/sto2/data/lenian/data/shp/OGDEXT_GEM_1_STATISTIK_AUSTRIA_20210101/STATISTIK_AUSTRIA_GEM_20210101.shp")


geoms = ArchGDAL.getlayer(shp_in,0)

simplified = ArchGDAL.simplify(geoms, 0.001)
