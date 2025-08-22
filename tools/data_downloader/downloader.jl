using Gtk4
using HTTP
using Gumbo
using Downloads

function main()
    # Create the main window
    win = GtkWindow("Data Downloader", 800, 600)

    # Create a vertical box to hold the UI elements
    vbox = GtkBox(:vertical)
    win[] = vbox

    # URL input
    url_entry = GtkEntry()
    vbox_add(vbox, GtkLabel("URL:"))
    vbox_add(vbox, url_entry)

    # Fetch Links button
    fetch_button = GtkButton("Fetch Links")
    vbox_add(vbox, fetch_button)

    # Filter input
    filter_entry = GtkEntry()
    vbox_add(vbox, GtkLabel("Filter:"))
    vbox_add(vbox, filter_entry)

    # List box for links
    list_box = GtkListBox()
    list_box.selection_mode = Gtk4.SelectionMode_MULTIPLE
    scrolled_win = GtkScrolledWindow()
    scrolled_win[] = list_box
    vbox_add(vbox, scrolled_win)

    # Download buttons
    hbox = GtkBox(:horizontal)
    download_selected_button = GtkButton("Download Selected")
    download_all_button = GtkButton("Download All")
    hbox_add(hbox, download_selected_button)
    hbox_add(hbox, download_all_button)
    vbox_add(vbox, hbox)

    # Status label
    status_label = GtkLabel("Enter a URL and click 'Fetch Links'")
    vbox_add(vbox, status_label)

    # --- Logic ---

    links = String[]

    function fetch_links_callback(widget)
        url = url_entry.text
        if isempty(url)
            status_label.label = "Please enter a URL."
            return
        end

        status_label.label = "Fetching links from $url..."
        try
            response = HTTP.get(url)
            parsed_html = Gumbo.parsehtml(String(response.body))
            empty!(list_box)
            empty!(links)
            for element in eachmatch(Selector("a"), parsed_html.root)
                if haskey(element.attributes, "href")
                    link = element.attributes["href"]
                    if !startswith(link, "http")
                        try
                            link_uri = URI(link)
                            base_uri = URI(url)
                            link = string(resolve(base_uri, link_uri))
                        catch e
                            println("Error resolving link: $link, $e")
                            continue
                        end
                    end
                    push!(links, link)
                    row = GtkLabel(link)
                    push!(list_box, row)
                end
            end
            status_label.label = "Found $(length(links)) links."
        catch e
            status_label.label = "Error fetching links: $e"
        end
    end

    function filter_links_callback(widget)
        filter_text = filter_entry.text
        for (i, child) in enumerate(list_box)
            label = child[1]
            if occursin(filter_text, label.label)
                child.visible = true
            else
                child.visible = false
            end
        end
    end

    function download_files(files_to_download)
        if isempty(files_to_download)
            status_label.label = "No files to download."
            return
        end

        if !isdir("downloads")
            mkdir("downloads")
        end

        for (i, link) in enumerate(files_to_download)
            try
                status_label.label = "Downloading file $i of $(length(files_to_download)): $link"
                filename = basename(link)
                downloader = Downloader(joinpath("downloads", filename), link)
                download(downloader)
            catch e
                status_label.label = "Error downloading $link: $e"
            end
        end
        status_label.label = "Download complete."
    end

    function download_selected_callback(widget)
        selected_rows = get_selected_rows(list_box)
        files_to_download = [row[1].label for row in selected_rows]
        download_files(files_to_download)
    end

    function download_all_callback(widget)
        visible_links = []
        for child in list_box
            if child.visible
                push!(visible_links, child[1].label)
            end
        end
        download_files(visible_links)
    end


    # Connect signals
    signal_connect(fetch_links_callback, fetch_button, "clicked")
    signal_connect(filter_links_callback, filter_entry, "changed")
    signal_connect(download_selected_callback, download_selected_button, "clicked")
    signal_connect(download_all_callback, download_all_button, "clicked")


    if !isinteractive()
        c = Condition()
        signal_connect(win, :destroy) do widget
            notify(c)
        end
        wait(c)
    end
end

main()
