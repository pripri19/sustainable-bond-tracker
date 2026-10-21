# Sustainable Infrastructure Bond Tracker (R)

A sourced database and R analysis of **green, social, sustainability and sustainability-linked corporate bonds** issued in African and Indian Ocean financial hubs (October 2021 to October 2026), feeding a **3-page strategic proposal** on how a commercial bank should structure its next sustainable lending framework. Built with `dplyr` and `ggplot2`; reports rendered with R Markdown.

## 👉 [View the live report](https://pripri19.github.io/sustainable-bond-tracker/) · [Read the 3-page proposal](https://pripri19.github.io/sustainable-bond-tracker/sustainable-bond-tracker/output/strategic_proposal.html)

No installation needed. Just click the links above.

> Project files (code, data, outputs) are in the [`sustainable-bond-tracker/`](sustainable-bond-tracker/) folder.

![Issuance by year](sustainable-bond-tracker/output/figures/fig1_volume_by_year.png)

## Key findings

| | |
|---|---|
| **Coverage** | 43 labelled bonds, 25 issuers, 12 markets, about USD 3.2bn |
| **Who issues** | Banks issue about 61% of volume, mostly multi-sector portfolio bonds |
| **Deepest hub** | Johannesburg (JSE): about 49% of volume, all four labels, transparent FRN pricing |
| **Coupons** | Fixed coupons of 5.5% to 13.5% follow the local currency curve, not the label |
| **Spreads** | JSE labelled FRNs: about +11 bps per extra year of tenor over 3M JIBAR |
| **Gaps** | Water infrastructure (1 deal), sustainability-linked structures (2 deals), patchy pricing disclosure |

![Use of proceeds](sustainable-bond-tracker/output/figures/fig2_use_of_proceeds.png)
![Spread vs tenor](sustainable-bond-tracker/output/figures/fig4_jibar_spread_tenor.png)

## Deliverables

- [Strategic proposal (PDF)](sustainable-bond-tracker/output/strategic_proposal.pdf), 3 pages, committee-ready
- [Full report (live web page)](https://pripri19.github.io/sustainable-bond-tracker/)
- [Bond register with source links (CSV)](sustainable-bond-tracker/data/raw/bonds_raw.csv)
- [Project details, data dictionary and limitations](sustainable-bond-tracker/README.md)

## How to run it yourself (optional, for R users)

1. Install [R](https://cran.r-project.org) and [RStudio Desktop](https://posit.co/download/rstudio-desktop).
2. Click **Code → Download ZIP** on this page and unzip it.
3. Open the `sustainable-bond-tracker` folder and double-click `sustainable-bond-tracker.Rproj`.
4. Open `run_all.R` and click **Source**. Missing packages install automatically; outputs are written to `output/`.

*Compiled from public sources for research and illustration. Not investment advice.*
