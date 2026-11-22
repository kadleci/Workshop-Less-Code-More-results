# Before starting, make sure you have the following installed:

# 1. R version 4.5.0 or newer
#    https://cran.r-project.org/
#
# 2. RStudio Desktop (IDE)
#    https://posit.co/download/rstudio-desktop/
#
# 3. Windows users: Rtools compatible with your R version
#    https://cran.r-project.org/bin/windows/Rtools/

# Useful keyboard shortcuts (Windows/Linux):
# Ctrl + Enter       Run current line or selection
# Ctrl + Shift + N   Create a new R script
# Ctrl + Shift + C   Comment/uncomment selected lines
# Ctrl + S           Save current script
# Ctrl + L           Clear the console
# Alt + -            Insert assignment operator (<-)
# Tab                Auto complete

# Comments start with #.
# R ignores everything after # on that line.
# Use comments to explain what your code does.

# This is a comment:
# R.version.string

# This is executable code:
R.version.string

# You can write comments above or next to your code:
R.version.string # Previous code is still executable

# The assignment operator <- stores a value in an object.
x <- 5  # Assign the value 5 to x
x # Print x

# R is case-sensitive!
# x and X are two different objects.

x <- 10 # Assign a new value to x (overrides previous)
X <- 20 # Assign the value 20 to X

x
X

# You can see the objects currently stored in memory:
ls()

a <- 4
b <- 2

# Basic arithmetic:
a + b  # Addition
a - b  # Subtraction
a * b  # Multiplication
a / b  # Division
a ^ b  # Exponentiation

# You can also assign the result of a calculation:
result <- a + b
result

# Other useful operators and characters:
# <-   Assignment
# ==   Equality comparison
# !=   Not equal
# >    Greater than
# <    Less than
# >=   Greater than or equal
# <=   Less than or equal
# |    OR
# &    AND
# $    Access a column or named element
# :    Generate a sequence
# %>%  Pipe operator (introduced later in the workshop)

# Examples:
10 == 10
10 != 5
10 > 5
10 < 5
1:10

# More complex operations are done with functions:
sqrt(25)       # Square root
round(3.14159, 2) # Round to 2 decimal places
abs(-10)       # Absolute value
sum(a, b)      # Sum
mean(c(a, b))  # Mean

# One of the most important skills in R is knowing how to find information about functions.
# Open the documentation for a function:
?c
help(c)

# Search for a topic in the documentation:
??mean

# Documentation usually includes:
# Description: What does the function do?
# Usage: How is the function written?
# Arguments: What inputs can you provide?
# Examples: How can you use the function?

#Different data types:
# Numeric: numbers (including decimal numbers)
numeric_value <- 3.14

# Integer: whole numbers explicitly stored as integers
integer_value <- 10L

# Character: text, always enclosed in quotation marks
character_value <- "Hello R!"

# Logical: TRUE or FALSE
logical_value <- TRUE

# R uses commas to separate function arguments and individual elements in vectors or other structures.
numbers <- c(1, 2, 3, 4, 5)
mean(numbers)

# Decimal numbers use a POINT, not a comma:
# Correct:
pi_value <- 3.14159
round(pi_value, digits = 2)

# Incorrect:
pi_value <- 3,14 # This does NOT create the decimal number 3.14.

# Packages extend the functionality of R.
# Installation usually needs to be done only once, or when updating.
install.packages("pkgbuild")
install.packages("readxl")
install.packages("writexl")
install.packages("tidyverse")
install.packages("plotly")
# Do not put install.packages() in every analysis script.
# Install packages separately and use library() at the beginning of your scripts.

# Loading needs to be done every time you start a new R session.
library(tidyverse) # Gain access to all tidyverse functions.

# You can also use functions without loading the package.
if (.Platform$OS.type == "windows") {
  pkgbuild::has_build_tools(debug = TRUE)
} # Check if Rtools is installed on Windows.

# Check the installed version of a package:
packageVersion("tidyverse")

# Make sure to properly cite R packages (if required):
citation("tidyverse")

# Tasks:
# Create three objects:
# - species_name: your favourite plant or animal species
# - sample_size: number of individuals sampled
# - mean_length: mean length of the sampled individuals

# Calculate the total estimated length:
# mean_length * sample_size

# Create a vector containing the following values:
# 12, 15, 18, 22, 25, NA

# Calculate its mean while ignoring missing values.

# Use ?mean to find out what na.rm does.

# Can you install multiple packages at the same time?
