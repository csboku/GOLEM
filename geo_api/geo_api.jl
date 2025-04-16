using Gtk
using HTTP
using JSON3
using Sockets
using DataFrames

API_URL = "https://dataset.api.hub.geosphere.at/v1/datasets"

# --- GUI Elements ---
win = GtkWindow("Simple API GUI", 400, 250)       # Main window
vbox = GtkBox(:h)                                # Vertical layout box
push!(win, vbox)                                 # Add vbox to window
b = GtkButton("Click Me")
push!(vbox, b)
showall(win)

# First lets try to get the data from the API
function get_data()
    response = HTTP.get(API_URL)
    println(response.status)
    println(response.body)
end

response = HTTP.get(API_URL)

response.body

datasets = JSON3.read(response.body)






for k in d_keys
    println(k)
end