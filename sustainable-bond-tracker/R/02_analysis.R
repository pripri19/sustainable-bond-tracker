# -----------------------------------------------------------------------------
# 02_analysis.R — summary tables (dplyr)
# Output: output/tables/*.csv and output/tables/key_metrics.rds
# -----------------------------------------------------------------------------

source("R/00_setup.R")
bonds <- readRDS("data/processed/bonds_clean.rds")
dir.create("output/tables", showWarnings = FALSE, recursive = TRUE)

# 1. Volume by year and label ------------------------------------------------
by_year_label <- bonds %>%
  count(issue_year, label, wt = amount_usd_m, name = "usd_m") %>%
  complete(issue_year, label, fill = list(usd_m = 0))

by_year <- bonds %>%
  group_by(issue_year) %>%
  summarise(deals = n(), usd_m = sum(amount_usd_m), .groups = "drop")

# 2. Use of proceeds ---------------------------------------------------------
by_sector <- bonds %>%
  group_by(use_of_proceeds) %>%
  summarise(deals = n(), usd_m = sum(amount_usd_m), .groups = "drop") %>%
  mutate(share = usd_m / sum(usd_m)) %>%
  arrange(desc(usd_m))

# 3. Hubs / countries --------------------------------------------------------
by_country <- bonds %>%
  group_by(region, country) %>%
  summarise(deals = n(), issuers = n_distinct(issuer),
            usd_m = sum(amount_usd_m),
            labels = paste(sort(unique(as.character(label))), collapse = ", "),
            .groups = "drop") %>%
  arrange(desc(usd_m))

by_issuer_type <- bonds %>%
  group_by(issuer_type) %>%
  summarise(deals = n(), usd_m = sum(amount_usd_m), .groups = "drop") %>%
  mutate(share = usd_m / sum(usd_m)) %>%
  arrange(desc(usd_m))

# 4. Pricing -----------------------------------------------------------------
fixed_coupons <- bonds %>%
  filter(!is.na(coupon_pct)) %>%
  select(bond_id, issuer, country, currency, label, coupon_type, coupon_pct,
         step_up_coupon_pct, tenor_years, use_of_proceeds, issue_date) %>%
  arrange(desc(coupon_pct))

jibar_frns <- bonds %>%
  filter(reference_rate == "3M JIBAR", !is.na(spread_bps), !is.na(tenor_years))

spread_model <- lm(spread_bps ~ tenor_years + I(capital_rank == "Tier 2"),
                   data = jibar_frns)

spread_by_bucket <- jibar_frns %>%
  filter(capital_rank == "Senior") %>%
  group_by(tenor_bucket) %>%
  summarise(notes = n(), median_spread_bps = median(spread_bps),
            min_bps = min(spread_bps), max_bps = max(spread_bps),
            .groups = "drop")

# 5. Tenor & maturity ladder -------------------------------------------------
tenor_summary <- bonds %>%
  filter(!is.na(tenor_years)) %>%
  group_by(label) %>%
  summarise(deals = n(), median_tenor = median(tenor_years),
            max_tenor = max(tenor_years), .groups = "drop")

maturity_ladder <- bonds %>%
  filter(!is.na(maturity_year)) %>%
  count(maturity_year, label, wt = amount_usd_m, name = "usd_m")

# 6. Disclosure quality ------------------------------------------------------
disclosure <- bonds %>%
  summarise(
    deals              = n(),
    pct_pricing        = mean(pricing_disclosed),
    pct_tenor          = mean(!is.na(tenor_years)),
    pct_usd_indicative = mean(usd_basis == "Indicative FX")
  )

# Key metrics used in the report and proposal --------------------------------
km <- list(
  n_bonds        = nrow(bonds),
  n_issuers      = n_distinct(bonds$issuer),
  n_countries    = n_distinct(bonds$country),
  total_usd_m    = sum(bonds$amount_usd_m),
  median_deal_usd_m = median(bonds$amount_usd_m),
  share_banks    = with(by_issuer_type,
                        sum(usd_m[issuer_type == "Bank"]) / sum(usd_m)),
  share_green_n  = mean(bonds$label == "Green"),
  share_slb_n    = mean(bonds$label == "Sustainability-linked"),
  share_za_usd   = with(by_country,
                        sum(usd_m[country == "South Africa"]) / sum(usd_m)),
  top_sector     = by_sector$use_of_proceeds[1],
  top_sector_share = by_sector$share[1],
  clean_energy_share = sum(by_sector$share[by_sector$use_of_proceeds == "Clean energy"]),
  water_share    = sum(by_sector$share[by_sector$use_of_proceeds == "Water infrastructure"]),
  water_deals    = sum(by_sector$deals[by_sector$use_of_proceeds == "Water infrastructure"]),
  fixed_min      = min(fixed_coupons$coupon_pct),
  fixed_max      = max(fixed_coupons$coupon_pct),
  n_fixed        = nrow(fixed_coupons),
  n_frn          = nrow(jibar_frns),
  spread_min     = min(jibar_frns$spread_bps),
  spread_max     = max(jibar_frns$spread_bps),
  spread_per_year = unname(coef(spread_model)["tenor_years"]),
  tier2_premium  = unname(coef(spread_model)[3]),
  spread_r2      = summary(spread_model)$r.squared,
  median_tenor   = median(bonds$tenor_years, na.rm = TRUE),
  pct_pricing    = disclosure$pct_pricing,
  pct_tenor      = disclosure$pct_tenor,
  mu_deals       = sum(bonds$country == "Mauritius"),
  mu_usd_m       = sum(bonds$amount_usd_m[bonds$country == "Mauritius"]),
  last_issue     = max(bonds$issue_date)
)

write_csv(by_year_label,   "output/tables/volume_by_year_label.csv")
write_csv(by_year,         "output/tables/volume_by_year.csv")
write_csv(by_sector,       "output/tables/use_of_proceeds.csv")
write_csv(by_country,      "output/tables/hubs_by_country.csv")
write_csv(by_issuer_type,  "output/tables/issuer_type.csv")
write_csv(fixed_coupons,   "output/tables/fixed_coupons.csv")
write_csv(spread_by_bucket,"output/tables/jibar_spread_by_tenor.csv")
write_csv(tenor_summary,   "output/tables/tenor_by_label.csv")
write_csv(maturity_ladder, "output/tables/maturity_ladder.csv")
write_csv(disclosure,      "output/tables/disclosure_quality.csv")
saveRDS(km, "output/tables/key_metrics.rds")
saveRDS(spread_model, "output/tables/spread_model.rds")

message(sprintf(
  "02_analysis: banks %.0f%% of volume; top use of proceeds = %s (%.0f%%); JIBAR spreads %d-%d bps.",
  100 * km$share_banks, km$top_sector, 100 * km$top_sector_share,
  km$spread_min, km$spread_max))
