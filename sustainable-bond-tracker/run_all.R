# -----------------------------------------------------------------------------
# run_all.R — rebuild the whole project end to end
# In RStudio: open sustainable-bond-tracker.Rproj, then Source this file.
# -----------------------------------------------------------------------------

source("R/00_setup.R")
source("R/01_clean.R")
source("R/02_analysis.R")
source("R/03_charts.R")

rmarkdown::render("reports/bond_tracker_report.Rmd",
                  output_dir = "output", quiet = TRUE)
rmarkdown::render("reports/strategic_proposal.Rmd",
                  output_format = "all", output_dir = "output", quiet = TRUE)

message("Done. Open output/bond_tracker_report.html and output/strategic_proposal.docx")
