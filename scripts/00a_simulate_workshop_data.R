# sim data for the workshop - big cats captures
# run once before the workshop

library(tidyverse)
library(lubridate)
library(writexl)

set.seed(2026)
n_rec <- 600

dir.create("workshop_data", showWarnings = FALSE)
dir.create("workshop_data/instructor", showWarnings = FALSE)

## sites ----
sites <- tibble(
  site_id = str_c("S0", 1:6),
  site_name = c("Altai Mountains", "Tost Mountains", "Khao Yai", "Namdapha",
                "Sumava", "Land of the Leopard"),
  country = c("Mongolia", "Mongolia", "Thailand", "India", "Czechia", "Russia"),
  habitat = c("mountain steppe", "mountain steppe", "tropical forest", "tropical forest",
              "temperate forest", "temperate forest"),
  elevation_m = c(2600, 2000, 800, 600, 900, 400),
  lat = c(46.5, 43.1, 14.4, 27.5, 49.0, 43.2),
  lon = c(91.8, 100.3, 101.4, 96.4, 13.5, 131.5)
)

## params ----
# head-body length in cm, weight in kg
species_pars <- tibble(
  species = c("Snow leopard", "Clouded leopard", "Eurasian lynx", "Leopard", "Pallas's cat"),
  l_m = c(115, 95, 105, 150, 57),
  l_f = c(105, 82, 97, 130, 54),
  sd_l = c(7, 5.5, 6, 11, 3),
  w_m = c(45, 17, 21, 58, 3.7),
  w_f = c(35, 12.5, 18, 38, 3.2)
)

age_pars <- tibble(
  age_class = c("subadult", "adult"),
  age_mult = c(0.9, 1)   # subadults ~10 % smaller
)

# more captures in winter + in 2024
effort <- tibble(
  month_start = seq(ymd("2023-01-01"), ymd("2024-12-01"), by = "month")
) %>%
  mutate(
    prob = (1 + 0.6 * cos(2 * pi * (month(month_start) - 1) / 12)) *
      if_else(year(month_start) == 2024, 1.3, 1)
  )

## clean data ----
captures_clean <- tibble(
  record_id = 1:n_rec,
  site_id = sample(sites$site_id, n_rec, replace = TRUE),
  month_start = sample(effort$month_start, n_rec, replace = TRUE, prob = effort$prob),
  u = runif(n_rec),
  sex = sample(c("M", "F"), n_rec, replace = TRUE),
  age_class = sample(age_pars$age_class, n_rec, replace = TRUE, prob = c(0.25, 0.75))
) %>%
  left_join(select(sites, site_id, habitat), by = "site_id") %>%
  mutate(
    species = case_when(
      habitat == "mountain steppe" & u < 0.60 ~ "Snow leopard",
      habitat == "mountain steppe" & u < 0.90 ~ "Pallas's cat",
      habitat == "mountain steppe" ~ "Eurasian lynx",
      habitat == "tropical forest" & u < 0.45 ~ "Clouded leopard",
      habitat == "tropical forest" ~ "Leopard",
      site_id == "S05" ~ "Eurasian lynx",   # only lynx in Sumava
      u < 0.50 ~ "Eurasian lynx",
      TRUE ~ "Leopard"
    ),
    timestamp = as_datetime(month_start) +
      days(sample(0:27, n_rec, replace = TRUE)) +
      hours(sample(c(20:23, 0:6), n_rec, replace = TRUE)) +
      minutes(sample(0:59, n_rec, replace = TRUE))
  ) %>%
  left_join(species_pars, by = "species") %>%
  left_join(age_pars, by = "age_class") %>%
  mutate(
    seasonal = cos(2 * pi * (yday(timestamp) - 200) / 365),
    temp_c = round(
      case_when(
        habitat == "tropical forest" ~ 25 + 3 * seasonal,
        habitat == "mountain steppe" ~ 2 + 12 * seasonal,
        TRUE ~ 8 + 10 * seasonal
      ) + rnorm(n_rec, 0, 3),
      1
    ),
    ref_l = if_else(sex == "M", l_m, l_f),
    ref_w = if_else(sex == "M", w_m, w_f),
    body_length_cm = round(rnorm(n_rec, ref_l * age_mult, sd_l * age_mult)),
    weight_kg = round(ref_w * (body_length_cm / ref_l)^3 * rnorm(n_rec, 1, 0.05), 1)
  ) %>%
  arrange(timestamp) %>%
  mutate(record_id = row_number()) %>%
  select(record_id, site_id, habitat, timestamp, species, sex, age_class,
         body_length_cm, weight_kg, temp_c)

## wide table for pivot_longer ----
captures_wide <- captures_clean %>%
  mutate(month = factor(month.abb[month(timestamp)], levels = month.abb)) %>%
  count(site_id, species, month) %>%
  pivot_wider(names_from = month, values_from = n, values_fill = 0, names_sort = TRUE)

## dirty data ----
# habitat removed -> they join it from sites.csv
captures_raw <- captures_clean %>%
  select(-habitat) %>%
  mutate(
    site_id = if_else(runif(n_rec) < 0.05, str_to_lower(site_id), site_id),

    species = case_when(
      runif(n_rec) < 0.06 ~ str_to_lower(species),
      runif(n_rec) < 0.06 ~ str_c(species, " "),
      runif(n_rec) < 0.25 ~ str_replace(species, "lynx", "linx"),
      runif(n_rec) < 0.25 ~ str_replace(species, "Pallas's", "Pallas"),
      TRUE ~ species
    ),

    sex = case_when(
      runif(n_rec) < 0.10 & sex == "M" ~ "male",
      runif(n_rec) < 0.10 & sex == "F" ~ "Female",
      runif(n_rec) < 0.08 ~ str_to_lower(sex),
      runif(n_rec) < 0.04 ~ str_c(" ", sex),
      TRUE ~ sex
    ),

    age_class = case_when(
      runif(n_rec) < 0.10 ~ str_to_title(age_class),
      runif(n_rec) < 0.10 & age_class == "subadult" ~ "sub adult",
      runif(n_rec) < 0.05 ~ str_c(age_class, " "),
      TRUE ~ age_class
    ),

    # commas, NA codes, outliers
    weight_kg = as.character(weight_kg),
    weight_kg = if_else(runif(n_rec) < 0.35, str_replace(weight_kg, "\\.", ","), weight_kg),
    weight_kg = case_when(
      record_id == 37 ~ "4500.0",
      record_id == 142 ~ "450.0",
      record_id == 255 ~ "0,4",
      runif(n_rec) < 0.04 ~ "NA",
      runif(n_rec) < 0.03 ~ "n/a",
      runif(n_rec) < 0.03 ~ "0",
      runif(n_rec) < 0.02 ~ "-999",
      TRUE ~ weight_kg
    ),

    # 1.1 = m, 1100 = mm
    body_length_cm = case_when(
      record_id == 88 ~ 1.1,
      record_id == 190 ~ 1100,
      runif(n_rec) < 0.04 ~ NA_real_,
      runif(n_rec) < 0.02 ~ 0,
      TRUE ~ body_length_cm
    ),

    temp_c = if_else(runif(n_rec) < 0.05, NA_real_, temp_c),

    timestamp = case_when(
      runif(n_rec) < 0.12 ~ format(timestamp, "%d.%m.%Y %H:%M"),
      runif(n_rec) < 0.04 ~ NA_character_,
      TRUE ~ format(timestamp, "%Y-%m-%d %H:%M:%S")
    ),

    # junk cols
    trap_id = str_c("TR", sample(100:999, n_rec, replace = TRUE)),
    observer = sample(c("JK", "PN", "MS", "LT"), n_rec, replace = TRUE),
    notes = if_else(
      runif(n_rec) < 0.15,
      sample(c("rain", "collar fitted", "hair sample taken", "camera moved"),
             n_rec, replace = TRUE),
      NA_character_
    ),
    lab_code = str_c("L", sample(1000:9999, n_rec, replace = TRUE))
  ) %>%
  bind_rows(., slice_sample(., n = 6)) %>%   # duplicates
  arrange(record_id) %>%
  rename(
    `Record ID` = record_id,
    `Site` = site_id,
    Timestamp = timestamp,
    Species = species,
    `Pohlaví` = sex,
    `Age class` = age_class,
    `Body length [cm]` = body_length_cm,
    `Weight (kg)` = weight_kg,
    `Temp °C` = temp_c,
    `Trap ID` = trap_id,
    Observer = observer,
    Notes = notes,
    `Lab code` = lab_code
  )

## export ----
write_csv(captures_raw, "workshop_data/big_cats_raw.csv")
write_xlsx(captures_raw, "workshop_data/big_cats_raw.xlsx")
write_csv(sites, "workshop_data/sites.csv")
write_csv(captures_wide, "workshop_data/captures_wide.csv")
write_csv(captures_clean, "workshop_data/instructor/big_cats_clean_key.csv")
