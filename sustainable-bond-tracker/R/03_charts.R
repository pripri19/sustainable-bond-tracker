# -----------------------------------------------------------------------------
# 03_charts.R — ggplot2 figures
# Output: output/figures/*.png
# -----------------------------------------------------------------------------

source("R/00_setup.R")
bonds <- readRDS("data/processed/bonds_clean.rds")
dir.create("output/figures", showWarnings = FALSE, recursive = TRUE)

save_fig <- function(plot, name, w = 8, h = 4.8) {
  ggsave(file.path("output/figures", paste0(name, ".png")), plot,
         width = w, height = h, dpi = 200, bg = "white")
}

usd_lab <- label_dollar(suffix = "m", accuracy = 1)

# Fig 1: issuance volume by year and label -----------------------------------
p1 <- bonds %>%
  count(issue_year, label, wt = amount_usd_m, name = "usd_m") %>%
  ggplot(aes(factor(issue_year), usd_m, fill = label)) +
  geom_col(width = 0.7) +
  scale_fill_manual(values = LABEL_COLOURS, drop = FALSE) +
  scale_y_continuous(labels = usd_lab, expand = expansion(c(0, 0.05))) +
  labs(title = "Labelled issuance by year",
       subtitle = "USD equivalent (m), October 2021 to October 2026 (2021 and 2026 are part-years)",
       x = NULL, y = NULL, caption = SOURCE_CAPTION) +
  theme_tracker()
save_fig(p1, "fig1_volume_by_year")

# Fig 2: use of proceeds -----------------------------------------------------
p2 <- bonds %>%
  group_by(use_of_proceeds) %>%
  summarise(usd_m = sum(amount_usd_m), deals = n(), .groups = "drop") %>%
  mutate(use_of_proceeds = fct_reorder(use_of_proceeds, usd_m)) %>%
  ggplot(aes(usd_m, use_of_proceeds)) +
  geom_col(fill = "#0072B2", width = 0.65) +
  geom_text(aes(label = paste0(deals, ifelse(deals == 1, " deal", " deals"))),
            hjust = -0.1, size = 3.2, colour = "grey30") +
  scale_x_continuous(labels = usd_lab, expand = expansion(c(0, 0.18))) +
  labs(title = "Where the capital goes: use of proceeds",
       subtitle = "USD equivalent (m); 'multi-sector' = bank/NBFI portfolio bonds",
       x = NULL, y = NULL, caption = SOURCE_CAPTION) +
  theme_tracker() +
  theme(panel.grid.major.y = element_blank(),
        panel.grid.major.x = element_line(colour = "grey90"))
save_fig(p2, "fig2_use_of_proceeds")

# Fig 3: fixed coupons by market ---------------------------------------------
fixed <- bonds %>%
  filter(!is.na(coupon_pct)) %>%
  mutate(lab = paste0(short_issuer(issuer), " (", currency, ", ",
                      ifelse(is.na(tenor_years), "?", tenor_years), "y)"),
         lab = fct_reorder(lab, coupon_pct))
p3 <- ggplot(fixed, aes(coupon_pct, lab, colour = label)) +
  geom_segment(aes(x = 0, xend = coupon_pct, yend = lab), colour = "grey80") +
  geom_point(size = 3.5) +
  geom_point(data = filter(fixed, !is.na(step_up_coupon_pct)),
             aes(x = step_up_coupon_pct), shape = 1, size = 3.5) +
  geom_text(aes(x = pmax(coupon_pct, step_up_coupon_pct, na.rm = TRUE) + 0.5,
                label = ifelse(is.na(step_up_coupon_pct),
                               sprintf("%.2f%%", coupon_pct),
                               sprintf("%.2f%% -> %.2f%%", coupon_pct,
                                       step_up_coupon_pct))),
            hjust = 0, size = 3.2, show.legend = FALSE) +
  scale_colour_manual(values = LABEL_COLOURS, drop = TRUE) +
  scale_x_continuous(labels = label_percent(scale = 1),
                     limits = c(0, 17), expand = expansion(c(0, 0))) +
  labs(title = "Fixed coupons track the local sovereign curve, not the label",
       subtitle = "Fixed-rate deals with disclosed coupons; hollow circle = Access Bank step-up coupon",
       x = "Coupon", y = NULL, caption = SOURCE_CAPTION) +
  theme_tracker() +
  theme(panel.grid.major.y = element_blank(),
        panel.grid.major.x = element_line(colour = "grey90"))
save_fig(p3, "fig3_fixed_coupons", h = 4.4)

# Fig 4: JIBAR spread vs tenor (South African FRNs) --------------------------
frn <- bonds %>%
  filter(reference_rate == "3M JIBAR", !is.na(spread_bps), !is.na(tenor_years))
p4 <- ggplot(frn, aes(tenor_years, spread_bps)) +
  geom_smooth(data = filter(frn, capital_rank == "Senior"), method = "lm",
              formula = y ~ x, se = FALSE, colour = "grey60",
              linetype = "dashed", linewidth = 0.6) +
  geom_point(aes(colour = label, shape = capital_rank), size = 3.4,
             alpha = 0.9) +
  scale_colour_manual(values = LABEL_COLOURS, drop = TRUE) +
  scale_shape_manual(values = c("Senior" = 16, "Tier 2" = 17)) +
  scale_x_continuous(breaks = c(3, 5, 7, 10)) +
  labs(title = "South African labelled FRNs: spread over 3M JIBAR by tenor",
       subtitle = "Dashed line = OLS fit on senior notes; triangles = Tier 2 capital notes",
       x = "Tenor (years)", y = "Spread (bps)", caption = SOURCE_CAPTION) +
  theme_tracker() +
  theme(panel.grid.major.x = element_line(colour = "grey92"))
save_fig(p4, "fig4_jibar_spread_tenor")

# Fig 5: maturity ladder -----------------------------------------------------
p5 <- bonds %>%
  filter(!is.na(maturity_year)) %>%
  count(maturity_year, label, wt = amount_usd_m, name = "usd_m") %>%
  ggplot(aes(factor(maturity_year), usd_m, fill = label)) +
  geom_col(width = 0.7) +
  scale_fill_manual(values = LABEL_COLOURS, drop = FALSE) +
  scale_y_continuous(labels = usd_lab, expand = expansion(c(0, 0.05))) +
  labs(title = "Maturity ladder: the refinancing pipeline",
       subtitle = "USD equivalent (m) by maturity year; deals with disclosed maturity only",
       x = NULL, y = NULL, caption = SOURCE_CAPTION) +
  theme_tracker()
save_fig(p5, "fig5_maturity_ladder")

# Fig 6: hub x label matrix --------------------------------------------------
p6 <- bonds %>%
  count(country, label) %>%
  mutate(country = fct_reorder(country, n, .fun = sum)) %>%
  ggplot(aes(label, country, fill = label)) +
  geom_tile(aes(alpha = n), colour = "white", linewidth = 1) +
  geom_text(aes(label = n), size = 3.6) +
  scale_fill_manual(values = LABEL_COLOURS, guide = "none") +
  scale_alpha(range = c(0.35, 1), guide = "none") +
  labs(title = "Deal count by market and label",
       x = NULL, y = NULL, caption = SOURCE_CAPTION) +
  theme_tracker() +
  theme(panel.grid = element_blank())
save_fig(p6, "fig6_market_label_matrix", w = 7, h = 4.8)

message("03_charts: 6 figures saved to output/figures/")
