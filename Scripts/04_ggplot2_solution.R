# Solutions: ggplot2 exercise with raptors

library(tidyverse)

raptors <- read_csv("workshop_data/exercise_raptors_individuals.csv")

# 1. Boxplot
ggplot(raptors, aes(x = species, y = weight_g, fill = sex)) +
  geom_boxplot()

# In raptors, females are larger than males. In big cats it is the other way round.

# 2. Scatterplot with trend lines
p_raptors <- ggplot(raptors, aes(wing_length_mm, weight_g, colour = species)) +
  geom_point(alpha = 0.5) +
  geom_smooth(method = "lm", se = FALSE)

p_raptors


# 3. Facets
p_raptors +
  facet_wrap(~ species, scales = "free")

# 4. Labels, theme and saving
p_final <- p_raptors +
  labs(
    title = "Wing length and weight of raptors",
    x = "Wing length (mm)",
    y = "Weight (g)",
    colour = "Species"
  ) +
  theme_minimal()

ggsave("raptors_wing_weight.png", plot = p_final, width = 8, height = 6, dpi = 300)
