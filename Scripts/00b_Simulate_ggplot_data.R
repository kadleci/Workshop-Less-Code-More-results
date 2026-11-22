# raptor ringing data for the workshop
# clean version for the ggplot exercise, dirty version for the cleaning task

library(tidyverse)
library(lubridate)

set.seed(123)

dir.create("workshop_data", showWarnings = FALSE)
dir.create("workshop_data/instructor", showWarnings = FALSE)

## params ----
# wing in mm, weight in g (males)
raptor_pars <- tibble(
  species = c("Common buzzard", "Eurasian sparrowhawk", "Common kestrel",
              "Northern goshawk", "Red kite", "Western marsh harrier"),
  base = c(1.2, 0.8, 1.0, 0.4, 0.5, 0.6),
  mean_wing = c(370, 200, 240, 320, 500, 390),
  sd_wing = c(12, 7, 7, 12, 14, 10),
  mean_wt = c(800, 150, 190, 800, 950, 600)
)

raptor_age_pars <- tibble(
  age = c("juvenile", "adult"),
  age_mult = c(0.97, 1)
)

monthly_temp <- tibble(
  date = seq(ymd("2019-01-01"), ymd("2024-12-01"), by = "month")
) %>%
  mutate(
    year = year(date),
    month = month(date),
    mean_temp_c = round(9 + 10 * sin(2 * pi * (month - 4) / 12) + rnorm(n(), 0, 1), 1)
  )

## monthly counts ----
# not exported, just for generating the birds
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
    # spring + autumn peak, harrier only in summer
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

## individuals ----
raptors <- ringing_monthly %>%
  uncount(ringed) %>%
  left_join(raptor_pars, by = "species") %>%
  mutate(
    date = date + sample(0:27, n(), replace = TRUE),
    sex = sample(c("M", "F"), n(), replace = TRUE),
    age = sample(raptor_age_pars$age, n(), replace = TRUE, prob = c(0.4, 0.6)),
    # two stations per habitat
    site_id = case_when(
      habitat == "forest" ~ sample(c("R01", "R02"), n(), replace = TRUE),
      habitat == "farmland" ~ sample(c("R03", "R04"), n(), replace = TRUE),
      habitat == "wetland" ~ sample(c("R05", "R06"), n(), replace = TRUE),
      TRUE ~ sample(c("R07", "R08"), n(), replace = TRUE)
    )
  ) %>%
  left_join(raptor_age_pars, by = "age") %>%
  mutate(
    wing_length_mm = round(
      rnorm(n(), mean_wing * age_mult * if_else(sex == "F", 1.06, 1), sd_wing)   # females bigger
    ),
    temp_c = round(mean_temp_c + rnorm(n(), 0, 3), 1),
    weight_g = round(
      mean_wt * (wing_length_mm / mean_wing)^3 * (1 + 0.003 * (10 - temp_c)) *
        rnorm(n(), 1, 0.05)
    )
  ) %>%
  arrange(date) %>%
  mutate(id = row_number()) %>%
  select(id, date, year, month, site_id, habitat, species, sex, age,
         wing_length_mm, weight_g, temp_c)

## dirty version for the cleaning task ----
raptors_raw <- raptors %>%
  mutate(
    # one species written in lower case
    species = if_else(species == "Common buzzard" & runif(n()) < 0.4,
                      "common buzzard", species),

    # m, f instead of M, F
    sex = if_else(runif(n()) < 0.15, str_to_lower(sex), sex),

    # NA codes
    weight_g = as.character(weight_g),
    weight_g = case_when(
      runif(n()) < 0.04 ~ "NA",
      runif(n()) < 0.03 ~ "n/a",
      runif(n()) < 0.03 ~ "-999",
      runif(n()) < 0.02 ~ "0",
      TRUE ~ weight_g
    ),

    # junk cols
    ring_number = str_c("CZP-", sample(100000:999999, n())),
    ringer = sample(c("JK", "PN", "MS", "LT", "IK"), n(), replace = TRUE),
    weather = sample(c("sunny", "cloudy", "rain", "wind"), n(), replace = TRUE),
    notes = if_else(runif(n()) < 0.1,
                    sample(c("moulting", "recapture", "parasites", "photo"),
                           n(), replace = TRUE),
                    NA_character_)
  ) %>%
  bind_rows(., slice_sample(., n = 5)) %>%   # duplicates
  arrange(id) %>%
  rename(
    ID = id,
    Date = date,
    Year = year,
    Month = month,
    Site = site_id,
    Habitat = habitat,
    Druh = species,                          # Czech name (= species)
    Sex = sex,
    Age = age,
    `Wing length [mm]` = wing_length_mm,
    `Weight (g)` = weight_g,
    `Temp °C` = temp_c,
    `Ring number` = ring_number,
    Ringer = ringer,
    Weather = weather,
    Notes = notes
  )

## export ----
write_csv(raptors, "workshop_data/exercise_raptors_individuals.csv")   # clean, for ggplot
write_csv(raptors_raw, "workshop_data/exercise_raptors_raw.csv")       # dirty, for the cleaning task
