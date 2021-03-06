
mask_function <- function(mat, cutoffs) {
  mask <- mat
  for (row in 1:nrow(mat)) {
    for (col in 1:ncol(mat)) {
      for (cutoff in cutoffs) {
        mask[row, col] <- (mat[row, col] >= cutoff[1] && mat[row, col] <= cutoff[2])
      }
    }
  }

  mask
}

threshold_in_range <- function(mat, ...) {
  kwargs <- list(...)
  if ("cutoffs" %in% names(kwargs)) {
    cutoffs <- kwargs[["cutoffs"]]
  } else {
    warning("Setting 'cutoffs' argument is strongly encouraged. Using cutoff range of (-1, 1).")
    cutoffs <- list(c(-1, 1))
  }

  mask <- mask_function(mat, cutoffs)
  thresholded_mat <- mat * mask

  if (!is.null(kwargs[["binary"]])) {
    if (kwargs[["binary"]] || FALSE) {
      thresholded_mat <- mask
    }
  }

  if (!is.null(kwargs[["remove_self_loops"]])) {
    if (kwargs[["remove_self_loops"]] && TRUE) {
      diag(thresholded_mat) <- 0
    }
  } else {
    diag(thresholded_mat) <- 0
  }

  thresholded_mat
}


threshold_on_quantile <- function(mat, ...) {
  kwargs <- list(...)

  if ("quantile" %in% names(kwargs)) {
    quantile <- kwargs[["quantile"]]
  } else {
    warning("Setting 'quantile' argument is strongly recommended. Using target quantile of 0.9 for thresholding.")
    quantile <- 0.9
  }

  if (!is.null(kwargs[["remove_self_loops"]])) {
    if (kwargs[["remove_self_loops"]] && TRUE) {
      diag(mat) <- 0
    }
  } else {
    diag(mat) <- 0
  }

  if (quantile != 0) {
    thresholded_mat <- mat * (mat > quantile(mat, probs = quantile))
  } else {
    thresholded_mat <- mat
  }

  if (!is.null(kwargs[["binary"]])) {
    if (kwargs[["binary"]] || FALSE) {
      thresholded_mat <- abs(sign(thresholded_mat))
    }
  }

  thresholded_mat
}


threshold_on_degree <- function(mat, ...) {
  kwargs <- list(...)

  if ("avg_k" %in% names(kwargs)) {
    avg_k <- kwargs[["avg_k"]]
  } else {
    warning("Setting 'avg_k' argument is strongly encouraged. Using average degree of 1 for thresholding.")
    avg_k <- 1
  }

  n <- ncol(mat)
  A <- matrix(1, n, n)

  if (!is.null(kwargs[["remove_self_loops"]])) {
    if (kwargs[["remove_self_loops"]] && TRUE) {
      diag(A) <- 0
      diag(mat) <- 0
    }
  } else {
    diag(A) <- 0
    diag(mat) <- 0
  }

  if (mean(rowSums(A)) <= avg_k) {
    thresholded_mat <- mat
  } else {
    for (m in sort(as.vector(t(mat)))) {
      A[mat == m] <- 0
      if (mean(rowSums(A)) <= avg_k) {
        break
      }
    }
    thresholded_mat <- mat * (mat > m)
  }

  if (!is.null(kwargs[["binary"]])) {
    if (kwargs[["binary"]] || FALSE) {
      thresholded_mat <- abs(sign(thresholded_mat))
    }
  }

  thresholded_mat
}


#' Utilities for thresholding matrices based on different criteria
#'
#' @param mat input matrix
#'
#' @param rule A string indicating which thresholding function to invoke.
#' @param ... Arguments
#'
#' @export
threshold <- function(mat, rule, ...) {
  kwargs <- list(...)

  tryCatch(
    {
      if (rule == "degree") {
        threshold_on_degree(mat, ...)
      }
      else if (rule == "range") {
        threshold_in_range(mat, ...)
      }
      else if (rule == "quantile") {
        threshold_on_quantile(mat, ...)
      }
      else if (rule == "custom") {
        kwargs[["custom_thresholder"]](mat)
      }
    },
    error = function(e) {
      stop("missing threshold parameter")
    }
  )
}
