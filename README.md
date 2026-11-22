# Less code, more results

### A modern workflow in R, from messy data to interactive plots

![R](https://img.shields.io/badge/R-%E2%89%A5%204.5.0-276DC3?logo=r&logoColor=white)
![RStudio](https://img.shields.io/badge/RStudio-Desktop-75AADB?logo=rstudioide&logoColor=white)
![tidyverse](https://img.shields.io/badge/tidyverse-2.0-1A162D)
![Workshop](https://img.shields.io/badge/workshop-5%20hours-2E7D32)

| | |
|---|---|
| **Event** | Kostelecké inspirování 2026 |
| **When** | Wednesday 25 November 2026, 14:00 to 19:00 |
| **Where** | The Grand Hall |
| **Led by** | Ivo Kadlec and Benneth Nass |
| **Bring** | Your own laptop with R and RStudio installed |

---

```r
raw %>%
  clean_names() %>%
  filter(!is.na(weight_kg)) %>%
  ggplot(aes(body_length_cm, weight_kg)) +
  geom_point()

# five lines instead of fifty
```

Is your script dozens of lines that repeat the same thing? Not sure what a pipeline is, or how `mutate()` and `map()` work? After this workshop, that is in the past.

We work with one dataset the whole afternoon: messy capture records of big cats, from first import to finished plots.

## Contents

- [What you will learn](#what-you-will-learn)
- [Before the workshop](#before-the-workshop)
- [Repository structure](#repository-structure)
- [Data](#data)
- [Keyboard shortcuts](#keyboard-shortcuts)
- [Contact](#contact)

## What you will learn

| Block | Topic | Key functions |
|---|---|---|
| 1 | Introduction to R and RStudio | `<-`, `?`, `library()` |
| 2 | Data preparation in base R | `read.csv()`, `unique()`, `trimws()` |
| 3 | Tidyverse and pipelines | `%>%`, `filter()`, `select()`, `mutate()`, `left_join()`, `pivot_longer()` |
| 4 | Visualisation with ggplot2, introduction to plotly | `ggplot()`, `facet_wrap()`, `ggplotly()` |
| 5 | Iteration without copy and paste | `for`, `lapply()`, `map()`, `walk()` |
| 6 | Troubleshooting and tips for everyday work | |

Every block ends with an exercise. Solutions are in the `*_solution.R` files.

## Who it is for

Students and researchers who already work in RStudio. No need to write your own functions, just basic familiarity with R and the motivation to learn something new.

Stuck on your own data? Let us know in advance, and if it does not fit in the workshop, we will look at it over a glass of good wine in the evening!

## Before the workshop

Please prepare your laptop **before** the workshop. Installing everything on site takes a lot of time and the Wi-Fi may be slow.

### 1. Install the software

| Software | Version | Download |
|---|---|---|
| R | 4.5.0 or newer | [cran.r-project.org](https://cran.r-project.org/) |
| RStudio Desktop | latest | [posit.co](https://posit.co/download/rstudio-desktop/) |
| Rtools (Windows only) | matching your R version | [cran.r-project.org/bin/windows/Rtools](https://cran.r-project.org/bin/windows/Rtools/) |

### 2. Install the packages

Run this once in the RStudio console:

```r
install.packages(c(
  "tidyverse",   # dplyr, tidyr, readr, stringr, ggplot2, purrr, lubridate
  "janitor",     # clean_names()
  "writexl",     # export to Excel
  "here",        # file paths in projects
  "plotly",      # interactive plots
  "htmlwidgets", # save interactive plots as HTML
  "pkgbuild"     # check Rtools on Windows
))
```

### 3. Test that everything works

```r
library(tidyverse)
library(janitor)
library(plotly)

R.version.string
packageVersion("tidyverse")

# Windows only: is Rtools installed?
if (.Platform$OS.type == "windows") pkgbuild::has_build_tools(debug = TRUE)

iris %>%
  clean_names() %>%
  group_by(species) %>%
  summarise(mean_length = mean(sepal_length))

p <- ggplot(iris, aes(Sepal.Length, Petal.Length, color = Species)) +
  geom_point()

p
ggplotly(p)

1:3 %>% map_dbl(\(x) x * 2)
```

If everything works, you will see a table with 3 species, a scatter plot, the same plot as an interactive version in the Viewer pane and the numbers `2 4 6`.

**Something does not work?** Copy the error message and send it to [kadleci@fzp.czu.cz](mailto:kadleci@fzp.czu.cz) before the workshop.

### 4. Download this repository

**Option A, without Git:** click the green **Code** button above, then **Download ZIP**. Unzip the folder.

**Option B, with Git:**

```bash
git clone https://github.com/kadleci/Workshop-Less-Code-More-results.git
```

Then open the `.Rproj` file in RStudio. All paths in the scripts are relative to the project folder, so the scripts work on any computer.

## Repository structure

```
Workshop-Less-Code-More-results/
├── scripts/             R scripts for each block, with exercises
│   └── *_solution.R     solutions of the exercises
├── workshop_data/       data used in the workshop
└── README.md
```

## Data

All data are **simulated**. Body sizes are based on published values, so the numbers look realistic, but no record comes from a real animal.

| File | Content | Used in |
|---|---|---|
| `big_cats_raw.csv` / `.xlsx` | Messy capture records of five cat species, full of errors to fix | Blocks 2 and 3 |
| `sites.csv` | Study sites with habitat and coordinates | Block 3 (join) |
| `big_cats_clean.csv` | The same data after cleaning | Blocks 4 and 5 |
| `exercise_raptors_raw.csv` | Messy raptor ringing data | Exercise in block 3 |
| `exercise_raptors_individuals.csv` | Clean raptor ringing data | Exercise in block 4 |

## Keyboard shortcuts

| Shortcut | Action |
|---|---|
| `Ctrl + Enter` | Run current line or selection |
| `Ctrl + Shift + N` | Create a new R script |
| `Ctrl + Shift + C` | Comment/uncomment selected lines |
| `Ctrl + Shift + M` | Insert pipe `%>%` |
| `Ctrl + S` | Save current script |
| `Ctrl + L` | Clear the console |
| `Alt + -` | Insert assignment operator `<-` (left Alt) |
| `Tab` | Auto complete |

On macOS use `Cmd` instead of `Ctrl` and `Option` instead of `Alt`.

<details>
<summary><b>Czech keyboard</b></summary>

<br>

`Alt + -` may not work on a Czech keyboard. Use `Alt` + minus on the numeric keypad, or set your own shortcut in **Tools > Modify Keyboard Shortcuts > Insert Assignment Operator**.

Characters often used in R (AltGr = right Alt key):

| Character | Keys | Character | Keys |
|---|---|---|---|
| `#` | AltGr + X | `$` | AltGr + ů |
| `<` | AltGr + , | `>` | AltGr + . |
| `[` | AltGr + F | `]` | AltGr + G |
| `{` | AltGr + B | `}` | AltGr + N |
| `\|` | AltGr + W | `&` | AltGr + C |
| `~` | AltGr + + | `\` | AltGr + Q |
| `@` | AltGr + V | `%` | Shift + = |

Tip: many people switch to the English keyboard for coding (`Win + Space`).

</details>

## Useful links

- [R for Data Science](https://r4ds.hadley.nz), free book about the tidyverse
- [Posit cheatsheets](https://posit.co/resources/cheatsheets/) for dplyr, ggplot2, purrr and more

## Contact

Any questions? Write to Ivo Kadlec at [kadleci@fzp.czu.cz](mailto:kadleci@fzp.czu.cz).

**We look forward to seeing you!**
Ivo Kadlec and Nass Benneth
