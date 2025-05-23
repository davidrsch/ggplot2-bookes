set.seed(451)

library(ggplot2)
conflicted::conflict_prefer("Position", "ggplot2")

library(dplyr)
conflicted::conflict_prefer("filter", "dplyr")
conflicted::conflict_prefer("pull", "dplyr") # in case git2r is loaded

library(tidyr)
conflicted::conflict_prefer("extract", "tidyr")

options(digits = 3, dplyr.print_min = 6, dplyr.print_max = 6)
options(crayon.enabled = FALSE)

# suppress startup message
library(maps)

knitr::opts_chunk$set(
  comment = "#>",
  collapse = TRUE,
  fig.show = "hold",
  dpi = 300,
  cache = TRUE
)

is_latex <- function() {
  identical(knitr::opts_knit$get("rmarkdown.pandoc.to"), "latex")
}

status <- function(type) {
  status <- switch(
    type,
    polishing = "should be readable but is currently undergoing final polishing",
    restructuring = "is undergoing heavy restructuring and may be confusing or incomplete",
    drafting = "is currently a dumping ground for ideas, and we don't recommend reading it",
    complete = "is largely complete and just needs final proof reading",
    stop("Invalid `type`", call. = FALSE)
  )

  class <- switch(
    type,
    polishing = "note",
    restructuring = "important",
    drafting = "important",
    complete = "note"
  )

  callout <- paste0(
    "\n",
    "::: {.callout-",
    class,
    "} \n",
    "You are reading the work-in-progress third edition of the ggplot2 book. ",
    "This chapter ",
    status,
    ". \n",
    "::: \n"
  )

  cat(callout)
}


# Draw parts of plots -----------------------------------------------------

draw_legends <- function(...) {
  plots <- list(...)
  gtables <- lapply(plots, function(x) ggplot_gtable(ggplot_build(x)))
  guides <- lapply(gtables, gtable::gtable_filter, "guide-box")

  one <- Reduce(function(x, y) cbind(x, y, size = "first"), guides)

  grid::grid.newpage()
  grid::grid.draw(one)
}


# Customised plot layout --------------------------------------------------

plot_hook_bookdown <- function(x, options) {
  paste0(
    begin_figure(x, options),
    include_graphics(x, options),
    end_figure(x, options)
  )
}

begin_figure <- function(x, options) {
  if (!knitr_first_plot(options)) return("")

  paste0(
    "\\begin{figure}[H]\n",
    if (options$fig.align == "center") "  \\centering\n"
  )
}
end_figure <- function(x, options) {
  if (!knitr_last_plot(options)) return("")

  paste0(
    if (!is.null(options$fig.cap)) {
      paste0(
        '  \\caption{',
        options$fig.cap,
        '}\n',
        '  \\label{fig:',
        options$label,
        '}\n'
      )
    },
    "\\end{figure}\n"
  )
}
include_graphics <- function(x, options) {
  opts <- c(
    sprintf('width=%s', options$out.width),
    sprintf('height=%s', options$out.height),
    options$out.extra
  )
  if (length(opts) > 0) {
    opts_str <- paste0("[", paste(opts, collapse = ", "), "]")
  } else {
    opts_str <- ""
  }

  paste0(
    "  \\includegraphics",
    opts_str,
    "{",
    tools::file_path_sans_ext(x),
    "}",
    if (options$fig.cur != options$fig.num) "%",
    "\n"
  )
}

knitr_first_plot <- function(x) {
  x$fig.show != "hold" || x$fig.cur == 1L
}
knitr_last_plot <- function(x) {
  x$fig.show != "hold" || x$fig.cur == x$fig.num
}


# control output lines ----------------------------------------------------

hook_output <- knitr::knit_hooks$get("output")
knitr::knit_hooks$set(output = function(x, options) {
  lines <- options$output.lines
  if (is.null(lines)) {
    return(hook_output(x, options)) # pass to default hook
  }

  x <- unlist(strsplit(x, "\n"))

  if (length(lines) == 1) {
    # first n lines
    if (length(x) > lines) {
      # truncate the output, but add ....
      x <- c(head(x, lines), more)
    }
  } else {
    x <- x[lines] # don't add ... when we get vector input
  }
  # paste these lines together
  x <- paste(c(x, ""), collapse = "\n")
  hook_output(x, options)
})
