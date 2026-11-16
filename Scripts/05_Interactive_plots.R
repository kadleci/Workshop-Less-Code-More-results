# Interactive plots with plotly (block 5)
# Input: workshop_data/big_cats_clean.csv (output of the cleaning script)

library(tidyverse)
library(lubridate)
library(plotly)        # interactive plots
library(htmlwidgets)   # saveWidget() ... save interactive plots (or other stuff) as html

## 1. Load the data ----

cats <- read_csv("workshop_data/big_cats_clean.csv")

## 2. From ggplot to plotly in one line ----

# A normal ggplot, saved as an object
p_scatter <- ggplot(cats, aes(body_length_cm, weight_kg, color = species)) +
  geom_point(alpha = 0.6) +
  labs(x = "Body length (cm)", y = "Weight (kg)", color = "Species") +
  theme_minimal()

p_scatter

# ggplotly() turns it into an interactive plot
# Try it: hover over a point, zoom in, click a species in the legend
ggplotly(p_scatter)

## 3. Better tooltips ----

# The tooltip shows the aesthetics by default (x, y, color).
# With "text" we decide ourselves what is shown when hovering.
# <br> means a new line in the tooltip.
p_tooltip <- cats %>%
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

## 4. Trend plot ----

# Interactive plots are useful for time series:
# zoom into one season and compare species by hovering
monthly <- cats %>%
  filter(!is.na(timestamp)) %>%
  mutate(month_start = floor_date(timestamp, "month")) %>%
  count(month_start, species)

p_trend <- ggplot(monthly, aes(month_start, n, color = species)) +
  geom_line() +
  geom_point() +
  labs(x = NULL, y = "Number of captures", color = "Species") +
  theme_minimal()

ggplotly(p_trend)

## 5. Facets work as well ----
# Exercise: create a boxplot of weight_kg for each species,
# split by habitat with facets. Then make it interactive with ggplotly().
# Hint: facet_wrap(), scales = "free_x"

# solution
p_box <- ggplot(cats, aes(species, weight_kg, fill = sex)) +
  geom_boxplot() +
  facet_wrap(~ habitat, scales = "free_x") +
  labs(x = NULL, y = "Weight (kg)", fill = "Sex") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

ggplotly(p_box)

## 6. plot_ly() directly (optional) ----

# plotly has its own syntax. It is not needed for most cases,
# but some plot types are only available here, for example 3D plots.
cats %>%
  plot_ly(x = ~body_length_cm, y = ~weight_kg, z = ~temp_c,
          color = ~species, type = "scatter3d", mode = "markers",
          marker = list(size = 3))

## 7. Save as HTML ----

# The result is a normal web page, it can be opened in any browser
# or sent to a colleague, no R is needed to view it
ggplotly(p_tooltip, tooltip = "text") %>%
  saveWidget("big_cats_scatter.html", selfcontained = TRUE)

# Exercise: save your plot from the exercise as an HTML file and open it in a browser
