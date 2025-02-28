#set heading(numbering: "1.1.a)")



= Plots

== Methods

#image("./plot_hgt_domain/hgt_domain_attain_autzoom_stations.png")
\
\
#image("./plot_rcp/emisions_nox_voc.png")
\
\
#image("./plot_rcp/methane_conc_rcp45_rcp85.png")


=== Bias correction 

==== Whole domain
#grid(
  columns: (1fr, 1fr),
    image("./meas_model_comp/1.png")
    ,
    image("./meas_model_comp/2.png")
)

\
\

#image("./meas_model_comp/measmod_box_col.png",width: 90%)

#grid(
  columns: (1fr, 1fr),
    image("./meas_model_comp/6.png")
    ,
    image("./meas_model_comp/8.png")
)

#pagebreak()
==== Bias correction selected stations

#grid(
  columns: (1fr, 1fr, 1fr),
    image("./plots_density_staion/density_AT0ENK1_Background_rural.png")
    ,
    image("./plots_density_staion/density_AT0ILL1_Background_rural.png")
    ,
    image("./plots_density_staion/density_AT0PIL1_Background_rural.png")

)
