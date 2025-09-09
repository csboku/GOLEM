using Gumbo
using AbstractTrees
using Downloads
using ProgressMeter

cd(@__DIR__)


function extract_links_from_file(filepath::String)
    # Read the saved HTML file
    html_content = read(filepath, String)

    # Parse HTML
    doc = parsehtml(html_content)

    download_links = []
    for elem in PreOrderDFS(doc.root)
        if typeof(elem) == HTMLElement{:a}
            href = getattr(elem, "href", nothing)
            if href !== nothing
                # Check for download extensions
                if occursin(r"\.(pdf|zip|exe|dmg|tar\.gz|rar|doc|docx|xls|xlsx|ppt|pptx|nc|hdf5|dat|csv|tgz)$"i, href)
                    push!(download_links, href)
                end
                # Check for download attribute
                if haskey(attrs(elem), "download")
                    push!(download_links, href)
                end
            end
        end
    end

    return unique(download_links)
end



function download_files(urls, download_dir::String="./downloads")
    # Create download directory
    mkpath(download_dir)

    successful = 0
    failed = String[]

    @showprogress "Downloading files..." for (i, url) in enumerate(urls)
        try
            filename = basename(url)
            # Handle query parameters in URL
            filename = split(filename, '?')[1]
            filepath = joinpath(download_dir, filename)

            println("Downloading: $filename")
            Downloads.download(url, filepath)
            successful += 1

        catch e
            println("Failed to download $url: $e")
            push!(failed, url)
        end
    end

    println("\nDownload Summary:")
    println("✅ Successful: $successful")
    println("❌ Failed: $(length(failed))")

    return failed
end


# Usage
links = extract_links_from_file("./dsd.html")




failed_downloads = download_files(links, "/sto4/projects/BIOMASS_CC_AQ/geosphere/rcp_data/dl/")

