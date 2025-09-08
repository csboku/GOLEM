using Plots,NCDatasets

dsa = Dataset("dsa_W.nc")
dsb = Dataset("dsb_W.nc")

dsa
we = dsa["west_east"][:]
sn = dsa["south_north"][:]


l = @layout [a b; c]


p1 = heatmap(we,[1:47],transpose(dsa["W"][:,50,:,1]),c=:batlow,colorbar_title="Z Wind-component [ms⁻¹]",clim=(-0.5,0.5),xaxis=false,yaxis=false,colorbar_titlefontsize=6,colorbar_tickfontsize=2);
p2 = heatmap(we,[1:47],transpose(dsb["W"][:,50,:,1]),c=:batlow,colorbar_title="Z Wind-component [ms⁻¹]",clim=(-0.5,0.5),xaxis=false,yaxis=false,colorbar_titlefontsize=6,colorbar_tickfontsize=2);
p3 = heatmap(we,[1:47],transpose(dsb["W"][:,50,:,1]),c=:roma,colorbar_title="Z Wind-component [ms⁻¹]",clim=(-0.5,0.5),xaxis=false,yaxis=false,colorbar_titlefontsize=6,colorbar_tickfontsize=2);

pout = plot(p1, p2, p3, layout = l);


anim = @animate for i ∈ 1:100
    print(i)
    p1 = heatmap(we,[1:47],transpose(dsa["W"][:,50,:,1]),c=:batlow,colorbar_title="Z Wind-component [ms⁻¹]",clim=(-0.5,0.5),xaxis=false,yaxis=false,colorbar_titlefontsize=6,colorbar_tickfontsize=2);
    p2 = heatmap(we,[1:47],transpose(dsb["W"][:,50,:,1]),c=:batlow,colorbar_title="Z Wind-component [ms⁻¹]",clim=(-0.5,0.5),xaxis=false,yaxis=false,colorbar_titlefontsize=6,colorbar_tickfontsize=2);
    p3 = heatmap(we,[1:47],transpose(dsb["W"][:,50,:,1]),c=:roma,colorbar_title="Z Wind-component [ms⁻¹]",clim=(-0.5,0.5),xaxis=false,yaxis=false,colorbar_titlefontsize=6,colorbar_tickfontsize=2);

    pout = plot(p1, p2, p3, layout = l);
end

gif(anim, "z_wind_fps15.gif", fps = 15)

# savefig(pout,"z_component.png")


