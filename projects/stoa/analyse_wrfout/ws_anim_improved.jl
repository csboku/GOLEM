using Plots, NCDatasets

# Load datasets
dsa = Dataset("dsa_WS.nc")
dsb = Dataset("dsb_WS.nc")

# Get coordinate arrays
lat = dsa["lat"][1,:]  # Extract 1D array
lon = dsa["lon"][:,1]  # Extract 1D array

# Set up layout - 3 panels: 2 on top, 1 below
layout = @layout [a b; c]

# Common plot settings for better formatting
plot_settings = (
    colorbar_titlefontsize=12,
    colorbar_tickfontsize=10,
    titlefontsize=14,
    guidefontsize=12,
    tickfontsize=10,
    dpi=150,
    margin=5Plots.mm
)

# Create individual plots with better formatting
function create_plots(time_idx)
    p1 = heatmap(lon, lat, transpose(dsa["WS"][:,:,1,time_idx]),
        c=:roma,
        colorbar_title="Wind Speed [ms⁻¹]",
        clim=(0, 15),
        title="Dataset A - Wind Speed",
        xaxis=false,yaxis=false,
        aspect_ratio=:auto;
        plot_settings...
    )

    p2 = heatmap(lon, lat, transpose(dsb["WS"][:,:,1,time_idx]),
        c=:roma,
        colorbar_title="Wind Speed [ms⁻¹]",
        clim=(0, 15),
        title="Dataset B - Wind Speed",
        xaxis=false,yaxis=false,
        aspect_ratio=:auto;
        plot_settings...
    )

    p3 = heatmap(lon, lat, transpose(dsb["WS"][:,:,1,time_idx] - dsa["WS"][:,:,1,time_idx]),
        c=:vik,
        colorbar_title="Difference [ms⁻¹]",
        clim=(-5, 5),
        title="Difference (B - A)",
        xaxis=false,yaxis=false,
        aspect_ratio=:auto;
        plot_settings...
    )

    return p1, p2, p3
end

# Create static plot for first time step
p1, p2, p3 = create_plots(1)
pout = plot(p1, p2, p3, layout=layout,
    plot_title="WRF Wind Speed Analysis - Time Step 1",
    size=(1400, 1000)
)

# Save static plot
savefig(pout, "ws_improved_static.png")
println("Static plot saved as ws_improved_static.png")

# Animation with improved formatting
anim = @animate for i ∈ 1:100
    println("Processing frame $i/100")

    # Create plots for this time step
    p1_anim, p2_anim, p3_anim = create_plots(i)

    # Combine plots with title showing time step
    plot(p1_anim, p2_anim, p3_anim, layout=layout,
        plot_title="WRF Wind Speed Analysis - Time Step $i",
        size=(1400, 1000)
    )
end

# Create GIF with higher quality
gif(anim, "ws_improved.gif", fps=15)
println("Animation saved as ws_improved.gif")
