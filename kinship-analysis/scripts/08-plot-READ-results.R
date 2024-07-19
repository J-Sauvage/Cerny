#!/usr/bin/env Rscript


# ------------------------------------------------------------------------------------------------ #
# ---- Functions
load_dependencies <- function(packages){
  installed_packages <- packages %in% rownames(installed.packages())
  if (any(installed_packages == FALSE)){
    install.packages(packages[!installed_packages])
  }
  lapply(packages, library, character.only = TRUE)
}

#' Simple argument parser.
#' @import argparse
#' @return an argparse::ArgumentParser object for this script.
build_parser <- function(){
  parser <- argparse::ArgumentParser(
    description = "Generate synthetic visualization for the READ Kinship
    estimation method"
  )

  parser$add_argument("--results",
    type    = "character",
    default = "Read_Results.tsv",
    help    = "(Path): main output of READ."
  )
  parser$add_argument("--meansP0",
    type    = "character",
    default = "meansP0_AncientDNA_normalized_READv2",
    help    = "(Path): secondary output of READ."
  )
  parser$add_argument("--group-regex",
    dest    = "condense.regex.list",
    metavar = "REGEX",
    type    = "character",
    nargs   = "+",
    help    = "List of PCREs matching samples groups to aggregate
    within a boxplot representation"
  )
  parser$add_argument("--group-labels",
    dest    = "condense.label.list",
    metavar = "LABEL",
    type    = "character",
    nargs   = "+",
    help    = "List of labels for every group to aggregate. Must match the
    number of arguments provided in --regex"
  )
  parser$add_argument("--main-label",
    dest    = "main_name",
    metavar = "LABEL",
    type    = "character",
    default = "",
    help    = "main population label for non-aggregated samples"
  )
  parser$add_argument("--plot-ratios",
    dest    = "plot.ratio",
    metavar = "DOUBLE",
    type    = "double",
    nargs   = "+",
    default = c(0.25, 0.25, 0.5),
    help    = "Scaled width size where non-aggregated samples are
    displayed. Value must lie within the range [0,1]"
  )
  parser$add_argument("--read-version",
    dest    = "version",
    metavar = "VERSION",
    type    = "numeric",
    default = 2,
    help    = "Specify which version of READ was used. Accepted values: {1, 2}"
  )
  parser$add_argument("--output-basename",
    metavar = "PATH",
    type    = "character",
    default = "READ-results-plot",
    help    = "Basename of the output files (html and plot)"
  )
  parser$add_argument("--output-format",
    type = "character",
    default = "svg",
    help    = "default format of the output file (svg|png)"
  )

  parser$add_argument("--notch",
    action = "store_true",
    help   = "Add a notch line indicating confidence intervals for boxplots"
  )

  parser$add_argument("--markers",
    type    = "character",
    default = "outliers",
    help    = "Define how to show individual markers within each boxplot
    {all,outliers,suspectedoutliers}"
  )

  parser$add_argument("--filter-snps",
    type    = "integer",
    default = 0,
    help    = "(READv2 only) Filter out individuals whose coverage is below 
    the specified valueas non-significant. These individuals are still used
    for the boxplot creation."
    )

  parser$add_argument("--ci",
    type    = "numeric",
    default = NULL,
    help    = "Compute confidence intervals for error bars instead of standard
    error. A value between [0 and 1] must be set."
  )

  parser$add_argument("--filter-ns-pairs",
    action = "store_true",
    help   = "Filter out pairs whose error bar go beyond the classification
    threshold for Unrelated individuals."
  )

  parser$add_argument("--within-group-regex",
    type    = "character",
    nargs   = "+",
    metavar = "REGEX",
    default = NULL,
    help    = "List of PCREs matching samples within the main population group.
    When provided, this allows for the construction of a third subplot, where
    each subgroup is displayed as a separate boxplot"
  )

  parser$add_argument("--within-group-labels",
    type    = "character",
    nargs   = "+",
    metavar = "REGEX",
    default = NULL,
    help    = "List of labels for every subgroup within the main population.
    Must match the number of arguments provided in --within-group-regex"
  )

  return(parser)
}

#' Return a static list describing Relatedness labels, colors and associated
#' READ kinship thresholds.
#' @param version Which version of READ to use. Setting any value below 2 will
#'        have the effect of removing the 'Third degree' label, and associated
#'        values.
#' @return an ordered with the following vectors:
#'         - labels: Relatedness degree label.
#'         - phi0  : associated READ meansP0 threshold value.
#'         - colors: associated color in (hexadecimal format).
kinship_thresholds <- function(version = 2) {
  thresholds <- list(
    phi0   = c(0.96875, 0.90625, 0.8125, 0.625, 0),
    #labels = c("Third degree", "Second Degree", "First Degree", "Identical Twins"),
    labels = c("Third degree", "Second Degree", "First Degree", "Monozygotic Twins / Self-comparisons"),
    colors  = c("#440154FF", "#31688EFF", "#35B779FF", "#FDE725FF")
  )

  if (version < 2) {
    thresholds$phi0   <- thresholds$phi0[-1]
    thresholds$labels <- thresholds$labels[-1]
    thresholds$colors <- thresholds$colors[-1]
  }
  thresholds
}

#' Output a static list of rectangle objects for a plotly plot. Each rectangle
#' highlighting the territory of a given degree of relatedness.
#' @param version READ version. Any value below 2 will have the effect of
#'        Removing the 'Third degree' rectangle
#' @return a list of lists. Can be given as input to a plotly::layout$shapes
#'         parameter
kinship_rectangles <- function(version = 2) {
    # Create colored rectangles for each relatedness order.
    kinship.thresholds <- kinship_thresholds(version = version)
    rectangles         <- list()
    for (i in seq_along(kinship.thresholds$labels)){
      rectangle                <- list()
      rectangle[["type"]]      <- "rect"
      rectangle[["layer"]]     <- "below"
      rectangle[["editable"]]  <- FALSE
      rectangle[["fillcolor"]] <- kinship.thresholds$colors[i]
      rectangle[["line"]]      <- list(color = kinship.thresholds$colors[i])
      rectangle[["opacity"]]   <- 0.15
      rectangle[["x0"]]        <- 0
      rectangle[["x1"]]        <- 1
      rectangle[["xref"]]      <- "paper"
      rectangle[["y0"]]        <- kinship.thresholds$phi0[i+1]
      rectangle[["y1"]]        <- kinship.thresholds$phi0[i]
      rectangles               <- c(rectangles, list(rectangle))
  }
  rectangles
}

annotate_kinship_labels <- function(fig, font.size = 20, version = 2) {
  kinship.thresholds <- kinship_thresholds(version = version)
  phi0               <- kinship.thresholds$phi0
  kinships           <- kinship.thresholds$labels
  # Add labels for each relatedness order
  fig %>% add_annotations(
    x         = 1,
    y         = phi0[1:length(phi0) - 1],
    yanchor   = "top",
    xanchor   = "right",
    xref      = "paper",
    text      = sprintf("<b>%s</b>", kinships),
    showarrow = FALSE,
    font      = list(size = font.size)
  ) %>% add_annotations(
      x         = 1,
      y         = 1,
      yref      = 'paper',
      yanchor   = "top",
      xanchor   = "right",
      xref      = "paper",
      text      = "<b>Unrelated</b>",
      font      = list(size = font.size),
      showarrow = FALSE
    )
}

#' Compute an appropriate yaxis range for a plotly::plot_ly object, given
#' the range of P0 values and confidence intervals found within the dataset.
#' 
#' @param merged_results a dataframe containing merged READ results, i.e.
#'        an inner join of a Read_Results.tsv and meansP0_ancientDNA_normalized
#'        dataset. (join on PairIndividuals column).
#' @param version Version of READ used. This parameter merely sets sensible
#'        default values for the 'col.po' and 'col.se' arguments.
#' @param col.group name of the grouping column contained in the input
#'        'merged_results' dataframe. 'col.group' must be a factor encoded
#'        integer vector, and may contain NA values.
#'        - non-NA values are understood as pairs which should be collapsed
#'          into a boxplot. min and max values for these pairs are computed
#'          using only the value of 'col.po' 
#'        - NA values are understood as pairs that should not be collapsed
#'          within a boxplot. min and max values are computed using the mean
#'          and standard error (i.e.: col.po +|- col.se), since error bars
#'          are to be displayed for these pairs.
#' @param col.po name of the column containing the normalized PO values
#'               within the 'merged_results' dataframe
#' @param col.se name of the column containing the normalized standard error
#'               within the 'merged_results' dataframe.
#' 
#' @return a vector of two floating point values, defining the min and max
#'         yaxis range for this dataframe. Note that this range has a
#'         minimum value of c(0.55, 1.0)
get_P0_range <- function(
  merged_results,
  version   = 2,
  col.group = "group",
  col.po    = ifelse(version == 2, "P0_mean", "Normalized2AlleleDifference"),
  col.se    = ifelse(version == 2, "StError_2Allele_Norm", "StandardError")
) {
  subset.cols <- c(col.group, col.po, col.se)
  min.val <- apply(merged_results[, subset.cols], MARGIN = 1, FUN = function(x) {
    y <- as.numeric(x[2:3])
    ifelse(is.na(x[[1]]), y[1] - y[2] * 2, y[1])
  }) %>% min
  max.val <- apply(merged_results[, subset.cols], MARGIN = 1, FUN = function(x) {
    y <- as.numeric(x[2:3])
    ifelse(is.na(x[[1]]), y[1] + y[2] * 2, y[1])
  }) %>% max
  c(min(0.59, min.val), max(1.0, max.val))
}

#' Return all pairwise n choose 2 of a vector (with replacement)
#' @param x a vector of values. Can accept numeric, character or factor.
#'        Note that factor vectors will instead have the function work-on and
#'        output *levels* for each value pair.
#' @return a dataframe wontaining two columns, 'left' and 'right', which 
#'         respectively encode members of a given combination pair.
combinations <- function(x){
  if (length(x) < 2) {
    out <- setNames(data.frame(matrix(ncol = 2, nrow = 0)), c("left", "right"))
    return(rbind(out, data.frame(left=x, right=x)))
  }
  out <- sapply(
    X   = seq_along(x),
    FUN = function(i) {
      sapply(i:length(x), FUN = function(j) list(left = x[i], right = x[j]))
    }
  )
  data.frame(t(do.call('cbind', out)))
}

#' Generate a condensable list of population labels for every pair of
#' individuals.
#' @param x a vector of character. Typically, the "PairIndividuals" column
#'        of a Read_Results.tsv file.
#' @param regex.list a list of PCRE regular expressions, matching individuals
#'        within x
#' @param label.list a list of labels for every regex. Must equal the length
#'        of regex.list
#' @param default default preallocated value for unmatched rows.
create_pair_labels <- function(x, regex.list, label.list, default = NA_real_) {
    # ---- Generate a data-frame of paired regex / labels.
  regex.pairs <- combinations(regex.list) %>%
    dplyr::mutate(
      label = apply(
        X      = combinations(label.list),
        MARGIN = 1,
        FUN    = function(x) paste0(x[1], "-", x[2])
      )
    ) %>%
    dplyr::mutate(
      pair_regex_A = paste0(left, right), pair_regex_B = paste0(right, left)
    )

  # ---- Assign a group for every condensable pair
  output      <- rep(default, length = length(x))

  target_cols <- c("pair_regex_A", "pair_regex_B")
  lapply(seq_len(nrow(regex.pairs)), FUN = function(regex.idx) {
    lapply(regex.pairs[regex.idx, target_cols], FUN = function(regex) {
      matches <- grepl(regex, x, perl = TRUE)
      output[matches] <<- regex.pairs$label[regex.idx]
    })
  })
  output
}


#' Main function of this script. Accepts command line arguments, which can be
#' tinkered with interactively by overriding the base::commandArgs() function.
#' See the build_parser() function for details on the list of required and
#' optional arguments.
#' 
#' This script will take in a set of READv2 output files ('Read_Results.tsv'
#' and 'meansP0_AncientDNA_normalized_READv2'), and output an interactive
#' plot using plotly. Non-focus individuals may be aggregated into boxplots,
#' using a set of PCRE regular expressions and labels, to summarize the reults.
#' 
#' @import plotly
#' @import dplyr
#' @import pracma
#' @import argparse
#' @import htmlwidgets.
#' @return NULL
main <- function() {
  # ---- load dependencies
  dependencies <- c("dplyr", "plotly", "pracma", "argparse", "htmlwidgets")
  load_dependencies(dependencies)

  # ---- Parse command-line arguments
  optargs <- build_parser()$parse_args(commandArgs(trailingOnly = TRUE))

  # ---- Quick validation of command line arguments.
  if (!(optargs$version %in% c(1, 2))) {
    quit("Invalid READ version. Must be either 1 or 2")
  }

  if (optargs$plot.ratio < 0 || optargs$plot.ratio > 1) {
    quit("Invalid plot Ratio. Must be within the range [0, 1]")
  }

  if (!(optargs$markers %in% c("all", "outliers", "suspectedoutliers"))) {
    quit("Invalid --markers value. {'all', 'outliers', 'suspectedoutliers'}")
  }
  
  # ---- Import data
  means.sep <- ifelse(optargs$version == 2, "\t", " ")
  results <- read.table(optargs$results, header = TRUE, sep = "\t")
  meansP0 <- read.table(optargs$meansP0, header = TRUE, sep = means.sep)
  merged <- merge(x = results, y = meansP0,
    by = "PairIndividuals", suffixes = c(".results", ".meansP0")
  )

  if (optargs$version == 2) {
    col.po  <- "P0_mean"
    col.se  <- "StError_2Allele_Norm"
    col.rel <- "Rel"
  } else {
    col.po  <- "Normalized2AlleleDifference"
    col.se  <- "StandardError"
    col.rel <- "Relationship"
  }

  # ---- Rescale Jackknife standard error to CI if requested
  if (!is.null(optargs$ci)) {
    if (!is.numeric(optargs$ci))
      stop("Must provide --ci with a numeric value.")
    if (optargs$ci > 1.0 || optargs$ci < 0.0)
      stop("--ci value must be between 0 and 1")
    merged[, col.se] <- merged[, col.se] * qnorm(1 - ((1 - optargs$ci) / 2))
  }

  # ---- Find non focused individuals and assign a group for every
  #      condensable pair of individuals.
  merged$group <- create_pair_labels(
    x          = merged$PairIndividuals,
    regex.list = optargs$condense.regex.list,
    label.list = optargs$condense.label.list,
    default = 0
  )

  # ---- Find focus individuals
  main_pairs.idx <- if (optargs$version == 2) {
    which(merged$group == 0 & merged[[col.rel]] != "Unrelated" & merged$OverlapNSNPs.meansP0 > optargs$filter_snps)
  } else {
    which(merged$group == 0 & merged[[col.rel]] != "Unrelated")
  }

  # ---- Remove individuals whose error bars go beyond unrelated if requested.
  if (optargs$filter_ns_pairs) {
    ns_threshold <- kinship_thresholds(version = optargs$version)$phi0[1]
    ns.pairs <- which((merged[, col.po] + merged[, col.se]) > ns_threshold)
    main_pairs.idx <- main_pairs.idx[which(!(main_pairs.idx %in% ns.pairs))]
  }

  #  ----- reorder by P0 value
  main_pairs.idx <- main_pairs.idx[
    order(merged[main_pairs.idx, col.po])
  ]

  # ---- Set focus individuals as NA group
  merged$group[main_pairs.idx] <- NA

  # ---- Assign mixed groups
  for (i in seq_along(optargs$condense.regex.list)) {
    regex         <- optargs$condense.regex.list[i]
    label         <- optargs$condense.label.list[i]
    matches <- (merged$group == 0) & grepl(regex, merged$PairIndividuals)
    merged$group[which(matches)] <- paste0(optargs$main_name,"-",label)
  }

  # ----- Assign main population group
  merged$group[merged$group == 0] <- paste0(
    optargs$main_name, "-", optargs$main_name
  )

  # ---- Assign subgroups to the main population if requested
  within_group_boxplot_requested <- !is.null(optargs$within_group_regex)
  if (within_group_boxplot_requested) {
    # ---- Assign subgroups for every main-population pair.
    merged$within.group <- create_pair_labels(
      x          = merged$PairIndividuals,
      regex.list = optargs$within_group_regex,
      label.list = optargs$within_group_label,
      default = NA
    )

    # ---- Ignore focus individuals.
    merged$within.group[main_pairs.idx] <- NA
  }

  # -------------------------------------------------------------------------- #
  # ---- Start plotting

  # ---- Generate a fig highlighting focus individuals, if there are some.
  marker_data <- data.frame(
    x       = factor(
      merged$PairIndividuals[main_pairs.idx],
      levels = merged$PairIndividuals[main_pairs.idx]
    ),
    y       = merged[main_pairs.idx, col.po],
    error_y = merged[main_pairs.idx, col.se],
    overlap = merged$OverlapNSNPs.meansP0[main_pairs.idx],
    raw.P0  = merged$Nonnormalized_P0.meansP0[main_pairs.idx]
  )

  marker_fig <- NULL
  if (NROW(marker_data) > 0) {
    marker_fig <- plotly::plot_ly() %>% plotly::add_markers(
      type    = "scatter",
      mode    = "markers",
      x       = marker_data$x,
      y       = marker_data$y,
      name    = paste("<b>", optargs$mainName, "</b>"),
      marker  = list(
        color = "#0579bd", #"#008083",
        size = 12,
        line = list(color = "#0579bd")#"#008083")
      ),
      error_y = ~list(
        array = marker_data$error_y,
        color = "#000000"
      ),
      text       = paste(
        '</br><b>Pair</b>: ', marker_data$PairIndividuals,
        '</br><b>Normalized P0</b>: ', marker_data$y,
        '<br><b>Raw P0</b>:',    marker_data$raw.P0,
        '</br><b>Overlap</b>:', marker_data$overlap
      )
    ) %>% plotly::layout(
      shapes = kinship_rectangles(version = optargs$version),
      margin = list(l = 0, r = 0, t = 0, b = 0),
      xaxis = list(tickangle = 60)
    )
  } else {
    warning("No significant pair found. Skipping subplotting with scatter")
  }

  # ---- Plot within group boxplots if requested by the user.
  within_boxplot_fig <- NULL
  if (within_group_boxplot_requested) {
    dat <- merged[!is.na(merged$within.group), ]

    within_boxplot_fig <- plotly::plot_ly()

    for (group in na.exclude(unique(merged$within.group))) {
      group_subset <- dat[dat$within.group == group, ]

      # Check if the median's notch will be larger than the IQR.
      # See https://plotly.com/r/reference/box/#box-notched for details on
      # how plotly internally computes the median' 95%
      n            <- NROW(group_subset)
      iqr          <- stats::IQR(group_subset[[col.po]])
      notchspan    <- 1.57 * (iqr / sqrt(n))
      quartiles    <- stats::quantile(group_subset[[col.po]])
      should_notch <- ( # are the notches contained between Q1 and Q3 ?
        quartiles[["50%"]] + notchspan < quartiles[["75%"]] &&
        quartiles[["50%"]] - notchspan > quartiles[["25%"]]
      )

      # Add boxplot.
      x <- paste0("<b>", group_subset$within.group, "</b> (n=", n, ")")
      within_boxplot_fig <- within_boxplot_fig %>% plotly::add_boxplot(
        x          = x,
        y          = group_subset[[col.po]],
        jitter     = 1,
        pointpos   = 0,
        boxpoints  = ifelse(should_notch, "outliers", "all"),
        notched    = should_notch,
        notchwidth = 0.25,
        width      = 0.8,
        fillcolor  = "#0579bd80",
        marker     = list(color = 'rgba(0,0,0,0.5)'),
        line       = list(color = 'rgba(7,40,89,1)'),
        text       = paste(
          '</br><b>Pair</b>: ', group_subset$PairIndividuals,
          '</br><b>Normalized P0</b>: ', group_subset[, col.po],
          '<br><b>Raw P0</b>:', group_subset$Nonnormalized_P0.meansP0,
          '</br><b>Overlap</b>:', group_subset$OverlapNSNPs.meansP0
        )
      )
    }

    within_boxplot_fig <- within_boxplot_fig %>% plotly::layout(
      shapes = kinship_rectangles(version = optargs$version),
      margin = list(l = 0, r = 0, t = 0, b = 0),
      xaxis  = list(tickangle = 60)
    )
    within_boxplot_fig
  }

  # ---- Generate main condensed boxplot
  merged$group.label <- lapply(
    X   = merged$group,
    FUN = function(x, counts){
      if(is.na(x)) return(x)
      with(counts, paste0("<b>", x, " </b>(n=", n[group == x], ")"))
    },
    counts = merged %>%
      dplyr::group_by(group) %>%
      dplyr::summarize(n = n()) %>%
      na.omit
  )

  boxplot_fig <- plotly::plot_ly() %>% plotly::add_boxplot(
    x           = merged$group.label,
    y           = merged[[col.po]],
    jitter      = 1,
    pointpos    = 0,
    boxpoints   = optargs$markers,
    notched     = optargs$notch,
    notchwidth  = 0.25,
    fillcolor   = "#F78104",
    marker      = list(color = 'rgba(100,100,100,0.3)'),
    line        = list(color = 'rgba(7,40,89,0.6)'),
    name        = paste0("<b>", optargs$proxyName, " individuals</b>"),
    hoverinfo   = 'text',
    hoveron    = "boxes+points",
    text        = paste(
      '</br><b>Pair</b>: ',          merged$PairIndividuals,
      '</br><b>Normalized P0</b>: ', merged[, col.po],
      '<br><b>Raw P0</b>:',    merged$Nonnormalized_P0.meansP0,
      '</br><b>Overlap</b>:',        merged$OverlapNSNPs.meansP0
    )
  ) %>% plotly::layout(
    shapes = kinship_rectangles(version = optargs$version),
    margin = list(l = 0, r = 0, t = 0, b = 0, pad = 0),
    xaxis  = list(tickangle = 60)
  )

  plots  <- list(marker_fig, within_boxplot_fig, boxplot_fig) %>%
    base::Filter(base::Negate(is.null), .)
  widths <- rep(optargs$plot.ratio, 3)[seq_along(plots)]

  fig <- plotly::subplot(plots,
    shareY = TRUE,
    margin = 0.005,
    nrows  = 1,
    widths = widths
   ) %>%
    annotate_kinship_labels(font.size = 12, version = optargs$version) %>%
    plotly::layout(
      title = list(text = "    "),
      yaxis = list(
        title     = list(text = "<b> Normalized mean P̄0</b>", font = list(size = 18)),
        range     = get_P0_range(merged, version = optargs$version) + 0.01
      ),
      legend = list(
        orientation = 'h',
        x           = -0,
        y           = -0.05,
        xref        = 'paper',
        yref        = 'paper',
        xanchor     = 'left',
        yanchor     = 'top',
        font        = list(size = 18)
      ),
    showlegend = FALSE
  ) %>% plotly::config(
    editable             = FALSE,
    displaylogo          = FALSE,
    scrollZoom           = TRUE,
    toImageButtonOptions = list(
      format   = optargs$output_format,
      filename = optargs$output_basename
    )
  )

  htmlwidgets::saveWidget(
    widget        = fig,
    file          = paste0(optargs$output_basename, ".html"),
    selfcontained = TRUE
  )

}

if (sys.nframe() == 0) {
    main()
}
