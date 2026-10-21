# -----------------------------------------------------------------------------
# 00_setup.R — packages, paths and shared styling
# Run from the project root (open sustainable-bond-tracker.Rproj in RStudio).
# -----------------------------------------------------------------------------

required_pkgs <- c("dplyr", "tidyr", "readr", "ggplot2", "scales", "forcats",
                   "stringr", "lubridate", "knitr", "rmarkdown")

missing_pkgs <- required_pkgs[!vapply(required_pkgs, requireNamespace,
                                      logical(1), quietly = TRUE)]
if (length(missing_pkgs) > 0) {
  message("Installing missing packages: ", paste(missing_pkgs, collapse = ", "))
  install.packages(missing_pkgs, repos = "https://cloud.r-project.org")
}

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(readr)
  library(ggplot2)
  library(scales)
  library(forcats)
  library(stringr)
  library(lubridate)
})

if (!file.exists("data/raw/bonds_raw.csv")) {
  stop("Working directory must be the project root. ",
       "Open sustainable-bond-tracker.Rproj, or setwd() to the project folder.")
}

# Analysis window ------------------------------------------------------------
WINDOW_START <- as.Date("2021-10-01")
WINDOW_END   <- as.Date("2026-10-31")

# Shared palette (Okabe-Ito, colour-blind safe) ------------------------------
LABEL_LEVELS  <- c("Green", "Social", "Sustainability", "Sustainability-linked")
LABEL_COLOURS <- c("Green"                 = "#009E73",
                   "Social"                = "#CC79A7",
                   "Sustainability"        = "#0072B2",
                   "Sustainability-linked" = "#E69F00")

REGION_LEVELS <- c("Southern Africa", "East Africa", "West Africa",
                   "North Africa", "Indian Ocean")

theme_tracker <- function(base_size = 11) {
  theme_minimal(base_size = base_size) +
    theme(
      plot.title         = element_text(face = "bold", size = rel(1.15)),
      plot.subtitle      = element_text(colour = "grey30"),
      plot.caption       = element_text(colour = "grey45", size = rel(0.75),
                                        hjust = 0),
      panel.grid.minor   = element_blank(),
      panel.grid.major.x = element_blank(),
      legend.position    = "top",
      legend.title       = element_blank(),
      plot.title.position   = "plot",
      plot.caption.position = "plot"
    )
}

SOURCE_CAPTION <- "Source: bond tracker register; per-bond source URLs in data/raw/bonds_raw.csv"

# Short display names for charts
short_issuer <- function(x) {
  dplyr::recode(x,
    "Tanga Urban Water Supply and Sanitation Authority" = "Tanga UWASA",
    "Standard Bank of South Africa" = "Standard Bank",
    "Industrial Development Corporation" = "IDC",
    "Arab African International Bank" = "AAIB",
    "Development Bank of Rwanda (BRD)" = "BRD Rwanda",
    "ONCF (Moroccan national railways)" = "ONCF",
    "Copperbelt Energy Corporation" = "Copperbelt Energy")
}
