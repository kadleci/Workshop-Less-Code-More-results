# Cleaning the big cat capture data with tidyverse (block 3)
# Input:  workshop_data/big_cats_raw.csv, workshop_data/sites.csv
# Output: workshop_data/big_cats_clean.csv (used later for ggplot)

library(tidyverse)   # dplyr, tidyr, readr, stringr, ggplot2, lubridate
library(janitor)     # clean_names()

## 1. What is the tidyverse? ----

# The tidyverse is a collection of R packages for data science.
# library(tidyverse) loads the core packages at once:
#   readr      import data (read_csv)
#   dplyr      transform data (filter, select, mutate, summarise, joins)
#   tidyr      reshape data (pivot_longer, pivot_wider)
#   stringr    work with text (str_trim, str_replace)
#   lubridate  work with dates and times
#   ggplot2    plots
#   purrr      iteration (map)
#   forcats    factors (categories)
#   tibble     a modern version of data.frame

# List of all tidyverse packages:
tidyverse_packages()

# Why is it useful?
# - All packages share the same style, so once you learn one, the others are easy.
# - Function names are verbs that say what they do: filter(), select(), arrange().
# - The first input is always the data, and the result is again a table.
#   That is why the functions can be chained into a pipeline.
# - Code is easier to read for other people and for you in half a year.
# - Very good documentation, cheatsheets and a large community.
#   Free book: R for Data Science, https://r4ds.hadley.nz

## 2. What is a pipeline? ----

# A pipeline is a chain of steps, where the result of one step
# goes straight into the next one.
# The pipe takes the result on the left and puts it as the FIRST input
# of the function on the right:
#   x %>% f()        is the same as   f(x)
#   x %>% f(y)       is the same as   f(x, y)
#   x %>% f() %>% g() is the same as  g(f(x))

x <- c(4, 9, 16)

# The same calculation written in three ways:

# 1. Nested functions: we have to read from the inside out
round(mean(sqrt(x)), 1)

# 2. Intermediate objects: easy to read, but many objects we do not need
x_sqrt <- sqrt(x)
x_mean <- mean(x_sqrt)
round(x_mean, 1)

# 3. Pipeline: read from left to right, like a recipe
#    "take x, then square root, then mean, then round"
x %>%
  sqrt() %>%
  mean() %>%
  round(1)

# Read %>% as "and then".
# Write each step on a new line, with the pipe at the END of the line.

# Shortcut for the pipe:
#   Windows/Linux: Ctrl + Shift + M
#   macOS:         Cmd + Shift + M

## 3. Two pipes: %>% and |> ----

# %>%  comes from the magrittr package (loaded with the tidyverse)
# |>   is the native pipe, built into R since version 4.1, no package needed
x |> sqrt() |> mean() |> round(1)

# For everyday work they do the same thing. Small differences:
# - |> works without loading any package and is a bit faster
# - %>% also accepts a function without brackets: x %>% sqrt   (|> needs sqrt())
# - placeholder when the data should not go to the first input:
#     %>% uses a dot:        cats %>% lm(weight_kg ~ body_length_cm, data = .)
#     |>  uses underscore:   cats |> lm(weight_kg ~ body_length_cm, data = _)
# In this workshop we use %>%, but you can use either. Just stay consistent.

# Which pipe does Ctrl + Shift + M insert?
# Tools > Global Options > Code > Editing >
#   "Use native pipe operator, |> (requires R 4.1+)"
# Ticked: the shortcut writes |>, not ticked: it writes %>%

## 4. Load the data ----

# read_csv() removes spaces around text values automatically (trim_ws = TRUE)
raw <- read_csv("workshop_data/big_cats_raw.csv")
sites <- read_csv("workshop_data/sites.csv")

# Always look at the data first: column names, types and first values
glimpse(raw)
head(raw)

# The same question written in two ways:
unique(raw$Species)
raw$Species %>% unique()

## 5. Column names and unnecessary columns ----

cats <- raw %>%
  # The Czech name and the degree symbol are renamed by hand,
  # clean_names() would not give us the English names we want
  rename(sex = `Pohlaví`, temp_c = starts_with("Temp")) %>%
  # Lower case, no spaces or brackets: "Weight (kg)" becomes weight_kg
  clean_names() %>%
  rename(site_id = site) %>%
  # Remove the columns we do not need for the analysis
  # (or keep only the ones we need: select(record_id, site_id, timestamp, ...))
  select(-trap_id, -observer, -notes, -lab_code) %>%
  # Remove duplicated rows (identical in all columns)
  distinct()

# All three renames could also be done in one rename() before clean_names():
# rename(site_id = Site, sex = `Pohlaví`, temp_c = starts_with("Temp"))

# Look at the data again. What has changed and what is still wrong?
glimpse(cats)
head(cats)

## 6. Text columns ----

# Find the problems first: which values occur in the column?
unique(cats$species)
unique(cats$site_id)
unique(cats$sex)

# Exercise: how can you get the same as a table with a pipeline?
# Hint: distinct() or count()

# Option 1: case_when(), every variant written out by hand.
# Clear to read, but we must know all the variants in advance.
cats %>%
  mutate(sex_new = case_when(
    str_trim(sex) %in% c("M", "m", "male") ~ "M",
    str_trim(sex) %in% c("F", "f", "Female") ~ "F",
    TRUE ~ NA_character_                 # anything else becomes NA
  )) %>%
  count(sex, sex_new)                    # Check: old value next to the new one

# Option 2: stringr functions, they fix all variants at once.
cats <- cats %>%
  mutate(
    # "s03" -> "S03"
    site_id = site_id %>%
      str_trim() %>%                      # remove spaces before and after
      str_to_upper(),                     # all letters in upper case

    # First fix spaces and upper/lower case, then the typos.
    # In the opposite order "pallas cat" in lower case would stay unfixed.
    species = species %>%
      str_trim() %>%                      # remove spaces before and after
      str_to_sentence() %>%               # capital letter only at the start
      str_replace("linx", "lynx") %>%     # replace "linx" with "lynx"
      str_replace("^Pallas cat$", "Pallas's cat"),   # ^ start, $ end of text

    # "male", "m", " M" -> "M"
    sex = sex %>%
      str_trim() %>%                      # remove spaces before and after
      str_to_upper() %>%                  # all letters in upper case
      str_sub(1, 1),                      # keep only the first letter

    # "Adult", "sub adult" -> "adult", "subadult"
    age_class = age_class %>%
      str_trim() %>%                      # remove spaces before and after
      str_to_lower() %>%                  # all letters in lower case
      str_remove_all(" ")                 # remove all spaces inside the text
  )

# Check that only the expected categories are left
cats %>% count(species)     # 5 species
cats %>% count(sex)         # M, F
cats %>% count(age_class)   # adult, subadult
cats %>% count(site_id)     # S01 to S06

## 7. Numeric columns ----

# Find the problems first: weight_kg is <chr>, so something in it is not a number
glimpse(cats)
cats$weight_kg %>% unique()
cats$body_length_cm %>% unique()

cats <- cats %>%
  mutate(
    # Weight was loaded as text because of the decimal commas.
    # Replace commas and convert to a number.
    weight_kg = weight_kg %>%
      str_replace(",", ".") %>%
      # na_if("n/a") %>%
      # Question: why do we not need na_if("n/a") here?
      # Hint: try as.numeric("n/a")
      as.numeric(),

    # 0 and -999 are codes for missing values, not real weights
    # if_else(condition, value if TRUE, value if FALSE)
    weight_kg = if_else(weight_kg <= 0, NA, weight_kg),
    body_length_cm = if_else(body_length_cm <= 0, NA, body_length_cm),

    # Some lengths were entered in wrong units:
    # 1.1 is in metres, 1100 is in millimetres
    # case_when() checks the conditions from top to bottom, the first TRUE wins
    body_length_cm = case_when(
      body_length_cm < 10 ~ body_length_cm * 100,    # m -> cm
      body_length_cm > 500 ~ body_length_cm / 10,    # mm -> cm
      TRUE ~ body_length_cm                          # everything else stays
    )
  )

# min and max quickly show values that make no sense
summary(cats$weight_kg)
summary(cats$body_length_cm)

## 8. Dates and times ----

# Find the problems first: timestamp is <chr> and has two different formats
cats$timestamp %>% unique() %>% head(20)

cats <- cats %>%
  mutate(
    # "2024-01-15 22:30:00" and "15.01.2024 22:30"
    # parse_date_time() tries both orders and reads both of them
    timestamp = parse_date_time(timestamp, orders = c("Ymd HMS", "dmY HM")),
    date = as_date(timestamp),     # only the date, without time
    year = year(timestamp),
    month = month(timestamp)
  )

# Check: how many records have no timestamp (missing already in the raw data)
cats %>% filter(is.na(timestamp)) %>% nrow()

## 9. filter() and arrange() ----

# filter() keeps the rows that meet a condition
cats %>% filter(species == "Leopard")
cats %>% filter(species == "Leopard", sex == "F")     # comma means "and"
cats %>% filter(species %in% c("Leopard", "Snow leopard"))

# Rows with and without a missing value (! means "not")
cats %>% filter(is.na(weight_kg))
cats %>% filter(!is.na(weight_kg))

# arrange() sorts the rows, desc() from the largest
cats %>% arrange(desc(weight_kg)) %>% select(species, weight_kg) %>% head()
cats %>% arrange(weight_kg) %>% select(species, weight_kg) %>% head()

# Some weights look strange (4500 kg?). We will deal with outliers in the next block.

## 10. Add habitat from the sites table ----

# left_join() keeps all records and adds habitat by matching site_id
cats <- cats %>%
  left_join(sites %>% select(site_id, habitat), by = "site_id") %>%
  relocate(habitat, .after = site_id) %>%   # move habitat next to site_id
  arrange(timestamp)                        # sort by time

## 11. Final check ----

glimpse(cats)

# Number of NA values in each column
cats %>% summarise(across(everything(), ~ sum(is.na(.x))))

## 12. Long and wide format ----

# Number of captures per species and month, in long format:
# one row per combination
captures_long <- cats %>%
  filter(!is.na(timestamp)) %>%
  count(species, month)

captures_long

# Wide format: one column per month, easier to read as a table
captures_wide <- captures_long %>%
  pivot_wider(names_from = month, values_from = n, values_fill = 0)

captures_wide

# And back to long format, which ggplot needs
captures_wide %>%
  pivot_longer(-species, names_to = "month", values_to = "n")

## 13. Save the clean data ----

write_csv(cats, "workshop_data/big_cats_clean.csv")

## 14. Task: clean the raptor data ----

# File: workshop_data/exercise_raptors_raw.csv
# Go step by step and check the result after each step.
#
# 1. Load the file and look at it with glimpse().
#
# 2. One column has a Czech name. Rename it to species
#    and clean all column names.
#
# 3. Remove the columns you do not need (ring number, ringer, weather, notes)
#    and remove duplicated rows.
#
# 4. Fix the text columns sex and species.
#    Check with count() that only the expected values are left
#    (6 species, M and F).
#
# 5. weight_g is loaded as text. Find out why,
#    replace the codes for missing values with NA and convert it to a number.
#
# 6. Check the result with summary() and save it as
#    workshop_data/raptors_clean.csv
#
# Bonus: write all steps as one pipeline.
