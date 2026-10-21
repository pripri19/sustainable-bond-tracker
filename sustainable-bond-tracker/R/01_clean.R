# -----------------------------------------------------------------------------
# 01_clean.R — load the hand-compiled register, validate, enrich, save
# Output: data/processed/bonds_clean.csv and .rds
# -----------------------------------------------------------------------------

source("R/00_setup.R")

raw <- read_csv("data/raw/bonds_raw.csv", show_col_types = FALSE,
                col_types = cols(.default = col_character()))
fx  <- read_csv("data/reference/fx_indicative.csv", show_col_types = FALSE)

num <- function(x) suppressWarnings(as.numeric(x))

bonds <- raw %>%
  mutate(
    issue_date        = as.Date(issue_date),
    maturity_date     = as.Date(maturity_date),
    amount_local_m    = num(amount_local_m),
    amount_usd_m_source = num(amount_usd_m_source),
    coupon_pct        = num(coupon_pct),
    step_up_coupon_pct = num(step_up_coupon_pct),
    spread_bps        = num(spread_bps),
    tenor_years       = num(tenor_years)
  ) %>%
  left_join(fx %>% select(currency, units_per_usd), by = "currency") %>%
  mutate(
    # Prefer the USD figure quoted by the source; otherwise indicative FX
    amount_usd_m = coalesce(amount_usd_m_source,
                            amount_local_m / units_per_usd),
    usd_basis    = if_else(!is.na(amount_usd_m_source),
                           "Source-quoted", "Indicative FX"),
    issue_year   = year(issue_date),
    maturity_year = year(maturity_date),
    label        = factor(label, levels = LABEL_LEVELS),
    region       = factor(region, levels = REGION_LEVELS),
    pricing_disclosed = coupon_type != "Not disclosed",
    framework_type = if_else(label == "Sustainability-linked",
                             "KPI-linked", "Use of proceeds"),
    tenor_bucket = cut(tenor_years,
                       breaks = c(0, 3, 5, 7, 10, Inf),
                       labels = c("<=3y", "3-5y", "5-7y", "7-10y", ">10y"),
                       right = TRUE)
  )

# ---- Validation -------------------------------------------------------------
stopifnot(
  !any(duplicated(bonds$bond_id)),
  all(!is.na(bonds$issue_date)),
  all(!is.na(bonds$label)),
  all(!is.na(bonds$region)),
  all(!is.na(bonds$amount_usd_m)),
  all(nchar(bonds$source_url) > 10)
)

out_of_window <- bonds %>%
  filter(issue_date < WINDOW_START | issue_date > WINDOW_END)
if (nrow(out_of_window) > 0) {
  warning(nrow(out_of_window), " bond(s) fall outside the analysis window: ",
          paste(out_of_window$bond_id, collapse = ", "))
}

bad_maturity <- bonds %>% filter(!is.na(maturity_date),
                                 maturity_date <= issue_date)
if (nrow(bad_maturity) > 0) stop("Maturity before issue: ",
                                 paste(bad_maturity$bond_id, collapse = ", "))

bonds <- bonds %>%
  filter(issue_date >= WINDOW_START, issue_date <= WINDOW_END) %>%
  arrange(issue_date)

dir.create("data/processed", showWarnings = FALSE, recursive = TRUE)
write_csv(bonds, "data/processed/bonds_clean.csv")
saveRDS(bonds, "data/processed/bonds_clean.rds")

message(sprintf("01_clean: %d bonds, %d issuers, %d countries, USD %.0fm total.",
                nrow(bonds), n_distinct(bonds$issuer),
                n_distinct(bonds$country), sum(bonds$amount_usd_m)))
