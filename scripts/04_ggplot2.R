# ggplot2 is a package for creating data visualisations.

# The basic structure is:
# ggplot(data, aes(x = variable, y = variable)) +
#   geom_...()

# Main components:
# ggplot()  = Define the dataset
# aes()     = Define aesthetics (variables, colours, sizes)
# geom_*()  = Define the type of plot
# labs()    = Add titles and axis labels
# theme()   = Change the appearance of the plot
# ggplot2 plots are built by adding layers using +

# Load tidyverse
# library(tidyverse)
# Load clean data
# big_cats <- read.csv(
#   "big_cats_clean.csv",
#   stringsAsFactors = FALSE
# )

# BOXPLOTS ----
# Boxplots are useful for comparing distributions between different groups.

# They show:
# - Median (middle line)
# - First and third quartiles (box)
# - Whiskers
# - Potential outliers

# Basic boxplot:
ggplot(big_cats, aes(x = species, y = weight_kg)) +
  geom_boxplot()

# How do we decide what is an outlier? We use the IQR rule (Tukey's rule), the same rule that a boxplot uses to draw the separate points.

# Q1 (1st quartile)  = 25 % of values are smaller than this
# Q3 (3rd quartile)  = 75 % of values are smaller than this
# IQR = Q3 - Q1      = the range of the middle half of the data (the box)

# A value is an outlier when it is far from the box:
#   lower limit = Q1 - 3 * IQR
#   upper limit = Q3 + 3 * IQR

# Boxplots use 1.5 * IQR. We use 3 * IQR to remove only extreme values (typing errors), not animals that are just a bit bigger or smaller.

# Why per species? A weight of 3 kg is normal for Pallas's cat, but impossible for a leopard. With limits calculated for all cats together, the small and large species would hide each other's errors.

# Calculate the limits for each species and look at the outliers
cats <- big_cats %>%
  group_by(species) %>%                               # calculations per species
  mutate(
    q1 = quantile(weight_kg, 0.25, na.rm = TRUE),     # na.rm = TRUE ignores NA
    q3 = quantile(weight_kg, 0.75, na.rm = TRUE),
    iqr = q3 - q1,
    lower = q1 - 3 * iqr,
    upper = q3 + 3 * iqr,
    outlier = weight_kg < lower | weight_kg > upper
  ) %>%
  ungroup()                                           # remove the grouping

# group_by() + mutate() keeps all rows and adds the limits to each of them
# (group_by() + summarise() would give one row per species instead)
cats %>%
  filter(outlier) %>%
  select(record_id, species, weight_kg, lower, upper)

# Replace the outliers with NA and remove the helper columns.
# We use NA instead of deleting the row, so the other measurements are kept.
big_cats <- cats %>%
  mutate(weight_kg = if_else(outlier, NA_real_, weight_kg, missing = weight_kg)) %>%
  select(-q1, -q3, -iqr, -lower, -upper, -outlier)

# Check the boxplots again, the extreme points should be gone:
ggplot(big_cats, aes(x = species, y = weight_kg)) +
  geom_boxplot()

# Aesthetics control how variables are represented in a plot.

# Common aesthetics:
# x       = Position on the x-axis
# y       = Position on the y-axis
# colour  = Colour of points and lines
# fill    = Interior colour of bars and boxes
# alpha   = Transparency

# For example:
# aes(colour = species) gives each species a different colour.

# Fill boxes according to sex:
ggplot(big_cats, aes(x = species, y = weight_kg, fill = sex)) +
  geom_boxplot()

# Add a legend and save as object:
p_box <- ggplot(big_cats, aes(x = species, y = weight_kg, fill = sex)) +
  geom_boxplot() +
  labs(
    title = "Weight distribution by species and sex",
    x = "Species",
    y = "Weight (kg)",
    fill = "Sex")

p_box

# What can we observe?
# - Different species have different weight distributions.
# - Males have higher median weights than females in this dataset.
# - There is considerable variation within species.

# A boxplot displays distributions, not individual values.
# Remaining outliers are not necessarily measurement errors.

# You can add significance levels with other packages like ggpubr:
# library(ggpubr)
# library(rstatix)

# Perform Wilcoxon tests separately for each species
# boxplot_stats <- big_cats %>%
#   group_by(species) %>%
#   wilcox_test(weight_kg ~ sex) %>%
#   ungroup() %>%
#   adjust_pvalue(method = "BH") %>%
#   add_significance("p.adj") %>%
#   add_xy_position(x = "species")

# Boxplot with significance bars and asterisks
# ggplot(big_cats, aes(x = species, y = weight_kg, fill = sex)) +
#   geom_boxplot() +
#   stat_pvalue_manual(
#     boxplot_stats,
#     label = "p.adj.signif",
#     tip.length = 0.01) +
#   labs(
#     x = "Species",
#     y = "Weight (kg)",
#     fill = "Sex")

# HISTOGRAMS ----
# Histograms show the distribution of a numerical variable.

# They divide values into intervals (bins) and display how many observations fall into each interval.

# Useful for:
# - Understanding data distributions
# - Identifying peaks
# - Detecting skewness
# - Identifying potential outliers

# Example: Distribution of body weight:
ggplot(big_cats, aes(x = weight_kg)) +
  geom_histogram()

# Change the bin width:
ggplot(big_cats, aes(x = weight_kg)) +
  geom_histogram(binwidth = 5)

# Add fill by species:
ggplot(big_cats, aes(x = weight_kg, fill = species)) +
  geom_histogram(
    binwidth = 5,
  )

p_hist <- ggplot(big_cats, aes(x = weight_kg, fill = species)) +
    geom_histogram(
      binwidth = 5,
      alpha = 0.5,
      position = "identity")

p_hist

# binwidth = 5:
# Each bin covers 5 kg.

# alpha = 0.5:
# Makes the histograms semi-transparent.

# position = "identity":
# Histograms are drawn on top of each other rather than stacked.

# SCATTERPLOTS ----
# Scatterplots are useful for examining relationships between two numerical variables.
# We assign one numerical variable to the x-axis and another numerical variable to the y-axis.

ggplot(
  data = big_cats,
  aes(x = body_length_cm, y = weight_kg)
) +
  geom_point()

# We can also write the same code more compactly:
ggplot(big_cats, aes(body_length_cm, weight_kg)) +
  geom_point()

# Add a title and axis labels:
ggplot(big_cats, aes(body_length_cm, weight_kg)) +
  geom_point() +
  labs(
    title = "Body length and weight of big cats",
    x = "Body length (cm)",
    y = "Weight (kg)"
  )

# Colour by species:
ggplot(big_cats, aes(body_length_cm, weight_kg, colour = species)) +
  geom_point()

# With labels:
ggplot(big_cats, aes(body_length_cm, weight_kg, colour = species)) +
  geom_point() +
  labs(
    title = "Body length and weight of big cats",
    x = "Body length (cm)",
    y = "Weight (kg)",
    colour = "Species"
  )

# Different point sizes:
ggplot(big_cats, aes(body_length_cm, weight_kg, colour = species, size = body_length_cm)) +
  geom_point()

# Different point shapes:
ggplot(big_cats, aes(body_length_cm, weight_kg, shape = sex)) +
  geom_point()

# Transparency:
# Alpha ranges from 0 (completely transparent) to 1 (completely opaque).
# This is especially useful when many observations overlap:
ggplot(big_cats, aes(body_length_cm, weight_kg, colour = species, shape = sex)) +
  geom_point(alpha = 0.5, size = 2)

# Add a linear trend line:
ggplot(big_cats, aes(x = body_length_cm,
                     y = weight_kg,
                     colour = species)) +
  geom_point(alpha = 0.6) +
  geom_smooth(method = "lm", se = FALSE)

# geom_smooth() adds a trend line to the plot.

# method = "lm":
# Fits a linear regression model.

# se = FALSE:
# Hides the confidence interval around the fitted line.

# Save the plot as an object:
p_scatter <- ggplot(big_cats,
                    aes(x = body_length_cm,
                        y = weight_kg,
                        colour = species)) +
  geom_point(size = 2, alpha = 0.6) +
  geom_smooth(method = "lm") +
  labs(
    title = "Relationship between body length and weight",
    x = "Body length (cm)",
    y = "Weight (kg)",
    colour = "Species"
  )

p_scatter

# CUSTOMISING PLOTS ----
# ggplot2 provides many ways to customise visualisations.

# We can change:
# - Colours
# - Point shapes
# - Point sizes
# - Axis labels
# - Plot titles
# - Background and grid
# - Legend position

# Example: Switch between colour presets.
p_scatter +
  scale_colour_brewer(palette = "Dark2")

p_scatter +
  scale_colour_brewer(palette = "Set1")

p_scatter +
  scale_colour_brewer(palette = "Paired")

p_scatter +
  scale_colour_viridis_d(option = "mako")

# Example: Change colours manually.
p_scatter +
  scale_colour_manual(
    values = c(
      "Clouded leopard" = "#1B9E77",
      "Eurasian lynx" = "#D95F02",
      "Leopard" = "#7570B3",
      "Pallas's cat" = "darkred",
      "Snow leopard" = "brown"
    )
  )

# Example: Change the overall theme.
p_scatter +
  theme_light()

# Other useful themes:
# theme_minimal()
# theme_classic()
# theme_light()
# theme_dark()
# theme_void()

# Example: Customise the legend position.
p_scatter +
  theme_minimal() +
  theme(
    legend.position = "bottom"
  )

# Example: Customise axis labels and title.
p_scatter +
  labs(
    title = "Body length vs body weight",
    subtitle = "Measurements from five big cat species",
    x = "Body length (cm)",
    y = "Body weight (kg)",
    caption = "Source: Big cats workshop dataset"
  ) +
  theme_classic()

# FACETING ----
# Faceting allows us to split a plot into multiple panels based on categorical variables.

# Instead of displaying all observations in one plot, we create separate panels for individual groups.

# Two useful functions:

# facet_wrap() = Creates a collection of panels.
# facet_grid() = Creates panels arranged in rows and columns.

# FACET_WRAP
# Example: One scatterplot for each species.
p_scatter +
  facet_wrap(~ species)

# We can also use free scales:
p_scatter +
  facet_wrap(~ species, scales = "free")

# Each panel can have its own axis limits.
# This can make patterns easier to see when groups have very different value ranges.
# Default is scales = "fixed".

# FACET_GRID
# Example: Compare body weight by habitat and sex.
p_box +
  facet_grid(habitat ~ sex)

# This is particularly useful in our dataset because species are associated with different habitats:

# Mountain steppe:
# - Snow leopard
# - Pallas's cat

# Tropical forest:
# - Clouded leopard

# Temperate forest:
# - Eurasian lynx
# - Leopard

# We can also facet histograms:
p_hist +
  facet_wrap(~ species)

# SAVING PLOTS ----
# Once we have created a plot, we can save it.
# ggsave() saves the last displayed plot by default.
# We can also specify the plot object explicitly.
ggsave(
  filename = "weight_distribution.png",
  plot = p_hist,
  width = 8,
  height = 6,
  dpi = 300
)

# Other formats are supported:
# .png
# .jpg
# .pdf
# .svg (requires the svglite package)

# Example: Save a scatterplot as PDF.
ggsave(
  filename = "body_length_vs_weight.pdf",
  plot = p_scatter,
  width = 8,
  height = 6
)

# Learn more about ggplot2: https://ggplot2-book.org/

# INTERACTIVE PLOTS ----
# Load packages
library(lubridate)
library(plotly)
library(htmlwidgets)

# ggplotly() turns it into an interactive plot
ggplotly(p_scatter)

# The tooltip shows the aesthetics by default (x, y, color).
# With "text" we decide ourselves what is shown when hovering.
# <br> means a new line in the tooltip.
p_tooltip <- big_cats %>%
  ggplot(aes(body_length_cm, weight_kg, color = species,
             text = str_c("Species: ", species,
                          "<br>Sex: ", sex,
                          "<br>Age: ", age_class,
                          "<br>Site: ", site_id,
                          "<br>Weight: ", weight_kg, " kg"))) +
  geom_point(alpha = 0.6) +
  labs(x = "Body length (cm)", y = "Weight (kg)", color = "Species") +
  theme_minimal()

# Without tooltip = "text" plotly would show everything together
ggplotly(p_tooltip, tooltip = "text")

# Facets work as well!
ggplotly(p_scatter + facet_wrap(~ species, scales = "free"))
