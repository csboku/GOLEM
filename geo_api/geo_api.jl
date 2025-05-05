using Gtk
using Dates
using HTTP
using JSON
using DataFrames
using CSV
using LibCURL
using StaticArrays
using Statistics

"""
GeoSphere Austria Dataset API GUI Application

This application allows users to download meteorological and climatological data
from the GeoSphere Austria Dataset API.
"""

# Constant definitions
const BASE_URL = "https://dataset.api.hub.geosphere.at/v1"
const DATASETS_URL = "$(BASE_URL)/datasets"

# Data structures to store API information
mutable struct DatasetInfo
    type::String
    mode::String
    url::String
    response_formats::Vector{String}
end

# Main application structure
mutable struct AppState
    datasets::Dict{String, DatasetInfo}
    selected_dataset::Union{String, Nothing}
    selected_stations::Vector{Int}
    selected_parameters::Vector{String}
    start_date::Union{DateTime, Nothing}
    end_date::Union{DateTime, Nothing}
    result_data::Union{DataFrame, Nothing}
    status_message::String

    # Constructor with default values
    function AppState()
        return new(
            Dict{String, DatasetInfo}(),
            nothing,
            Int[],
            String[],
            nothing,
            nothing,
            nothing,
            "Ready"
        )
    end
end

# Initialize application state
app_state = AppState()

function fetch_datasets()
    app_state.status_message = "Fetching available datasets..."

    try
        response = HTTP.get(DATASETS_URL)
        if response.status == 200
            datasets_json = JSON.parse(String(response.body))
            app_state.datasets = Dict{String, DatasetInfo}()

            for (endpoint, info) in datasets_json
                # Create a new DatasetInfo instance
                dataset_info = DatasetInfo(
                    info["type"],
                    info["mode"],
                    info["url"],
                    info["response_formats"]
                )
                app_state.datasets[endpoint] = dataset_info
            end

            app_state.status_message = "Loaded $(length(app_state.datasets)) datasets"
            return true
        else
            app_state.status_message = "Error loading datasets: HTTP $(response.status)"
            return false
        end
    catch e
        app_state.status_message = "Error: $(e)"
        return false
    end
end

function fetch_metadata(dataset_url)
    try
        metadata_url = "$(dataset_url)/metadata"
        response = HTTP.get(metadata_url)

        if response.status == 200
            return JSON.parse(String(response.body))
        else
            app_state.status_message = "Error loading metadata: HTTP $(response.status)"
            return nothing
        end
    catch e
        app_state.status_message = "Error: $(e)"
        return nothing
    end
end

function fetch_stations(metadata)
    if haskey(metadata, "stations")
        return metadata["stations"]
    else
        return []
    end
end

function fetch_parameters(metadata)
    if haskey(metadata, "parameters")
        return metadata["parameters"]
    else
        return []
    end
end

function download_data(dataset_url, params)
    try
        query_url = dataset_url

        # Add query parameters if any are provided
        if !isempty(params)
            query_string = join(["$key=$(HTTP.URIs.escapeuri(string(value)))" for (key, value) in params], "&")
            query_url = "$(dataset_url)?$(query_string)"
        end

        app_state.status_message = "Downloading data from: $(query_url)"

        response = HTTP.get(query_url)

        if response.status == 200
            content_type = HTTP.header(response, "Content-Type", "")

            if occursin("application/json", content_type) || occursin("geojson", content_type)
                result = JSON.parse(String(response.body))
                app_state.status_message = "Downloaded JSON data"
                return result
            elseif occursin("text/csv", content_type)
                result = CSV.read(IOBuffer(response.body), DataFrame)
                app_state.status_message = "Downloaded CSV data"
                return result
            else
                app_state.status_message = "Downloaded raw data"
                return String(response.body)
            end
        else
            app_state.status_message = "Error downloading data: HTTP $(response.status)"
            return nothing
        end
    catch e
        app_state.status_message = "Error: $(e)"
        return nothing
    end
end

function bulk_download(dataset_url, stations, start_date, end_date, output_format, output_dir)
    try
        # Get metadata to find all available parameters
        metadata = fetch_metadata(dataset_url)
        if metadata === nothing || !haskey(metadata, "parameters")
            app_state.status_message = "Error: Could not fetch metadata or no parameters available"
            return false
        end

        # Get all parameter names
        all_parameters = collect(keys(metadata["parameters"]))

        # Create output directory if it doesn't exist
        if !isdir(output_dir)
            mkpath(output_dir)
        end

        # For each station, download all parameters
        total_stations = length(stations)
        successful_downloads = 0

        for (i, station_id) in enumerate(stations)
            app_state.status_message = "Processing station $station_id ($i of $total_stations)"

            # Prepare query parameters
            params = Dict{String, Any}()
            params["station_ids"] = station_id
            params["parameters"] = join(all_parameters, ",")

            # Add date range if specified
            if start_date !== nothing
                params["start"] = Dates.format(start_date, "yyyy-mm-dd")
            end

            if end_date !== nothing
                params["end"] = Dates.format(end_date, "yyyy-mm-dd")
            end

            # Add format
            params["output_format"] = output_format

            # Download data
            result = download_data(dataset_url, params)

            if result !== nothing
                # Create filename
                filename = joinpath(output_dir, "station_$(station_id)_data.$(output_format)")

                # Save data
                if save_data(result, filename, output_format)
                    successful_downloads += 1
                end
            end
        end

        app_state.status_message = "Bulk download completed. Successfully downloaded data for $successful_downloads out of $total_stations stations."
        return successful_downloads > 0
    catch e
        app_state.status_message = "Error during bulk download: $(e)"
        return false
    end
end

function process_dataset_selection(dataset_key)
    app_state.selected_dataset = dataset_key
    dataset_info = app_state.datasets[dataset_key]

    # Clear previous selections
    app_state.selected_stations = Int[]
    app_state.selected_parameters = String[]

    # Fetch metadata for the selected dataset
    metadata = fetch_metadata(dataset_info.url)

    if metadata !== nothing
        app_state.status_message = "Loaded metadata for $(dataset_key)"
        return metadata
    else
        app_state.status_message = "Failed to load metadata for $(dataset_key)"
        return nothing
    end
end

function save_data(data, filename, format)
    try
        if format == "csv"
            if data isa DataFrame
                CSV.write(filename, data)
            else
                # Try to convert to DataFrame if it's not already
                df = if data isa Dict && haskey(data, "features")
                    # Handle GeoJSON format
                    features_data = DataFrame()

                    for feature in data["features"]
                        if haskey(feature, "properties")
                            # Combine with existing data
                            if isempty(features_data)
                                features_data = DataFrame(feature["properties"])
                            else
                                push!(features_data, feature["properties"])
                            end
                        end
                    end

                    features_data
                else
                    # Try generic conversion
                    DataFrame(data)
                end

                CSV.write(filename, df)
            end
        elseif format == "json"
            open(filename, "w") do io
                if data isa Dict || data isa Vector
                    JSON.print(io, data, 4)  # Pretty print with 4-space indent
                else
                    # Convert to Dict if not already
                    JSON.print(io, Dict("data" => data), 4)
                end
            end
        else
            # Save as raw text
            open(filename, "w") do io
                write(io, string(data))
            end
        end

        app_state.status_message = "Data saved to $(filename)"
        return true
    catch e
        app_state.status_message = "Error saving data: $(e)"
        return false
    end
end

# Build GUI components
function build_gui()
    # Create main window
    win = GtkWindow("GeoSphere Austria Dataset API", 800, 600)

    # Create main vertical box
    main_vbox = GtkBox(:v)
    set_gtk_property!(main_vbox, :spacing, 10)
    set_gtk_property!(main_vbox, :margin, 10)
    push!(win, main_vbox)

    # Create header
    header_label = GtkLabel("GeoSphere Austria Dataset API Explorer")
    set_gtk_property!(header_label, :use_markup, true)
    GAccessor.markup(header_label, "<span size='large' weight='bold'>GeoSphere Austria Dataset API Explorer</span>")
    push!(main_vbox, header_label)

    # Create horizontal box for main content
    content_hbox = GtkBox(:h)
    set_gtk_property!(content_hbox, :spacing, 10)
    push!(main_vbox, content_hbox)

    # Left panel - Dataset selection
    left_vbox = GtkBox(:v)
    set_gtk_property!(left_vbox, :spacing, 5)

    dataset_frame = GtkFrame("Datasets")
    dataset_scroll = GtkScrolledWindow()
    set_gtk_property!(dataset_scroll, :min_content_height, 300)
    dataset_list = GtkListBox()
    push!(dataset_scroll, dataset_list)
    push!(dataset_frame, dataset_scroll)
    push!(left_vbox, dataset_frame)

    # Load Datasets button
    load_datasets_btn = GtkButton("Load Datasets")
    push!(left_vbox, load_datasets_btn)

    signal_connect(load_datasets_btn, "clicked") do widget
        # Clear the list first
        for child in dataset_list
            destroy(child)
        end

        if fetch_datasets()
            # Populate dataset list with sorted keys
            sorted_keys = sort(collect(keys(app_state.datasets)))
            for key in sorted_keys
                info = app_state.datasets[key]
                row = GtkListBoxRow()
                label = GtkLabel(key)
                set_gtk_property!(label, :xalign, 0.0)  # Left align text
                set_gtk_property!(label, :margin, 5)
                push!(row, label)
                push!(dataset_list, row)
            end
            showall(dataset_list)
        end

        # Update status
        status_bar.label = app_state.status_message
    end

    # Add left panel to content
    push!(content_hbox, left_vbox)
    set_gtk_property!(left_vbox, :expand, false)

    # Middle panel - Parameters and stations
    middle_vbox = GtkBox(:v)
    set_gtk_property!(middle_vbox, :spacing, 5)

    # Parameters frame
    params_frame = GtkFrame("Parameters")
    params_scroll = GtkScrolledWindow()
    set_gtk_property!(params_scroll, :min_content_height, 150)
    params_box = GtkBox(:v)
    set_gtk_property!(params_box, :spacing, 2)
    push!(params_scroll, params_box)
    push!(params_frame, params_scroll)
    push!(middle_vbox, params_frame)

    # Stations frame
    stations_frame = GtkFrame("Stations")
    stations_scroll = GtkScrolledWindow()
    set_gtk_property!(stations_scroll, :min_content_height, 150)
    stations_box = GtkBox(:v)
    set_gtk_property!(stations_box, :spacing, 2)
    push!(stations_scroll, stations_box)
    push!(stations_frame, stations_scroll)
    push!(middle_vbox, stations_frame)

    # Add middle panel to content
    push!(content_hbox, middle_vbox)
    set_gtk_property!(middle_vbox, :expand, true)

    # Right panel - Query controls
    right_vbox = GtkBox(:v)
    set_gtk_property!(right_vbox, :spacing, 10)

    # Date range
    date_frame = GtkFrame("Date Range")
    date_vbox = GtkBox(:v)
    set_gtk_property!(date_vbox, :spacing, 5)
    set_gtk_property!(date_vbox, :margin, 5)

    # Start date
    start_date_hbox = GtkBox(:h)
    set_gtk_property!(start_date_hbox, :spacing, 5)
    start_date_label = GtkLabel("Start Date:")
    set_gtk_property!(start_date_label, :xalign, 0.0)
    start_date_entry = GtkEntry()
    set_gtk_property!(start_date_entry, :placeholder_text, "YYYY-MM-DD")
    push!(start_date_hbox, start_date_label)
    push!(start_date_hbox, start_date_entry)
    push!(date_vbox, start_date_hbox)

    # End date
    end_date_hbox = GtkBox(:h)
    set_gtk_property!(end_date_hbox, :spacing, 5)
    end_date_label = GtkLabel("End Date:")
    set_gtk_property!(end_date_label, :xalign, 0.0)
    end_date_entry = GtkEntry()
    set_gtk_property!(end_date_entry, :placeholder_text, "YYYY-MM-DD")
    push!(end_date_hbox, end_date_label)
    push!(end_date_hbox, end_date_entry)
    push!(date_vbox, end_date_hbox)

    push!(date_frame, date_vbox)
    push!(right_vbox, date_frame)

    # Output format
    format_frame = GtkFrame("Output Format")
    format_vbox = GtkBox(:v)
    set_gtk_property!(format_vbox, :spacing, 5)
    set_gtk_property!(format_vbox, :margin, 5)

    format_combo = GtkComboBoxText()
    push!(format_combo, "csv", "CSV")
    push!(format_combo, "geojson", "GeoJSON")
    set_gtk_property!(format_combo, :active, 0)  # Default to CSV

    push!(format_vbox, format_combo)
    push!(format_frame, format_vbox)
    push!(right_vbox, format_frame)

    # Download button
    download_btn = GtkButton("Download Data")
    set_gtk_property!(download_btn, :margin_top, 10)
    push!(right_vbox, download_btn)

    # Bulk download button
    bulk_download_btn = GtkButton("Bulk Download All Parameters")
    set_gtk_property!(bulk_download_btn, :margin_top, 5)
    push!(right_vbox, bulk_download_btn)

    # Save to file button
    save_btn = GtkButton("Save Data to File")
    set_gtk_property!(save_btn, :margin_top, 5)
    push!(right_vbox, save_btn)

    # Add right panel to content
    push!(content_hbox, right_vbox)
    set_gtk_property!(right_vbox, :expand, false)

    # Add status bar at the bottom
    status_bar = GtkLabel("Ready")
    set_gtk_property!(status_bar, :xalign, 0.0)  # Left align
    set_gtk_property!(status_bar, :margin, 5)
    push!(main_vbox, status_bar)

    # Connect signals

    # Dataset selection
    signal_connect(dataset_list, "row-activated") do widget, row
        idx = get_gtk_property(row, :index, Int)
        sorted_keys = sort(collect(keys(app_state.datasets)))
        selected_key = sorted_keys[idx+1]  # +1 because GTK is 0-indexed

        # Clear existing parameter and station boxes
        for child in params_box
            destroy(child)
        end
        for child in stations_box
            destroy(child)
        end

        metadata = process_dataset_selection(selected_key)

        if metadata !== nothing
            # Populate parameters
            if haskey(metadata, "parameters")
                for (param_id, param_info) in metadata["parameters"]
                    check = GtkCheckButton(param_id)
                    if haskey(param_info, "description")
                        set_gtk_property!(check, :tooltip_text, param_info["description"])
                    end
                    push!(params_box, check)

                    # Connect signal to update selected parameters
                    signal_connect(check, "toggled") do widget
                        if get_gtk_property(widget, :active, Bool)
                            # Add to selected parameters if not already there
                            if !(param_id in app_state.selected_parameters)
                                push!(app_state.selected_parameters, param_id)
                            end
                        else
                            # Remove from selected parameters
                            filter!(p -> p != param_id, app_state.selected_parameters)
                        end
                    end
                end
            end

            # Populate stations if available
            if haskey(metadata, "stations")
                for (station_id, station_info) in metadata["stations"]
                    name = haskey(station_info, "name") ? station_info["name"] : "Station $station_id"
                    check = GtkCheckButton(name)
                    set_gtk_property!(check, :tooltip_text, "ID: $station_id")
                    push!(stations_box, check)

                    # Connect signal to update selected stations
                    signal_connect(check, "toggled") do widget
                        station_int_id = parse(Int, station_id)
                        if get_gtk_property(widget, :active, Bool)
                            # Add to selected stations if not already there
                            if !(station_int_id in app_state.selected_stations)
                                push!(app_state.selected_stations, station_int_id)
                            end
                        else
                            # Remove from selected stations
                            filter!(s -> s != station_int_id, app_state.selected_stations)
                        end
                    end
                end
            end

            showall(params_box)
            showall(stations_box)
        end

        # Update status
        status_bar.label = app_state.status_message
    end

    # Download button action
    signal_connect(download_btn, "clicked") do widget
        if app_state.selected_dataset === nothing
            app_state.status_message = "Error: No dataset selected"
            status_bar.label = app_state.status_message
            return
        end

        dataset_info = app_state.datasets[app_state.selected_dataset]

        # Prepare query parameters
        params = Dict{String, Any}()

        # Add selected parameters if any
        if !isempty(app_state.selected_parameters)
            params["parameters"] = join(app_state.selected_parameters, ",")
        end

        # Add selected stations if any
        if !isempty(app_state.selected_stations)
            params["station_ids"] = join(app_state.selected_stations, ",")
        end

        # Add date range if specified
        start_date_text = get_gtk_property(start_date_entry, :text, String)
        if !isempty(start_date_text)
            try
                app_state.start_date = DateTime(start_date_text)
                params["start"] = Dates.format(app_state.start_date, "yyyy-mm-dd")
            catch
                app_state.status_message = "Error: Invalid start date format. Use YYYY-MM-DD."
                status_bar.label = app_state.status_message
                return
            end
        end

        end_date_text = get_gtk_property(end_date_entry, :text, String)
        if !isempty(end_date_text)
            try
                app_state.end_date = DateTime(end_date_text)
                params["end"] = Dates.format(app_state.end_date, "yyyy-mm-dd")
            catch
                app_state.status_message = "Error: Invalid end date format. Use YYYY-MM-DD."
                status_bar.label = app_state.status_message
                return
            end
        end

        # Add format
        format = get_gtk_property(format_combo, :active_id, String)
        params["output_format"] = format

        # Download data
        result = download_data(dataset_info.url, params)

        if result !== nothing
            app_state.result_data = result
            app_state.status_message = "Data downloaded successfully"
        end

        # Update status
        status_bar.label = app_state.status_message
    end

    # Bulk download button action
    signal_connect(bulk_download_btn, "clicked") do widget
        if app_state.selected_dataset === nothing
            app_state.status_message = "Error: No dataset selected"
            status_bar.label = app_state.status_message
            return
        end

        if isempty(app_state.selected_stations)
            app_state.status_message = "Error: No stations selected for bulk download"
            status_bar.label = app_state.status_message
            return
        end

        dataset_info = app_state.datasets[app_state.selected_dataset]

        # Get date range if specified
        start_date = nothing
        end_date = nothing

        start_date_text = get_gtk_property(start_date_entry, :text, String)
        if !isempty(start_date_text)
            try
                start_date = DateTime(start_date_text)
            catch
                app_state.status_message = "Error: Invalid start date format. Use YYYY-MM-DD."
                status_bar.label = app_state.status_message
                return
            end
        end

        end_date_text = get_gtk_property(end_date_entry, :text, String)
        if !isempty(end_date_text)
            try
                end_date = DateTime(end_date_text)
            catch
                app_state.status_message = "Error: Invalid end date format. Use YYYY-MM-DD."
                status_bar.label = app_state.status_message
                return
            end
        end

        # Get output format
        format = get_gtk_property(format_combo, :active_id, String)

        # Ask user for output directory
        dialog = GtkFileChooserDialog(
            "Select Output Directory for Bulk Download",
            win,
            GtkFileChooserAction.SELECT_FOLDER,
            ("Cancel", GtkResponseType.CANCEL, "Select", GtkResponseType.ACCEPT)
        )

        response = run(dialog)
        if response == GtkResponseType.ACCEPT
            output_dir = GAccessor.filename(dialog)
            destroy(dialog)

            # Create a progress dialog
            progress_win = GtkWindow("Bulk Download Progress", 400, 150)
            progress_vbox = GtkBox(:v)
            set_gtk_property!(progress_vbox, :spacing, 10)
            set_gtk_property!(progress_vbox, :margin, 10)
            push!(progress_win, progress_vbox)

            progress_label = GtkLabel("Starting bulk download...")
            push!(progress_vbox, progress_label)

            progress_bar = GtkProgressBar()
            push!(progress_vbox, progress_bar)

            cancel_btn = GtkButton("Cancel")
            push!(progress_vbox, cancel_btn)

            showall(progress_win)

            # Run bulk download in a separate task to keep UI responsive
            @async begin
                try
                    # Update progress bar periodically
                    total_stations = length(app_state.selected_stations)

                    # Monitor thread to update progress
                    monitor_task = @async begin
                        for i in 1:100
                            # Update progress bar
                            Gtk.G_.fraction(progress_bar, i/100)
                            sleep(0.1)

                            # Exit if window is closed
                            if !Gtk.G_.is_visible(progress_win)
                                break
                            end
                        end
                    end

                    # Start bulk download
                    success = bulk_download(
                        dataset_info.url,
                        app_state.selected_stations,
                        start_date,
                        end_date,
                        format,
                        output_dir
                    )

                    # Close progress window
                    Gtk.destroy(progress_win)

                    # Update status
                    Gtk.G_.label(status_bar, app_state.status_message)

                catch e
                    app_state.status_message = "Error during bulk download: $(e)"
                    Gtk.G_.label(status_bar, app_state.status_message)
                    Gtk.destroy(progress_win)
                end
            end

            # Handle cancel button
            signal_connect(cancel_btn, "clicked") do widget
                app_state.status_message = "Bulk download cancelled by user"
                Gtk.G_.label(status_bar, app_state.status_message)
                Gtk.destroy(progress_win)
            end

            # Handle window close
            signal_connect(progress_win, :destroy) do widget
                app_state.status_message = "Bulk download cancelled by user"
                Gtk.G_.label(status_bar, app_state.status_message)
            end

        else
            destroy(dialog)
        end
    end

    # Save button action
    signal_connect(save_btn, "clicked") do widget
        if app_state.result_data === nothing
            app_state.status_message = "Error: No data to save"
            status_bar.label = app_state.status_message
            return
        end

        # Create a save dialog
        dialog = GtkFileChooserDialog(
            "Save Data",
            win,
            GtkFileChooserAction.SAVE,
            ("Cancel", GtkResponseType.CANCEL, "Save", GtkResponseType.ACCEPT)
        )

        # Set default filename
        format = get_gtk_property(format_combo, :active_id, String)
        default_filename = "geosphere_data_$(Dates.format(now(), "yyyymmdd_HHMMSS")).$format"
        GAccessor.filename(dialog, default_filename)

        # Show dialog and handle response
        response = run(dialog)
        if response == GtkResponseType.ACCEPT
            filename = GAccessor.filename(dialog)
            if save_data(app_state.result_data, filename, format)
                app_state.status_message = "Data saved to $filename"
            end
        end

        destroy(dialog)

        # Update status
        status_bar.label = app_state.status_message
    end

    # Show the window
    showall(win)

    # Set up window close event
    signal_connect(win, :destroy) do widget
        Gtk.gtk_quit()
    end

    return win
end

# Entry point
function main()
    win = build_gui()
    Gtk.GTK_MAIN()
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
