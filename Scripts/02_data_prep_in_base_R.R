# Importing data
# Before analysing data, we need to import it into R.
# Base R provides several functions for importing data:

# read.csv()       Import comma-separated files
# read.delim()     Import tab-separated files
# read.table()     Import general text files

# We use check.names = FALSE to preserve the original column names, including spaces, brackets and symbols.
# stringsAsFactors = FALSE ensures text columns remain character vectors rather than factors.

# If R cannot find the file, check the working directory:
setwd(...)
getwd()

# Dataset: workshop_data/big_cats_raw.csv
big_cats <- read.csv(
  "workshop_data/big_cats_raw.csv",
  header = TRUE,
  sep = ",",
  stringsAsFactors = FALSE,
  check.names = FALSE
)

# Importing Excel file(s)
# library(readxl)
# big_cats_xl <- read_excel(
#  "workshop_data/big_cats_raw.xlsx",
#  sheet = 1
# )

# Inspecting data
# Useful functions:
head(big_cats)      # First 6 rows
tail(big_cats)      # Last 6 rows
dim(big_cats)       # Number of rows and columns
nrow(big_cats)      # Number of rows
ncol(big_cats)      # Number of columns
names(big_cats)     # Column names
str(big_cats)       # Structure and data types
summary(big_cats)   # Summary statistics

# Inspect individual columns:
unique(big_cats$Species)
unique(big_cats$Pohlaví)
unique(big_cats$`Age class`)
unique(big_cats$Site)

# Notice that some columns that should contain numbers are imported as character variables.
# This happens because they contain inconsistent formats, such as decimal commas, text or special missing-value codes.
# Also notice that some categorical variables have inconsistent spelling, capitalisation or whitespace.
# Our task is to identify and correct these problems.

# Renaming column names
# Messy column names make it difficult to work with data.

# Examples:
# "Weight (kg)"
# "Body length [cm]"
# "Temp °C"
# "Pohlaví"

# We want simple, consistent and descriptive names.
# We can rename columns directly using names():
names(big_cats)

# Rename selected columns:
names(big_cats)[names(big_cats) == "Record ID"] <- "record_id"
names(big_cats)[names(big_cats) == "Site"] <- "site"
names(big_cats)[names(big_cats) == "Timestamp"] <- "timestamp"
names(big_cats)[names(big_cats) == "Species"] <- "species"
names(big_cats)[names(big_cats) == "Pohlaví"] <- "sex"

# Check the new names:
names(big_cats)

# Consistent naming conventions makes data easier to read.
# A common convention is snake_case:

# body_length_cm
# sample_date
# species_name

# Avoid spaces, special characters and unnecessary symbols.

# Removing unnecessary columns
# Not every column is necessarily useful for our analysis.

# In this example, we do not need:
# - Trap ID
# - Observer
# - Notes
# - Lab code

# Assigning NULL to a column removes it from the data frame.
big_cats$Notes <- NULL
big_cats$`Lab code` <- NULL

# Check the remaining columns:
names(big_cats)

# Duplicated observations can bias subsequent analyses.
# duplicated() identifies rows that have already appeared.
# The first occurrence is kept; subsequent occurrences are marked as TRUE.
sum(duplicated(big_cats))

# Remove exact duplicated rows:
big_cats <- big_cats[!duplicated(big_cats), ]

# Check the result:
sum(duplicated(big_cats))
dim(big_cats)

# Two observations with the same animal or site are not necessarily duplicates.
# Here we remove only completely identical records.

# Cleaning character variables
# Text columns often contain unnecessary whitespace.
# trimws() removes leading and trailing whitespace.

# We can apply it to every character column using lapply().
big_cats[] <- lapply(big_cats, function(x) {
  if (is.character(x)) {
    trimws(x)
  } else {
    x
  }
})

# Check whether whitespace has been removed:
unique(big_cats$species)
unique(big_cats$site)
unique(big_cats$sex)
unique(big_cats$age_class)

# Standardise site codes:
# toupper() converts text to uppercase.
# tolower() converts text to lowercase.
unique(big_cats$site)
big_cats$site <- toupper(big_cats$site)
unique(big_cats$site) # Check the result

# Categorical data should use consistent labels.
# For example, sex currently contains:
# M, m, male, F, f, Female
unique(big_cats$sex)
big_cats$sex <- tolower(trimws(big_cats$sex))
big_cats$sex[big_cats$sex == "m"] <- "M"
big_cats$sex[big_cats$sex == "male"] <- "M"
big_cats$sex[big_cats$sex == "f"] <- "F"
big_cats$sex[big_cats$sex == "female"] <- "F"

# Check the result:
unique(big_cats$sex)
table(big_cats$sex)

# Converting character columns into numbers
# Sometimes numeric variables are imported as character. R cannot directly calculate the mean of a character vector.

# For example:
# "21.5"
# "21,5"
# "18.2"

# Inspect the column:
class(big_cats$weight_kg)
head(big_cats$weight_kg)

# We need to replace decimal commas with decimal points.
# gsub() replaces matching patterns in character strings.

# Here:
# "," = character we want to replace
# "." = replacement
# fixed = TRUE means we search for the literal characters.
big_cats$weight_kg <- gsub(",", ".", big_cats$weight_kg)

# Now convert the column:
big_cats$weight_kg <- as.numeric(big_cats$weight_kg)

# Check the result:
class(big_cats$weight_kg)
summary(big_cats$weight_kg)

# We can also convert other numeric columns:
big_cats$body_length_cm <- as.numeric(big_cats$body_length_cm)
big_cats$temperature_c <- as.numeric(big_cats$temperature_c)

# Handling missing values
# Missing values can be represented in different ways.

# In our weight column, we encounter:
# NA
# n/a
# 0
# -999

# These values should be treated as missing observations.
# Do not automatically replace all zeros with NA in every dataset. Whether zero is meaningful depends on the variable.

# First inspect the problematic values:
table(big_cats$weight_kg, useNA = "always")

# Replace special missing-value codes with NA.
# We already converted the weight column to numeric.
# Therefore, "n/a" has become NA during conversion, while zero and -999 are still numeric values.
big_cats$weight_kg[big_cats$weight_kg == -999] <- NA
big_cats$weight_kg[big_cats$weight_kg == 0] <- NA

# Check the number of missing values:
sum(is.na(big_cats$weight_kg))

# Check missing values across the entire dataset:
colSums(is.na(big_cats))

# Joining tables
# Sometimes information is distributed across multiple files.
# Our big_cats_raw.csv contains site codes but no habitat.
# We could obtain habitat information from sites.csv.

# Load side
sites <- read.csv("workshop_data/sites.csv")

# Combine both datasets using the site column
big_cats <- merge(
  big_cats,
  sites,
  by.x = "site",
  by.y = "site_id",
  all.x = TRUE
)

# Final inspection of the data
# Structure:
str(big_cats)

# Summary:
summary(big_cats)

# Dimensions:
dim(big_cats)

# Column names:
names(big_cats)

# Missing values:
colSums(is.na(big_cats))

# Unique categories:
unique(big_cats$species)
unique(big_cats$sex)
unique(big_cats$age_class)

# Check for remaining duplicated rows:
sum(duplicated(big_cats))

# Check weight and body length:
summary(big_cats$weight_kg)
summary(big_cats$body_length_cm)

# Exporting data
# Once the data are cleaned, we can export them.
# write.csv() writes a data frame to a CSV file.
# row.names = FALSE prevents R from adding an unnecessary
# row-number column.
write.csv(
  big_cats,
  "big_cats.csv",
  row.names = FALSE,
  na = ""
)

# Export dataset to Excel
library(writexl)
write_xlsx(
  big_cats,
  "big_cats_clean.xlsx"
)

# Tasks:
# The current script only partially fixed the data. Add/edit the commands to further improve the this data set!

# Rename all columns consistently.

# Remove the remaining unnecessary columns.

# Fix inconsistencies in the age class and species columns.
