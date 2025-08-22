
#set document(author: "Gemini", title: "Image Report")
#set text(size: 10pt)

#show link: set text(blue)

#let png_files = (

  "o3_mean_uncorrected_august_2011.png",

    "o3_mean_fine_august_2011.png",
        "o3_mean_coarse_august_2011.png",

  "o3_mean_uncorrected_regridded_august_2011.png",
  "o3_ecdf_comparison_august_2011.png",
  "o3_pdf_comparison_august_2011.png",
)

#for file in png_files {
  figure(
    image(file, width: 80%),
    caption: [Image: #file],
  )
}
