# Clean simulated raptor ringing data for the student exercise in the ggplot2 block
# Creates one table of individual birds (2019 to 2024)

library(tidyverse)
library(lubridate)

set.seed(123)

dir.create("workshop_data", showWarnings = FALSE)

# Species parameters: base ringing rate, male wing length (mm) and male weight (g)
raptor_pars <- tibble(
  species = c("Common buzzard", "Eurasian sparrowhawk", "Common kestrel",
              "Northern goshawk", "Red kite", "Western marsh harrier"),
  base = c(1.2, 0.8, 1.0, 0.4, 0.5, 0.6),
  mean_wing = c(370, 200, 240, 320, 500, 390),
  sd_wing = c(12, 7, 7, 12, 14, 10),
  mean_wt = c(800, 150, 190, 800, 950, 600)
)

# Juveniles have slightly shorter wings
raptor_age_pars <- tibble(
  age = c("juvenile", "adult"),
  age_mult = c(0.97, 1)
)

# Monthly mean temperature with a seasonal cycle
monthly_temp <- tibble(
  date = seq(ymd("2019-01-01"), ymd("2024-12-01"), by = "month")
) %>%
  mutate(
    year = year(date),
    month = month(date),
    mean_temp_c = round(9 + 10 * sin(2 * pi * (month - 4) / 12) + rnorm(n(), 0, 1), 1)
  )

# Monthly ringing per habitat and species (used only to generate the individual records)
# Two migration peaks (spring and autumn), red kite increasing, kestrel declining,
# marsh harrier only in wetlands and only in summer (useful for facets)
ringing_monthly <- monthly_temp %>%
  crossing(
    habitat = c("forest", "farmland", "wetland", "mountain"),
    species = raptor_pars$species
  ) %>%
  left_join(raptor_pars, by = "species") %>%
  mutate(
    habitat_effect = case_when(
      habitat == "wetland" & species == "Western marsh harrier" ~ 4,
      species == "Western marsh harrier" ~ 0.2,
      habitat == "farmland" & species %in% c("Common buzzard", "Common kestrel", "Red kite") ~ 2,
      habitat == "forest" & species %in% c("Northern goshawk", "Eurasian sparrowhawk") ~ 2,
      habitat == "forest" & species == "Common buzzard" ~ 1.4,
      habitat == "mountain" & species == "Red kite" ~ 0.4,
      TRUE ~ 1
    ),
    season_effect = case_when(
      species == "Western marsh harrier" & month %in% 5:9 ~ 2,
      species == "Western marsh harrier" ~ 0,
      TRUE ~ 1 + 0.6 * sin(2 * pi * (month - 2) / 6)
    ),
    year_effect = case_when(
      species == "Red kite" ~ 1 + 0.10 * (year - 2019),
      species == "Common kestrel" ~ 1 - 0.05 * (year - 2019),
      TRUE ~ 1
    ),
    ringed = rpois(n(), base * habitat_effect * season_effect * year_effect)
  ) %>%
  select(date, year, month, habitat, species, ringed, mean_temp_c)

# Individual birds, expanded from the monthly counts
# Females are larger than males (typical for raptors), weight follows wing length
raptors <- ringing_monthly %>%
  uncount(ringed) %>%
  left_join(raptor_pars, by = "species") %>%
  mutate(
    date = date + sample(0:27, n(), replace = TRUE),
    sex = sample(c("M", "F"), n(), replace = TRUE),
    age = sample(raptor_age_pars$age, n(), replace = TRUE, prob = c(0.4, 0.6))
  ) %>%
  left_join(raptor_age_pars, by = "age") %>%
  mutate(
    wing_length_mm = round(
      rnorm(n(), mean_wing * age_mult * if_else(sex == "F", 1.06, 1), sd_wing)
    ),
    temp_c = round(mean_temp_c + rnorm(n(), 0, 3), 1),
    weight_g = round(
      mean_wt * (wing_length_mm / mean_wing)^3 * (1 + 0.003 * (10 - temp_c)) *
        rnorm(n(), 1, 0.05)
    )
  ) %>%
  arrange(date) %>%
  mutate(id = row_number()) %>%
  select(id, date, year, month, habitat, species, sex, age,
         wing_length_mm, weight_g, temp_c)

write_csv(raptors, "workshop_data/exercise_raptors_individuals.csv")
