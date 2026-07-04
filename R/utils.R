select_data_type <- function(temp_meta, simplified = NULL) {
  if (
    !is.logical(simplified) || length(simplified) != 1L || is.na(simplified)
  ) {
    stop(
      "Argument 'simplified' needs to be either TRUE or FALSE",
      call. = FALSE
    )
  }

  if (simplified) {
    temp_meta[temp_meta$type == "simplified", , drop = FALSE]
  } else {
    temp_meta[temp_meta$type != "simplified", , drop = FALSE]
  }
}

select_data_level <- function(temp_meta, level = "prov") {
  if (
    !is.character(level) ||
      length(level) != 1L ||
      is.na(level) ||
      !level %in% c("all", "dep", "prov")
  ) {
    stop("Argument 'level' needs to be 'all', 'dep' or 'prov'", call. = FALSE)
  }

  level_name <- switch(
    level,
    all = "nacional",
    dep = "departamento",
    prov = "provincia"
  )
  temp_meta[temp_meta$level == level_name, , drop = FALSE]
}

.perform_get <- function(url, destination, timeout, progress) {
  request <- list(
    url = url,
    httr::timeout(timeout),
    httr::write_disk(destination, overwrite = TRUE)
  )
  if (progress) {
    request <- append(request, list(httr::progress()))
  }
  do.call(httr::GET, request)
}

.download_file <- function(
  url,
  destination,
  timeout = 120,
  progress = FALSE,
  silent = FALSE
) {
  partial <- paste0(destination, ".part")
  unlink(partial)
  on.exit(unlink(partial), add = TRUE)

  response <- tryCatch(
    .perform_get(url, partial, timeout, progress),
    error = function(error) {
      if (!silent) {
        message("Unable to download data: ", conditionMessage(error))
      }
      NULL
    }
  )

  if (is.null(response)) {
    return(FALSE)
  }
  if (httr::http_error(response)) {
    if (!silent) {
      message(
        "Unable to download data from ",
        url,
        ": HTTP ",
        httr::status_code(response),
        "."
      )
    }
    return(FALSE)
  }
  if (!file.exists(partial) || file.info(partial)$size == 0) {
    if (!silent) {
      message("The data server returned an empty file for ", url, ".")
    }
    return(FALSE)
  }

  if (file.exists(destination)) {
    unlink(destination)
  }
  if (!file.rename(partial, destination)) {
    if (!file.copy(partial, destination, overwrite = TRUE)) {
      if (!silent) {
        message("Unable to save downloaded data to ", destination, ".")
      }
      return(FALSE)
    }
    unlink(partial)
  }

  TRUE
}

.read_metadata <- function(url, cache_name, required_columns) {
  cache_path <- file.path(tempdir(), cache_name)
  cache_missing <- !file.exists(cache_path) || file.info(cache_path)$size == 0

  if (cache_missing && !.download_file(url, cache_path, timeout = 30)) {
    return(invisible(NULL))
  }

  metadata <- tryCatch(
    utils::read.csv(cache_path, stringsAsFactors = FALSE),
    error = function(error) {
      message("Unable to read downloaded metadata: ", conditionMessage(error))
      NULL
    }
  )
  valid <- !is.null(metadata) &&
    nrow(metadata) > 0L &&
    all(required_columns %in% names(metadata))

  if (!valid) {
    unlink(cache_path)
    message("Downloaded metadata are empty or have an unexpected format.")
    return(invisible(NULL))
  }

  metadata
}

download_metadata <- function() {
  .read_metadata(
    "https://raw.githubusercontent.com/PaulESantos/perugeopkg/master/metadata_peru_gpkg.csv",
    "metadata_peru_gpkg.csv",
    c("dep_name", "prov_name", "level", "type", "download_path")
  )
}

download_metadata_anp <- function() {
  .read_metadata(
    "https://raw.githubusercontent.com/PaulESantos/perugeopkg/master/metadata_anp.csv",
    "metadata_anp.csv",
    c("anp_nombre", "anp_categoria", "download_path")
  )
}

select_metadata <- function(geography, level = "all", simplified = NULL) {
  if (
    !is.character(level) ||
      length(level) != 1L ||
      !level %in% c("all", "dep", "prov")
  ) {
    stop("'level' must be one of 'all', 'dep', or 'prov'.", call. = FALSE)
  }

  geography <- trimws(toupper(geography))
  metadata <- download_metadata()
  if (is.null(metadata)) {
    return(invisible(NULL))
  }

  temp_meta <- switch(
    level,
    all = metadata[metadata$dep_name == "all", , drop = FALSE],
    dep = metadata[metadata$dep_name %in% geography, , drop = FALSE],
    prov = metadata[metadata$prov_name %in% geography, , drop = FALSE]
  )
  temp_meta <- select_data_level(temp_meta, level)
  select_data_type(temp_meta, simplified)
}

select_metadata_anp <- function(anp) {
  anp <- trimws(toupper(anp))
  metadata <- download_metadata_anp()
  if (is.null(metadata)) {
    return(invisible(NULL))
  }

  exact <- metadata$anp_nombre == anp
  if (any(exact)) {
    return(metadata[exact, , drop = FALSE])
  }
  metadata[grepl(anp, metadata$anp_nombre, fixed = TRUE), , drop = FALSE]
}

load_gpkg <- function(temps = NULL) {
  if (!is.character(temps) || !length(temps) || anyNA(temps)) {
    stop("'temps' must be a non-empty character vector.", call. = FALSE)
  }

  files <- lapply(temps, function(path) {
    tryCatch(
      sf::st_read(path, quiet = TRUE),
      error = function(error) {
        message(
          "Unable to read downloaded spatial data: ",
          conditionMessage(error)
        )
        NULL
      }
    )
  })
  if (any(vapply(files, is.null, logical(1)))) {
    return(invisible(NULL))
  }

  spatial_data <- if (length(files) == 1L) {
    files[[1L]]
  } else {
    do.call(rbind, files)
  }
  if (nrow(spatial_data) == 0L) {
    message("Downloaded spatial data contain no features.")
    return(invisible(NULL))
  }

  spatial_data
}

.cache_paths <- function(file_url) {
  clean_url <- sub("[?#].*$", "", file_url)
  file_name <- basename(utils::URLdecode(clean_url))
  if (any(!nzchar(file_name))) {
    stop("Every download URL must end with a file name.", call. = FALSE)
  }
  paths <- file.path(tempdir(), file_name)
  if (anyDuplicated(paths)) {
    stop("Download URLs must have unique file names.", call. = FALSE)
  }
  paths
}

download_gpkg <- function(file_url, progress_bar = show_progress()) {
  if (!is.character(file_url) || !length(file_url) || anyNA(file_url)) {
    stop("'file_url' must be a non-empty character vector.", call. = FALSE)
  }
  if (
    !is.logical(progress_bar) ||
      length(progress_bar) != 1L ||
      is.na(progress_bar)
  ) {
    stop("'showProgress' must be TRUE or FALSE.", call. = FALSE)
  }

  cache_paths <- .cache_paths(file_url)
  missing <- !file.exists(cache_paths) | file.info(cache_paths)$size == 0
  pending <- which(missing)

  progress <- NULL
  if (progress_bar && length(pending) > 1L) {
    progress <- utils::txtProgressBar(min = 0, max = length(pending), style = 3)
    on.exit(close(progress), add = TRUE)
  }

  for (index in seq_along(pending)) {
    position <- pending[[index]]
    downloaded <- .download_file(
      file_url[[position]],
      cache_paths[[position]],
      timeout = 120,
      progress = progress_bar && length(pending) == 1L
    )
    if (!downloaded) {
      return(invisible(NULL))
    }
    if (!is.null(progress)) {
      utils::setTxtProgressBar(progress, index)
    }
  }

  spatial_data <- load_gpkg(cache_paths)
  if (is.null(spatial_data)) {
    unlink(cache_paths)
  }
  spatial_data
}

download_gpkg_anp <- function(file_url, progress_bar = show_progress()) {
  download_gpkg(file_url, progress_bar)
}
