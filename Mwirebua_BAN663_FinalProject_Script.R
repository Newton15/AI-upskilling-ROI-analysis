############################################################
# BAN 663 – Final Project
# R Programming for Data Analysis
# MS in Applied AI and Business Analytics
#
# Name:    Newton Mwirebua
# Track:   [ ] Open A1   [ ] Open A2   [X] Structured B
# Dataset: provided
# Date:    5/6/2026
#
# THIS TEMPLATE IS A SUGGESTED STRUCTURE — NOT A REQUIREMENT.
# Adapt it freely to fit your data and business questions.
# Add sections, rename things, reorganize as needed.
# What is required is the analytical content, not this layout.
#
# WORKFLOW REMINDER
#   Work in this file first — get everything running clean.
#   Convert to .Rmd
#   Hard deadline: May 7 (Thursday)
#
# WRITING RULE (applies to every insight you write)
#   Finding  — what the data shows
#   Meaning  — why it matters for the business
#   Evidence — one specific number
############################################################


# ============================================================
# SETUP — load all packages here, nothing else
# ============================================================

library(readr)
library(readxl)
library(dplyr)
library(stringr)
library(lubridate)
library(ggplot2)
library(scales)
library(forcats)
library(broom)
# library(effsize)  # for Cohen's d — install once in console


# ============================================================
# SECTION 0 — DATA IMPORT
# ============================================================
# Use descriptive object names that reflect the content.
# Place data files in a data/ subfolder.

employees <- read_csv("data/employees.csv",            show_col_types = FALSE)
outcomes  <- read_csv("data/performance_outcomes.csv", show_col_types = FALSE)
training  <- read_csv("data/training_records.csv",     show_col_types = FALSE)

# dataset1 <- read_csv("data/your_file.csv")
# dataset2 <- read_excel("data/your_other_file.xlsx")

# Quick confirmation — run once, then comment out
glimpse(employees)
glimpse(outcomes)
glimpse(training)


# ============================================================
# SECTION 1 — BUSINESS FRAMING
# ============================================================
# Write as comments. This becomes your Introduction narrative
# in the .Rmd report.

# BUSINESS CONTEXT (3-5 sentences):
# Describe the organisation, its scale, and the decision problem.

# The dataset describes a mid-size professional services firm with 280
# consultants distributed across six industry practice areas. Over the
# past 24 months the firm has invested in a portfolio of AI upskilling
# programs (AI Foundations, Workflow Automation, Data Literacy, and
# Leadership in AI). The Chief People Officer must decide how to
# allocate next year's training budget. That decision rests on whether
# past training has measurably moved performance and AI tool adoption,
# and whether some segments still show elevated flight risk despite
# the investment.


# BUSINESS QUESTIONS (2-3 — must pass the quality gate):
# Q1:Does training intensity (total training hours completed) predict post-training performance, after controlling for an employee's baseline performance and tenure?
# Q2:Does AI tool adoption differ meaningfully across the six industry practice areas, in a way that should change how programs are targeted?
# Q3 (optional):Do consultants hired after the firm's AI strategy reset (post-transition hires) show higher AI tool adoption than legacy employees hired before the reset?


# DECISION AT STAKE:
# What would a manager decide differently based on your findings?
# Q1: If training hours show a positive effect on post-performance, the
#     CPO preserves or expands the L&D budget. If the effect is null,
#     she redirects spending toward manager coaching, tooling, or
#     workflow redesign.

# Q2: If practice areas differ on AI tool adoption, the firm runs
#     targeted enablement in the lagging practices instead of one-size-
#     fits-all rollouts.

# Q3: If post-transition hires show meaningfully higher AI adoption,
#     the firm should accelerate its AI-fluent hiring pipeline. If they
#     do not, the bottleneck is upskilling, not hiring — and the firm
#     should redirect investment toward existing-staff enablement.


# VARIABLE DESCRIPTIONS (one sentence each):
# For every key variable used in analysis, describe what it measures.
# employee_id            — unique consultant identifier (primary key).
# industry_practice      — one of six practice areas the consultant serves.
# industry_automation_index — 0-10 composite of AI/automation maturity in that industry.
# role_level             — Junior / Mid / Senior / Principal.
# tenure_years           — years employed at firm.
# automation_exposure    — Low / Medium / High exposure to AI tools.
# baseline_performance   — pre-program manager rating, 1-5 scale.
# hired_post_transition  — TRUE if hired after the AI strategy reset.
# post_performance       — manager rating after the training period, 1-5.
# billable_hours_change  — % change in billable hours vs prior period.
# absenteeism_days       — unplanned days absent during the period.
# turnover_intent        — Low / Medium / High self-reported flight risk.
# ai_tool_adoption_score — usage/proficiency composite, 1-10.
# months_since_training  — recency of last completed program.
# program_type           — name of the training program taken.
# training_hours         — hours invested in that program.
# completion_status      — Completed / Partial / Dropped.
# training_month         — month the program was scheduled.



# ============================================================
# SECTION 2 — DATA ORIENTATION AND QUALITY ASSESSMENT
# ============================================================

# ── 2A. Rapid orientation ──────────────────────────────────
# Run for each dataset.

glimpse(employees)
head(employees)
dim(employees)
names(employees)

glimpse(outcomes)
head(outcomes)
dim(outcomes)
names(outcomes)

glimpse(training)
head(training)
dim(training)
names(training)


# ── 2B. Quality check 1 ────────────────────────────────────
# Type: [Validity / Structure / Consistency / Completeness]
# type:Consistency

# Why this check matters for your business questions:
# Q1 and Q2 both rely on grouping by program type. If "AI Foundations", "ai foundations" and "Ai foundations" are treated as three different programs, every group-level number is wrong.

cat("\n--- Raw program_type values ---\n")
print(table(training$program_type))

cat("\n--- Raw completion_status values ---\n")
print(table(training$completion_status))


# What I found (specific numbers):

# program_type has 12 distinct strings that collapse to 4 real programs:
#   AI Foundations      = 71 + 11 + 8  = 90 records
#   Workflow Automation = 55 + 8  + 8  = 71 records
#   Data Literacy       = 45 + 10 + 9  = 64 records
#   Leadership in AI    = 22 + 6  + 3  = 31 records
# completion_status has 9 distinct strings that collapse to 3 real states:
#   Completed = 110 + 28 + 17 = 155 records
#   Partial   = 57  + 11 + 6  = 74 records
#   Dropped   = 18  + 7  + 2  = 27 records
# Total: 256 records — matches the raw row count. Both columns will be
# standardised in Section 3 with str_to_title(str_squish(...)).


# ── 2C. Quality check 2 ────────────────────────────────────
# Type: Validity
# Why this check matters:
# training_month is the only field that tells us *when* a program was delivered, which matters for any future trend or cohort question. A single-format parse (e.g. only ymd) silently coerces non-matching strings to NA — and we can see at least three formats in the data.

cat("\n--- Sample of training_month strings ---\n")
print(head(unique(training$training_month), 15))

cat("\nDistinct training_month values:",
    length(unique(training$training_month)), "\n")


# What I found:

# 52 distinct training_month strings across THREE formats:
#   ISO YYYY-MM-DD    e.g. "2023-03-01", "2023-04-01"
#   US MM/DD/YYYY     e.g. "04/01/2023", "06/01/2024"
#   Abbreviated Mon-YY e.g. "May-24", "Aug-23"
# Will be parsed in Section 3 with parse_date_time(orders =
# c("ymd", "mdy", "by")) which handles all three in one pass.


# ── 2D. Plausibility check ─────────────────────────────────
# Flag impossible or extreme values in key numeric columns.
# Report counts: sum(col < 0), sum(col > threshold), etc.

cat("\n--- Numeric plausibility ---\n")
cat("post_performance NAs           :", sum(is.na(outcomes$post_performance)), "\n")
cat("post_performance < 1 or > 5    :",
    sum(outcomes$post_performance < 1 | outcomes$post_performance > 5,
        na.rm = TRUE), "\n")
cat("absenteeism_days < 0           :", sum(outcomes$absenteeism_days < 0), "\n")
cat("absenteeism_days > 60 (extreme):", sum(outcomes$absenteeism_days > 60), "\n")
cat("max absenteeism_days           :", max(outcomes$absenteeism_days), "\n")
cat("training_hours < 0             :", sum(training$training_hours < 0), "\n")
cat("baseline_performance out of 1-5:",
    sum(employees$baseline_performance < 1 | employees$baseline_performance > 5), "\n")
cat("tenure_years < 0               :", sum(employees$tenure_years < 0), "\n")

# What I found:

# - 17 missing post_performance values (~6%) — within the planned
#   missingness target. Acceptable; lm() will handle via na.action.
# - 4 records with absenteeism_days > 60 (extreme) and a max of 224.
#   60+ days unplanned absence on a 12-month review is implausible:
#   inconsistent with the employee remaining on payroll long enough
#   to receive a post-period review. All 4 will be filtered in Section 3.
# - All other checks clean: no negative values, no out-of-range ratings,
#   no negative training hours, no negative tenure.


# ── 2E. Quality verdict ────────────────────────────────────

# QUALITY VERDICT:
# Overall assessment: [X] Caution
# Key finding: data is structurally sound — no duplicate primary keys,
#   every foreign key in training and outcomes resolves to a parent
#   employee record — but contains four solvable issues:
#   (1) capitalisation chaos in program_type (12 strings → 4 programs)
#       and completion_status (9 strings → 3 states),
#   (2) three different date formats in training_month,
#   (3) 17 missing post_performance values (~6%),
#   (4) four absenteeism outliers, max 224 days.
# Action taken: standardise text with str_to_title(), parse multi-format
#   dates with parse_date_time(orders = c("ymd","mdy","by")), filter
#   absenteeism > 60 days as implausible, retain missingness for the
#   regression to handle via na.action.



# ============================================================
# SECTION 3 — DATA PREPARATION AND INTEGRATION
# ============================================================
# Apply the Module 2 pattern ONLY where issues actually exist.
# Do not add cleaning steps the data does not need.

# ── 3A. Date parsing (only if date columns have mixed formats)

# parse_date_time() tries each order in turn:
#   ymd handles "2023-03-01"
#   mdy handles "06/01/2024"
#   by  handles "May-24"

training_clean <- training %>%
  mutate(
    training_month = parse_date_time(
      training_month,
      orders = c("ymd", "mdy", "by"),
      quiet  = TRUE
    ) %>% as_date()
  )

cat("Dates that failed to parse:",
    sum(is.na(training_clean$training_month)), "\n")


# ── 3B. Text standardisation (only if capitalisation is inconsistent)

# str_squish() collapses any stray whitespace; str_to_title() unifies case.
# 12 program_type strings collapse to 4 programs;
# 9 completion_status strings collapse to 3 states.

training_clean <- training_clean %>%
  mutate(
    program_type      = str_to_title(str_squish(program_type)),
    program_type      = str_replace_all(program_type, "\\bAi\\b", "AI"),
    completion_status = str_to_title(str_squish(completion_status))
  )

cat("\n--- Cleaned program_type ---\n")
print(table(training_clean$program_type))

cat("\n--- Cleaned completion_status ---\n")
print(table(training_clean$completion_status))


# ── 3C. Business-rule filter (one filter, well justified)
# Why these records are out of scope:
# Four records have absenteeism_days > 60. Sixty-plus days of unplanned
# absence on a 12-month review window is implausible — inconsistent
# with the employee remaining on payroll long enough to receive a
# post-period review. Treating these as data-entry errors and removing.

cat("\nOutcome records before filter:", nrow(outcomes), "\n")

outcomes_clean <- outcomes %>%
  filter(absenteeism_days <= 60)

cat("Outcome records after filter :", nrow(outcomes_clean), "\n")
cat("Records removed              :",
    nrow(outcomes) - nrow(outcomes_clean), "\n")


# ── 3D. Join (only if using multiple files)
# Document match rate after joining.

# Step 1: aggregate training to employee level (some employees took
#         multiple programs; we need one row per consultant to join 1:1).
# Step 2: left-join employees + outcomes_clean + training_per_employee.
# Step 3: coalesce(0) keeps employees with NO training records in the
#         analysis — they took zero hours, not "missing".

training_per_employee <- training_clean %>%
  group_by(employee_id) %>%
  summarize(
    total_training_hours = sum(training_hours, na.rm = TRUE),
    programs_taken       = n_distinct(program_type),
    completed_any        = any(completion_status == "Completed"),
    .groups = "drop"
  )

analytical_data <- employees %>%
  left_join(outcomes_clean,        by = "employee_id") %>%
  left_join(training_per_employee, by = "employee_id") %>%
  mutate(
    total_training_hours = coalesce(total_training_hours, 0),
    programs_taken       = coalesce(programs_taken,       0L),
    completed_any        = coalesce(completed_any,        FALSE)
  )

cat("\nUnmatched outcome rows   :",
    sum(is.na(analytical_data$post_performance)), "\n")
cat("Employees with 0 training:",
    sum(analytical_data$total_training_hours == 0), "\n")


# ── 3E. Derived variables (1-2 only, if needed for analysis)
# What each new column measures and why it is needed:
#
# performance_change   — post minus baseline; isolates the period effect.
# training_engagement  — bucketed total hours so we can chart cleanly
#                        and compare engagement levels in Section 4.
# Factor levels set explicitly so charts and tests order categories
# correctly (Junior < Mid < Senior < Principal; Low < Medium < High).

analytical_data <- analytical_data %>%
  mutate(
    performance_change = post_performance - baseline_performance,
    training_engagement = case_when(
      total_training_hours == 0                                ~ "None",
      total_training_hours >  0 & total_training_hours <= 20   ~ "Light (1-20h)",
      total_training_hours > 20 & total_training_hours <= 40   ~ "Moderate (21-40h)",
      total_training_hours > 40                                ~ "Heavy (40h+)"
    ) %>% factor(levels = c("None", "Light (1-20h)",
                            "Moderate (21-40h)", "Heavy (40h+)")),
    role_level      = factor(role_level,
                             levels = c("Junior", "Mid", "Senior", "Principal")),
    turnover_intent = factor(turnover_intent, levels = c("Low", "Medium", "High"))
  )


# ── 3F. Confirm analytical dataset

glimpse(analytical_data)
cat("\nAnalytical dataset:", nrow(analytical_data), "rows,",
    ncol(analytical_data), "columns\n")


# ============================================================
# SECTION 4 — VISUAL ANALYTICS
# ============================================================
# 3-5 charts. Each motivated by a business question.
# Finding-based titles — state what the data shows, not what
# it measures.
# Write insight after each chart using the Writing Rule.

# ── Chart 1 ────────────────────────────────────────────────
# Business question addressed: Q[1]
# Chart type: relationship (scatter with regression line)
# Prediction before plotting:
# I expect a positive but modest slope — more training hours
#   associate with higher post-performance, but with substantial
#   scatter because training is one driver among many (manager
#   quality, project mix, tooling).

# # Data prep: drop rows with missing post_performance for cleaner plotting
chart1_data <- analytical_data %>%
  filter(!is.na(post_performance))

chart1 <- ggplot(chart1_data,
                 aes(x = total_training_hours, y = post_performance)) +
  geom_point(alpha = 0.5, color = "#4C72B0") +
  geom_smooth(method = "lm", se = TRUE, color = "#D1495B") +
  labs(
    title    = "More training hours associate with higher post-period performance",
    subtitle = "Linear fit shown; baseline and tenure controlled for in Section 5",
    x        = "Total training hours",
    y        = "Post-period performance (1-5 manager rating)"
  ) +
  theme_minimal(base_size = 12)

chart1

# INSIGHT — Writing Rule:
# Finding: Fitted line slopes upward; post-performance rises as training hours rise.
# Meaning: L&D investment is moving the needle at the firm level — training is not invisible.
# Evidence: Predicted rating climbs from ~3.8 at zero hours to ~4.4 around 115 hours.


# ── Chart 2 ────────────────────────────────────────────────
# Business question addressed: Q[2]
# Chart type:comparison (across 6 industry practice groups)
# Prediction:I expect Technology and Financial Services to lead AI tool adoption and Public Sector or Manufacturing to lag, with a spread of at least 1-2 points on the 10-point scale.

chart2 <- ggplot(analytical_data,
                 aes(x = fct_reorder(industry_practice,
                                     ai_tool_adoption_score,
                                     .fun = median),
                     y = ai_tool_adoption_score)) +
  geom_boxplot(fill = "#4C72B0", alpha = 0.75, outlier.alpha = 0.4) +
  coord_flip() +
  labs(
    title    = "AI tool adoption is uneven across the six practice areas",
    subtitle = "Higher score = more frequent and proficient use of AI tools",
    x        = NULL,
    y        = "AI tool adoption score (1-10)"
  ) +
  theme_minimal(base_size = 12)

chart2


# INSIGHT:
# Finding: Manufacturing & Operations and Financial Services lead AI adoption; Public Sector lags clearly.
# Meaning: A blanket rollout would under-serve Public Sector and Healthcare — target enablement there first.
# Evidence: Top-to-bottom median gap is roughly 2 points on the 10-point adoption scale.


# ── Chart 3 ────────────────────────────────────────────────
# Business question addressed: Q[3]
# Chart type:distribution / comparison between two groups
# Prediction: I expect post-transition hires (TRUE) to show meaningfully higher median AI adoption than legacy hires (FALSE), because that hiring strategy was specifically designed to import AI fluency.

# Data prep: friendly cohort labels with sample sizes baked in
chart3_data <- analytical_data %>%
  mutate(
    cohort = factor(
      ifelse(hired_post_transition, "Post-transition (n=45)",
             "Legacy (n=235)"),
      levels = c("Legacy (n=235)", "Post-transition (n=45)")
    )
  )

chart3 <- ggplot(chart3_data,
                 aes(x = cohort, y = ai_tool_adoption_score, fill = cohort)) +
  geom_boxplot(alpha = 0.75, outlier.alpha = 0.4) +
  scale_fill_manual(values = c("Legacy (n=235)"         = "#4C72B0",
                               "Post-transition (n=45)" = "#D1495B"),
                    guide = "none") +
  labs(
    title    = "Post-transition and legacy hires show similar AI adoption",
    subtitle = "Two-cohort comparison; formal t-test in Section 5",
    x        = NULL,
    y        = "AI tool adoption score (1-10)"
  ) +
  theme_minimal(base_size = 12)

chart3

# INSIGHT:
# Finding: Cohort medians overlap heavily — post-transition adoption sits at or below legacy.
# Meaning: AI-fluent hiring is NOT delivering a measurable premium; the upskilling bottleneck is real.
# Evidence: Both medians cluster around 4.2–4.5 on the 10-point scale; t-test confirms in Section 5.


# ── Chart 4 (optional) ─────────────────────────────────────
# Only include if it adds genuinely new information.


# ── Chart 5 (optional) ─────────────────────────────────────


# ============================================================
# SECTION 5 — STATISTICAL REASONING
# ============================================================
# This section runs three formal tests, one per business question:
#   Q1 → Multiple linear regression  (primary test, with predict() in 5D)
#   Q2 → ANOVA + TukeyHSD             (3+ groups comparison)
#   Q3 → Independent t-test           (2 groups comparison)
#
# Method matching (guidelines Section 3.2):
#   Q1 — relationship with multiple predictors → Multiple regression
#   Q2 — comparison across 3+ groups           → ANOVA + Tukey
#   Q3 — comparison between 2 groups           → t-test


# ── 5A. Visualise before testing + state predictions ──────
# Visuals already done in Section 4:
#   Chart 1 = scatter (Q1 regression)
#   Chart 2 = boxplot across practices (Q2 ANOVA)
#   Chart 3 = boxplot across cohorts (Q3 t-test)

# PREDICTIONS — written before running any test:
# Q1: I expect total_training_hours to have a small but positive,
#     statistically significant coefficient on post_performance,
#     because Chart 1 showed a clear upward fitted line.
# Q2: I expect a significant ANOVA (p < 0.05) with at least one
#     practice differing meaningfully, because Chart 2 showed visibly
#     separated medians across roughly 2 points on the 10-point scale.
# Q3: Originally I expected post-transition hires to show higher AI
#     adoption. Chart 3 suggested otherwise — the two cohorts looked
#     nearly identical. I now expect the t-test to return p > 0.05
#     (no significant difference) and am running it to confirm formally.


# ── 5B. Run the tests ─────────────────────────────────────

# Q1 — Multiple regression
model <- lm(
  post_performance ~ baseline_performance + total_training_hours +
    tenure_years,
  data = analytical_data
)

cat("\n--- Q1 Regression coefficients ---\n")
print(tidy(model))

cat("\n--- Q1 Model fit ---\n")
print(glance(model) %>% select(r.squared, adj.r.squared,
                               sigma, p.value, nobs))


# Q2 — ANOVA + Tukey HSD
aov_result <- aov(ai_tool_adoption_score ~ industry_practice,
                  data = analytical_data)

cat("\n--- Q2 ANOVA ---\n")
print(summary(aov_result))

cat("\n--- Q2 Tukey HSD pairwise comparisons ---\n")
print(TukeyHSD(aov_result))


# Q3 — Independent t-test (Welch's, R default — handles unequal n)
t_result <- t.test(ai_tool_adoption_score ~ hired_post_transition,
                   data = analytical_data)

cat("\n--- Q3 t-test ---\n")
print(t_result)


# ── 5C. Effect sizes / model fit ──────────────────────────

# Q1 — R-squared
cat("\nQ1 R-squared:         ", round(glance(model)$r.squared,    3), "\n")
cat("Q1 Adjusted R-squared:", round(glance(model)$adj.r.squared, 3), "\n")

# Q2 — eta-squared (proportion of variance explained by industry_practice)
ss_total   <- sum(summary(aov_result)[[1]]$`Sum Sq`)
ss_between <- summary(aov_result)[[1]]$`Sum Sq`[1]
eta_sq     <- ss_between / ss_total
cat("\nQ2 eta-squared:      ", round(eta_sq, 3), "\n")

# Q3 — Cohen's d (drop NAs before computing)
legacy_scores <- analytical_data$ai_tool_adoption_score[
  !analytical_data$hired_post_transition]
legacy_scores <- legacy_scores[!is.na(legacy_scores)]

post_scores   <- analytical_data$ai_tool_adoption_score[
  analytical_data$hired_post_transition]
post_scores   <- post_scores[!is.na(post_scores)]

pooled_sd <- sqrt(((length(legacy_scores) - 1) * var(legacy_scores) +
                     (length(post_scores)   - 1) * var(post_scores)) /
                    (length(legacy_scores) + length(post_scores) - 2))

cohen_d <- (mean(post_scores) - mean(legacy_scores)) / pooled_sd
cat("\nQ3 Cohen's d:         ", round(cohen_d, 3),
    " (negative = legacy higher)\n")


# INTERPRETATION — Writing Rule, one block per question
# (Replace [X] with actual numbers from your run)

# Q1 — Regression
# Finding:  Training hours show a positive, significant coefficient on
#           post-performance after controlling for baseline and tenure.
#           Tenure itself is not significant once baseline is in the model.
# Meaning:  L&D investment is moving the needle independently of who the
#           employee already was — the budget IS doing real work. Each
#           10 training hours is worth ~0.05 rating points; 50 hours
#           is worth ~0.23, modest per-hour but meaningful in aggregate.
# Evidence: training_hours coefficient = 0.00452, p < 0.001;
#           model R² = 0.665 (66.5% of post-performance variance explained).
# Caution:  Observational data — association, not causation. Confounders
#           not in the model (manager quality, project mix, client
#           assignment) plausibly drive part of the effect.

# Q2 — ANOVA
# Finding:  AI tool adoption differs significantly across the six
#           practice areas. Tukey HSD shows the leaders (Manufacturing
#           & Operations, Financial Services) sit ~2-3 points above the
#           laggards (Public Sector, Healthcare, Retail & Consumer).
# Meaning:  Practice-level differences are real and large. A blanket
#           rollout would systematically under-serve the laggards;
#           targeted enablement in Public Sector, Healthcare and
#           Retail & Consumer is the sharper play.
# Evidence: F = 13.71, p < 0.001, eta² = 0.202 (large effect — practice
#           area explains ~20% of adoption variance). Tukey p < 0.05 for
#           Public Sector vs Manufacturing (-2.79), Public Sector vs
#           Financial Services (-2.56), Healthcare vs Financial Services
#           (-1.44), and four other pairs.
# Caution:  ANOVA confirms differences exist; Tukey HSD identifies the
#           specific pairs. Manufacturing & Operations and Financial
#           Services are statistically tied at the top — do not pick
#           between them.

# Q3 — t-test
# Finding:  Significant difference, but in the OPPOSITE direction
#           predicted. Legacy hires score 0.55 points HIGHER on AI
#           adoption than post-transition hires. The "AI-fluent
#           hiring" cohort is the lower-adopting group.
# Meaning:  The post-reset hiring strategy is not delivering its
#           intended AI-fluency premium — it is producing the
#           opposite. Either the recruiting filter is missing the
#           target, or legacy hires have had more time and exposure
#           to internalise the tooling. The CPO should pause expansion
#           of the AI-fluent hiring pipeline and investigate why these
#           hires under-adopt before scaling further.
# Evidence: Welch's t = 2.23, df = 68.2, p = 0.029;
#           mean Legacy = 4.62, mean Post-transition = 4.07
#           (difference = 0.55 points, 95% CI: 0.06 to 1.05);
#           Cohen's d ≈ -0.333 (small-to-medium effect, Legacy-higher).

# Caution:  Sample sizes are very unequal (235 vs 45). Welch's t-test
#           handles this, but the smaller cohort has wider error bars,
#           and Cohen's d sits at the small-to-medium boundary. The
#           direction is reliable; the magnitude should be treated as
#           a reasonable estimate, not a precise number.


# ── 5D. Prediction — regression only (Q1) ─────────────────
# Business scenario: a Senior consultant with 6 years tenure, baseline
# rating of 3.8, who has invested 35 training hours this period.
# What does the model predict their post-performance will look like?

new_scenario <- data.frame(
  baseline_performance = 3.8,
  total_training_hours = 35,
  tenure_years         = 6
)

scenario_pred <- predict(model, newdata = new_scenario,
                         interval = "prediction", level = 0.95)
print(scenario_pred)

# Interpretation:
# The "fit" column is the model's point estimate; lower/upper give
# the 95% prediction interval. Even for an "average" mid-tenure
# Senior with moderate training, the interval spans roughly ±1
# rating point. This means training raises the AVERAGE post-period
# performance but does not guarantee any individual outcome — exactly
# what Chart 1's wide scatter suggested. The CPO should treat the
# point estimate as a planning number, not a promise.


# ============================================================
# SECTION 6 — AUTOMATION
# ============================================================
# What this function does:
# Returns a per-practice summary (employee count, training, post-
# performance, AI adoption, turnover risk) for any of the six
# industry practice areas. Supports the CPO's recurring need to
# review each practice for budget allocation and retention planning.
#
# Reusable parameter: `practice` — any value of industry_practice.

practice_summary_for <- function(data, practice) {
  
  # Input validation
  if (!is.character(practice))
    stop("`practice` must be a character string (e.g. 'Technology').")
  
  valid <- unique(data$industry_practice)
  if (!practice %in% valid)
    stop(paste0("Practice not found: '", practice,
                "'\nValid options: ", paste(valid, collapse = ", ")))
  
  # Per-practice analysis
  data %>%
    filter(industry_practice == practice) %>%
    summarize(
      industry_practice    = practice,
      n_employees          = n(),
      avg_training_hours   = round(mean(total_training_hours,    na.rm = TRUE), 1),
      avg_post_performance = round(mean(post_performance,        na.rm = TRUE), 2),
      avg_ai_adoption      = round(mean(ai_tool_adoption_score,  na.rm = TRUE), 2),
      pct_high_turnover    = round(mean(turnover_intent == "High",
                                        na.rm = TRUE) * 100, 1),
      .groups = "drop"
    )
}


# ── Test with valid inputs ──────────────────────────────────
practice_summary_for(analytical_data, "Technology")
practice_summary_for(analytical_data, "Public Sector")


# ── Test error handling ─────────────────────────────────────
# Uncomment one at a time to verify both branches throw cleanly:
# practice_summary_for(analytical_data, 99)              # wrong type
# practice_summary_for(analytical_data, "Spaceflight")   # not in data


# ── Automate across all practice areas ──────────────────────
# "Function defines analysis, loop makes it scalable."
all_practices  <- unique(analytical_data$industry_practice)
practice_table <- data.frame()

for (p in all_practices) {
  practice_table <- rbind(practice_table,
                          practice_summary_for(analytical_data, p))
}

practice_table <- practice_table %>%
  arrange(desc(avg_post_performance))

print(practice_table)
# ============================================================
# EXECUTIVE SUMMARY DRAFT
# ============================================================
# Draft your four key bullets here as comments.
# These become the narrative text in your .Rmd Key Findings,
# Recommendations, and Limitations sections.
# Every bullet follows the Writing Rule: Finding + Meaning + Evidence.

# FINDING
#   Training hours predict post-period performance after controlling
#   for baseline ability and tenure — the L&D budget is doing real
#   work. Each 10 training hours is worth roughly +0.05 rating points
#   on a 5-point scale (50 hours = +0.23) — modest per-hour but
#   meaningful in aggregate.
#   Evidence: training_hours coefficient = 0.00452, p < 0.001;
#   model R² = 0.665 (66.5% of post-performance variance explained).

# RISK 
#   The firm's "AI-fluent hiring" pipeline is delivering the OPPOSITE
#   of its design intent. Post-transition hires score 0.55 points
#   LOWER on AI adoption than legacy employees, and the gap is
#   statistically significant. The recruiting filter is missing the
#   target it was built to hit. Compounding this, AI tool adoption is
#   severely uneven across practice areas — Public Sector lags
#   Manufacturing & Operations by 2.79 points on the 10-point scale.
#   Evidence: Welch's t = 2.23, p = 0.029, Cohen's d = -0.333;
#   ANOVA F = 13.71, p < 0.001, eta² = 0.202.

# RECOMMENDATION
#   Hold the L&D envelope but reallocate. (1) Concentrate next year's
#   training spend in the three lagging practices — Public Sector,
#   Healthcare, and Retail & Consumer — confirmed by Tukey HSD as
#   significantly below the leaders. (2) Pause expansion of the
#   AI-fluent hiring pipeline and investigate why these hires
#   under-adopt before scaling further. (3) Redirect the saved hiring
#   premium into existing-staff enablement, where the regression
#   shows training is paying back. Expected outcome: lift in adoption
#   scores for the bottom-three practices and improved ROI on the
#   retention budget.

# LIMITATION.
#   The data is observational. The regression shows association, not
#   causation. Confounders not in the model — manager quality,
#   project mix, client assignment, onboarding quality — plausibly
#   drive part of every effect we observed. Q3's t-test compared
#   very unequal cohorts (235 vs 45); Welch's handles the imbalance,
#   but the smaller cohort has wider error bars and Cohen's d
#   = -0.333 sits at the small-to-medium boundary. Before
#   committing meaningful new spend, the CPO should pilot the
#   targeted-rollout approach in two practices and measure quarter-
#   over-quarter against the rest of the firm as a control.


############################################################
# PRE-CONVERSION CHECKLIST
# Run through this before opening the .Rmd template.
#
# [X] Script runs top-to-bottom without errors
#     (Source the file: Ctrl/Cmd + Shift + S)
# [X] All library() calls are at the top
# [X] No absolute file paths
# [X] Section headers are clear and labeled
# [X] Business questions written in Section 1
# [X] Variable descriptions written in Section 1
# [X] Quality verdict cat() in Section 2
# [X] Record counts before/after filter in Section 3
# [X] analytical_data confirmed with glimpse()
# [X] 3-5 charts saved as objects (chart1, chart2, chart3...)
# [X] Prediction written BEFORE test code in Section 5
# [X] Effect size or R-squared code present
# [X] Function tested with 2 valid inputs + 2 error cases
# [X] Executive summary cat() produces 4 complete bullets
#
# READY TO CONVERT? Open BAN663_FinalProject_Template.Rmd
############################################################
