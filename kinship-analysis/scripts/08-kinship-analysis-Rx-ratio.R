#!/usr/bin/env Rscript

#' Import a set of dependencies. Install them if missing.
#' @importFrom base lapply
#' @importFrom utils install.packages library
#' @param packages character vector of libraries.
#' @export NULL
load_dependencies <- function(packages){
  installed_packages <- packages %in% rownames(installed.packages())
  if (any(installed_packages == FALSE)){
    install.packages(packages[!installed_packages])
  }
  lapply(packages, library, character.only = TRUE)
}

#' static function. Returns a vector of characters, specifying valid
#' kinship estimation methods.
kinship_method_labels <- function() {
  c("KIN", "READv2", "GRUPS")
}

#' static function. Returns the default minimum SNP overlap
default_min_overlap <- function() {
  1800
}

#' Simple command line argument parser, using argparse
build_parser <- function() {
  parser <- argparse::ArgumentParser(
    description = "Check kinship sex-bias between samples of a given site"
  )
  parser$add_argument("--results-file",
    type     = "character",
    required = TRUE,
    help     = "(Path): main results for a given method"
  )

  parser$add_argument("--rx-file",
    type     = "character",
    required = TRUE,
    help     = "(Path), file containing sex-assignment values.
    File must be tab-separated and headed with at least two columns named
    ['sample', 'assignment']"
  )
  parser$add_argument("--tool",
    type     = "character",
    required = TRUE,
    help     = paste0(
      "Name of the method used to produce the file provided by
      --results. Valid values: [",
      paste(kinship_method_labels(), collapse = ", "),
      "]"
    )
  )
  parser$add_argument("--min-overlap",
    type    = "numeric",
    default = default_min_overlap(),
    help    = "Minimum required SNP overlap"
  )
  parser$add_argument("--output",
    type    = "character",
    default = "kinship-sex-bias-boxplot.svg",
    help    = "(Path) Name of the output boxplot"
  )
  parser$add_argument("--plot-width",
    type    = "numeric",
    default = 5.5,
    help    = "Width of the output boxplot (inch)"
  )
  parser$add_argument("--plot-height",
    type    = "numeric",
    default = 7,
    help    = "Height of the output boxplot (inch)"
  )
  

  return(parser)

}

#' Load a Rx-ratio file. and perform basic filtering and data-wrangling.
#' File must be tab-separated, and headed with at least two columns, named
#' ['samples', 'assignment']. Assignment must either contain "XX", or "XY"
#' to differentiate female from males. Any other value will be set to NA.
#' @import dplyr
#' @return a dataframe containing two columns, 'samples' and 'assignments'
load_sex_assignment <- function(path) {
  read.table(path, header = TRUE, sep = "\t") %>%
    dplyr::select("sample", "assignment") %>%
    dplyr::mutate(assignment = ifelse(
        assignment %in% c("XX", "XY"),
        assignment,
        NA
      )
    )
}

#' import READv2 Results file
import_readv2 <- function(
  path,
  sample_regex = "[A-Z]{3}[0-9]+[A-Z]{0,1}(?:-[0-9]+){0,1}",
  min.overlap = default_min_overlap()
) {
  read.table(path, sep = "\t", header = TRUE) %>%
    dplyr::filter(OverlapNSNPs > min.overlap) %>%
    dplyr::select("PairIndividuals", "Rel", "KinshipCoefficient", "OverlapNSNPs") %>%
    tidyr::separate_wider_regex( # Split PairIndividuals into two columns
      col         = PairIndividuals,
      cols_remove = FALSE,
      patterns    = c(
        Ind1 = paste0("^",sample_regex),
        Ind2 = paste0(sample_regex, "$")
      )
    ) %>%
    dplyr::mutate(PairIndividuals = paste(Ind1, Ind2, sep = "-")) %>%
    dplyr::rename(Pair = PairIndividuals) %>%
    dplyr::relocate(Ind1, Ind2, .after = Pair)
    
    #dplyr::select(-c(Ind1, Ind2))
}

load_results_file <- function(path, tool, min.overlap = default_min_overlap()) {
  load_func <- list(
    "READv2" = import_readv2
  )[[tool]]
  load_func(path, min.overlap = min.overlap)
}

assign_sex <- function(results, rx) {
  results$Ind1.sex <- apply(results, MARGIN = 1, FUN = function(row) {
    with(rx, assignment[which(sample == row[["Ind1"]])])
  })
  results$Ind2.sex <- apply(results, MARGIN = 1, FUN = function(row) {
    with(rx, assignment[which(sample == row[["Ind2"]])])
  })

  results$Pair.sex <- with(results, paste(Ind1.sex, Ind2.sex, sep = "-"))

  results$Pair.sex.factor <- sapply(results$Pair.sex, FUN=function(x) {
    if (x == "XY-XX") "XX-XY"
    else if (grepl("NA", x)) NA
    else x
  }) %>% factor(levels=c("XX-XX", "XY-XY", "XX-XY"))
  results
}

#' Plot a boxplot higlighting sex bias (ie XX-XX vs XY-XY kinship coefficients)
#' @import ggplot2
#' @import EnvStats
boxplot_sex_bias <- function(
  results,
  test = kruskal.test(KinshipCoefficient ~ Pair.sex.factor, data = results),
  annotate = TRUE
) {

  line.color = "#008083"
  fill.color = "#008083CC"

  if (annotate) {
    test.name <- test$method
    p.value <- ifelse(
      test$p.value > 10^-3,
      as.character(round(test$p.value, 3)),
      format(test$p.value, scientific = T)
    )
    text <- "hello annot"
    text <- paste0("p.value: ", p.value, " (",test.name,")")
  }

  ggplot2::ggplot(
    data=results,
    aes(x=Pair.sex.factor, y = KinshipCoefficient)
  ) +
  ggplot2::geom_violin(alpha = 0.3, color = line.color) +
  ggplot2::geom_boxplot(
    width=0.2,
    outlier.color = "darkred",
    outlier.alpha = 1,
    outlier.size  = 2,
    color = line.color,
    fill=fill.color,
    alpha=0.3,
    notch = TRUE
  ) +
  EnvStats::stat_n_text() +
  ggplot2::ggtitle(text) +
  ggplot2::xlab("Paired Rx assignment") +
  ggplot2::ylab("Kinship coefficient") +
  ggplot2::theme_minimal()
}

if (sys.nframe() == 0) {
  # ---- DEBUG
  options(dplyr.print_max = 1e9, tibble.width = Inf, width = 300)
  # ---- END DEBUG


  # ---- load dependencies
  dependencies <- c("argparse", "dplyr", "ggplot2", "EnvStats")
  load_dependencies(dependencies)

  # ---- Parse command line arguments
  optargs <- tryCatch(
    { build_parser()$parse_args(commandArgs(trailingOnly = TRUE)) },
    error = function(e){ stop(paste(e, "\n")) }
  )

  # ----- Quick validation of command line args.
  if (!(optargs$tool %in% kinship_method_labels()))
    stop("Invalid specified --tool")

  # ---- load rx assign
  rx <- load_sex_assignment(optargs$rx_file)

  # ---- load results file
  results <- load_results_file(
    optargs$results_file,
    tool         = optargs$tool,
    min.overlap = optargs$min_overlap
  )

  # ---- Parse and assign sex of individudals
  results <- assign_sex(results, rx)

  sex.bias.test <- kruskal.test(KinshipCoefficient~Pair.sex.factor, data=results)
  boxplot <- boxplot_sex_bias(results, test = sex.bias.test, annotate = TRUE)
  ggsave(
    filename = optargs$output,
    device   = svg,
    width    = optargs$plot_width,
    height   = optargs$plot_height
  )
}