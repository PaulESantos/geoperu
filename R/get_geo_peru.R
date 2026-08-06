#' Download spatial data of Peru
#'
#' Downloads spatial data of Peru using the WGS 84 geodetic reference system
#' (EPSG:4326).
#'
#' @param geography A character or a vector with the name of geographical region.
#' Use "all" to request all geographic units at the selected level.
#' @param level A character: "all" for national data, "dep" for departments,
#' and "prov" for provinces. Together with `geography = "all"`, the options
#' return one national dataset, 25 departments, or 196 provinces, respectively.
#' @param simplified A logical TRUE or FALSE, to select data with all districts or
#' a polygon simplified to a higher level.
#' @param showProgress Logical TRUE or FALSE to display a progress bar during download.
#'
#' @return An `"sf" "data.frame"` object containing the spatial data of Peru.
#'
#' @export
#'
#' @examples
#' if (interactive()) {
#' # Read specific province
#' anta <- get_geo_peru(geography = "ANTA",
#'                      level = "prov",
#'                      simplified = TRUE)
#'
#'}
get_geo_peru <- function(
  geography = "all",
  level = "all",
  simplified = TRUE,
  showProgress = TRUE
) {
  if (!is.character(geography) || !length(geography) || anyNA(geography)) {
    stop("'geography' must be a non-empty character vector.", call. = FALSE)
  }
  if (
    !is.character(level) ||
      length(level) != 1L ||
      !level %in% c("all", "dep", "prov")
  ) {
    stop("'level' must be one of 'all', 'dep', or 'prov'.", call. = FALSE)
  }
  if (
    !is.logical(simplified) || length(simplified) != 1L || is.na(simplified)
  ) {
    stop("'simplified' must be TRUE or FALSE.", call. = FALSE)
  }
  if (
    !is.logical(showProgress) ||
      length(showProgress) != 1L ||
      is.na(showProgress)
  ) {
    stop("'showProgress' must be TRUE or FALSE.", call. = FALSE)
  }

  # Get metadata with data url addresses
  temp_meta <- select_metadata(
    geography = geography,
    level = level,
    simplified = simplified
  )
  # check if download failed
  if (is.null(temp_meta)) {
    return(invisible(NULL))
  }

  # list paths of files to download
  file_url <- as.character(temp_meta$download_path)
  # download gpkg
  if (!length(file_url)) {
    warning("No spatial data matched the requested geography.", call. = FALSE)
    return(invisible(NULL))
  }
  temp_sf <- download_gpkg(file_url, progress_bar = showProgress)
  # check if download failed
  if (is.null(temp_sf)) {
    return(invisible(NULL))
  } else {
    return(temp_sf)
  }
}
