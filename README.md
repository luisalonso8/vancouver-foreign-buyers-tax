# Did BC's Foreign Buyers' Tax change new-home prices in Vancouver?

A difference-in-differences / event-study analysis of the 15% Foreign Buyers' Tax that British Columbia introduced in Metro Vancouver on 2 August 2016.

 The goal is a clearly stated causal question, a defensible design, and honest reporting of what the data can and cannot say.

## Question

What was the effect of the 2016 Foreign Buyers' Tax (FBT) on new-home prices in Vancouver, relative to comparable Canadian metro areas that did not have the tax?

## Design

- **Outcome:** log of the New Housing Price Index (NHPI), monthly, by CMA. The NHPI is a Statistics Canada index of what builders charge for new homes (house and land), with a fixed base period equal to 100. Source: table 18-10-0205-01, pulled with the `cansim` R package.
- **Treated unit:** Vancouver CMA. A CMA (Census Metropolitan Area) is Statistics Canada's definition of a metro area: a large city plus the surrounding municipalities that are economically tied to it.
- **Controls:** CMAs outside BC and Ontario (Calgary, Edmonton, Saskatoon, Regina, Winnipeg, Halifax, and similar; the exact set is defined in `R/02_clean.R`).
- **Window:** January 2013 to March 2017. This ends before Ontario's own foreign buyers' tax (April 2017), so Toronto-area and other Ontario CMAs are excluded and the controls stay clean.
- **Excluded on purpose:** Victoria and other BC CMAs, because the tax was extended to more BC regions in 2018 and BC-wide spillovers are plausible.
- **Estimator:** event study with two-way fixed effects (CMA and month) using `fixest`, one coefficient per month relative to the month before the tax (reference period: July 2016).

## Glossary

- **FBT:** Foreign Buyers' Tax, a 15% additional property transfer tax on foreign buyers in Metro Vancouver, effective 2 August 2016.
- **NHPI:** New Housing Price Index (new homes only, not resale).
- **CMA:** Census Metropolitan Area.
- **DiD:** difference-in-differences.

## Known threats to validity

These are stated up front, not hidden.

1. **Parallel trends.** The key assumption. Pre-tax event-study coefficients are the main evidence for or against it.
2. **Alberta's 2015-2016 oil downturn.** Calgary and Edmonton may not follow Vancouver's pre-trend. Results are shown with and without Alberta controls.
3. **Federal mortgage stress test (October 2016).** It falls inside the post period and affects all CMAs, though not equally.
4. **Few clusters.** With a single treated unit and a handful of controls, cluster-robust standard errors are unreliable. Inference should be supplemented with randomization or placebo-in-space tests.
5. **NHPI measures new housing, not resale.** Results do not speak to the resale market.

## Repo layout

```
R/
  01_download.R     pull NHPI from Statistics Canada (cansim)
  02_clean.R        filter CMAs and window, build treatment and relative-month variables
  03_event_study.R  event study with fixest, saves figure and coefficients
reports/
  report.qmd        Quarto report (to be written)
data/raw/           downloaded data (not tracked)
data/processed/     analysis dataset (not tracked)
outputs/figures/    figures
```

## Reproducing

Requires R (4.3 or later) and Quarto.

```r
install.packages(c("cansim", "dplyr", "lubridate", "stringr", "fixest", "broom", "ggplot2", "renv"))
renv::init()   # first time only, then commit renv.lock

source("R/01_download.R")
source("R/02_clean.R")
source("R/03_event_study.R")
```

Then render the report:

```
quarto render reports/report.qmd
```

## Status

- [x] Repo scaffold
- [x] Download script
- [x] Cleaning script
- [x] Event-study script (first draft)
- [ ] Verify table and geography names against the live Statistics Canada table
- [ ] Parallel-trends check and robustness (alternative controls, shorter window, placebo date)
- [ ] Small-sample inference
- [ ] Quarto report and GitHub Pages
