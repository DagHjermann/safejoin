#' Eat columns from another data frame
#'
#' Modified left_join where only a specified subset of \code{y} is kept, with
#'   optional checks and transformations.
#'
#' Character codes are the same as for `safe_*_join` functions, with the
#' addition of `"d"`to check if dots were filled.
#'
#' @inheritParams dplyr::left_join
#' @inheritParams safe_joins
#' @param x,y	tbls to join
#' @param ... One or more unquoted expressions, passed to \code{dplyr::select},
#'   defining the columns to keep from \code{y}
#' @param fun function or formula or \code{NULL}, if not \code{NULL}, \code{y}
#'   will be grouped by its \code{by} columns and \code{fun} will be applied to
#'   all kept columns from {y}
#' @param conflict if `NULL`, in case of column conflict both columns are
#'   suffixed as in *dplyr*, if a function of two parameters or a formula,
#'   a function is applied on both columns. If the string "patch", matched
#'   values from `y` will overwrite existing values in `x` while the other
#'   values will be kept
#' @param prefix prefix of new columns or function/formula to apply on names of new
#'   columns
#' @return a data frame
#' @export
eat <- function(x, y, ..., by = NULL, fun = NULL,
                 check = "~j",
                 conflict = NULL,
                 prefix = NULL) {

  #conflict <- match.arg(conflict,)

  l <- safe_check(x, y, by, check, skip_some = TRUE)
  x <- l$x
  y <- l$y
  by <- l$by

  # check dots
  d_check <- check_for_letter(check,"d")
  if (d_check$lgl && length(substitute(list(...))) == 1) {
    if (d_check$fun == "abort") {
      rlang::abort("Eaten columns must be given explicitly")
    }
    txt <- sprintf(
      "Column names not provided, all columns from y will be eaten :\n%s",
      paste_enum(setdiff(names(y),by$y)))
    get(d_check$fun)(txt)
  }

  # store y's by columns as symbols
  by_y_syms <- rlang::syms(by$y)

  # subset y by column
  if (rlang::dots_n(...)) y <- dplyr::select(y, !!!by_y_syms, ...)

  # prefix y cols if relevant
  if (!is.null(prefix)) {
    if (is.character(prefix)) prefix <- eval(rlang::expr( ~stringr::str_c(!!prefix, "_", .)))
    y <- dplyr::rename_at(y, setdiff(names(y),by$y), prefix)
  }

  # transform y with fun if relevant
  if (!is.null(fun)) {
    fun <- rlang::as_function(fun)
    . <- dplyr::group_by(y, !!!by_y_syms)
    y <- dplyr::summarize_all(., fun)
  }

  # check column conflict
  c_check <- check_for_letter(check,"c")
  patch <- FALSE
  apply_conflict_fun <- FALSE
  if (c_check$lgl || !is.null(conflict) &&
     length(common_aux <-
            intersect(setdiff(names(x),by$x), setdiff(names(y),by$y)))) {
    txt <- sprintf("Conflict of auxiliary columns: %s", paste_enum(common_aux))
    get(c_check$fun)(txt)
    if (is.function(conflict) || inherits(conflict,"formula")) {
      conflict_fun <- rlang::as_function(conflict)
      y <- dplyr::rename_at(y, common_aux,~paste0("*", .x, "_patch*"))
      apply_conflict_fun <- TRUE
      } else if (conflict == "patch") {
          y <- dplyr::rename_at(y, common_aux,~paste0("*", .x, "_patch*"))
          #x <- mutate(x, `*temp_dummy_x*` = 1)
          y <- dplyr::mutate(y, `*temp_dummy_y*` = 1)
          patch <- TRUE
        }
  }

  # check y unicity (might be executed only if not summarized)
  v_check <- check_for_letter(check,"v")
  if (v_check$lgl && anyDuplicated(y[by$y])) {
    txt <- sprintf("y is not unique on %s", paste_enum(by$y))
    get(v_check$fun)(txt)
  }

  res <- dplyr::left_join(x,y, by = setNames(by$y,by$x))

  # after join, apply the patch or fun if relevant
  if (patch) {
    dummy_col <- "*temp_dummy_y*"
    rows_lgl <- !is.na(res[[dummy_col]])
    temp_cols <-  paste0("*",common_aux,"_patch*")
    res[rows_lgl, common_aux] <- res[rows_lgl,temp_cols]
    res <- dplyr::mutate_at(res,c(dummy_col,temp_cols), ~NULL)
  } else if (apply_conflict_fun) {
    for (aux in common_aux) {
    res[[aux]] <- conflict_fun(res[[aux]], res[[paste0("*",aux,"_patch*")]])
    temp_cols <-  paste0("*",common_aux,"_patch*")
    res <- dplyr::mutate_at(res,temp_cols, ~NULL)
    }
  }
  res
}