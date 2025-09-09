from ecmwf.opendata import Client

client = Client(source="ecmwf",model="ifs")

# client.retrieve(
#     step=240,
#     type="fc",
#     param="msl",
#     target="data.grib2",
# )

print(client.latest(
    type="fc",
    target="data.grib2",
))

client.retrieve(
    type="fc",
    step=24,
    target="/gpfs/data/fs71391/cschmidt/data/ecmwf/data.grib2",
)
