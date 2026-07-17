# AI Upskilling ROI at a Mid-Size Professional Services Firm

An R data analysis project that measures whether a firm's investment in **AI upskilling programs** and **AI-focused hiring** actually paid off — in employee performance and AI tool adoption.

Built for **BAN 663 – Final Project**, using R and R Markdown.

---

## Business Context

A mid-size professional services firm with **280 consultants** across six industry practice areas has spent 24 months investing in AI training programs (AI Foundations, Workflow Automation, Data Literacy, Leadership in AI) and has started hiring "AI-fluent" consultants. The Chief People Officer now has to decide how to spend next year's training and hiring budget. This project analyzes the data to guide that decision.

---

## Business Questions

1. **Does training pay off?** Does the number of training hours predict better post-training performance, after accounting for an employee's starting ability and tenure?
2. **Is AI adoption uneven?** Does AI tool adoption differ across the six practice areas in a way that should change how programs are targeted?
3. **Is AI-fluent hiring working?** Do consultants hired under the new AI strategy adopt AI tools more than employees hired before it?

---

## Key Findings

| Question | Method | Result |
|---|---|---|
| Q1 – Training effect | Multiple linear regression | Training hours **do** predict higher performance (coef = 0.00452, p < 0.001). Model explains 66.5% of variance (R² = 0.665). |
| Q2 – Practice differences | ANOVA + Tukey HSD | Adoption differs **significantly** (F = 13.71, p < 0.001). Manufacturing & Operations and Financial Services lead; Public Sector lags by 2.5–2.8 points. |
| Q3 – Hiring cohorts | Welch's t-test | Significant — but **opposite** to expectation. Legacy hires adopt AI *more* than post-transition hires (t = 2.23, p = 0.029). |

**Bottom line for the CPO:**
- Keep the training budget, but **redirect it toward the lagging practices** (Public Sector, Healthcare, Retail & Consumer).
- **Pause** the AI-fluent hiring pipeline and investigate why those hires are under-adopting.
- Move the saved hiring money into **training existing staff**, since training demonstrably works.

---

## What the Project Does

1. **Data quality assessment** – catches messy real-world problems: 12 different spellings of 4 program names, 3 different date formats, 6% missing performance scores, and a handful of impossible absenteeism values.
2. **Data preparation** – standardizes text, parses all three date formats in one pass, filters outliers, and joins three tables on `employee_id`.
3. **Visual analytics** – three charts, each answering one business question, with a prediction stated *before* plotting.
4. **Statistical testing** – regression, ANOVA with Tukey HSD, and Welch's t-test, chosen to match each question.
5. **Automation** – a reusable function that produces a per-practice summary (with input validation) so the analysis can be re-run each quarter for any practice area.

---

## Tech Stack

**R**, with:
- `readr`, `dplyr`, `stringr`, `lubridate` – data loading and cleaning
- `ggplot2`, `scales`, `forcats` – visualization
- `broom` – tidy model output

---

## Data

Three linked tables:

| Table | Rows | What it holds |
|---|---|---|
| `employees.csv` | 280 | One row per consultant — practice area, role, tenure, baseline performance, hiring cohort |
| `performance_outcomes.csv` | 280 | Post-period results — performance, billable hours change, absenteeism, AI adoption score |
| `training_records.csv` | 256 | One row per program completed — program type, hours, completion status, month |

> The data is fictional and was supplied for the course.

---

## Repository Contents

```
.
├── data/
│   ├── employees.csv
│   ├── performance_outcomes.csv
│   └── training_records.csv
├── Mwirebua_BAN663_FinalProject_Final.Rmd     # main analysis (R Markdown)
├── Mwirebua_BAN663_FinalProject_Script.R      # standalone R script
├── Mwirebua_BAN663_FinalProject_Final.docx    # knitted report
└── README.md
```

---

## How to Run It

1. Open the project in **RStudio**.
2. Make sure the three CSV files are inside a folder named `data` (the code reads from `data/employees.csv`, etc.).
3. Install the required packages if you don't have them:
   ```r
   install.packages(c("readr","dplyr","stringr","lubridate",
                      "ggplot2","scales","forcats","broom"))
   ```
4. Open `Mwirebua_BAN663_FinalProject_Final.Rmd` and click **Knit** to reproduce the full report, or run `Mwirebua_BAN663_FinalProject_Script.R` line by line.

---

## Author

**Newton Mwirebua**
BAN 663 – Final Project
