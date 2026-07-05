#' Download Spatial Data of Protected Natural Areas (ANP) in Peru
#'
#' Downloads spatial data of protected natural areas in Peru declared by SERNANP
#' (National Service of Natural Areas Protected by the State).
#' Data were obtained from the
#' [SERNANP Geographic Information Viewer](https://www.gob.pe/institucion/sernanp/pages/21261-acceder-a-informacion-espacial-de-las-area-naturales-protegidas-visor-de-informacion-geografica)
#' as the official source. The data use WGS 84 (EPSG:4326).
#'
#' @param anp A character or a vector with the name(s) of the protected natural areas in Peru.
#' @param showProgress Logical TRUE or FALSE to display a progress bar during download.
#'
#' @return An `"sf" "data.frame"` object containing the spatial data of Peru's protected natural areas.
#'
#' @export
#'
#' @examples
#' if (interactive()) {
#' # Read specific ANP
#' manu <- get_anp_peru(anp = "Manu")
#'
#'}
get_anp_peru <- function(anp = NULL, showProgress = TRUE) {
  if (is.null(anp) || !is.character(anp) || !length(anp) || anyNA(anp)) {
    stop("'anp' must be a non-empty character vector.", call. = FALSE)
  }
  if (
    !is.logical(showProgress) ||
      length(showProgress) != 1L ||
      is.na(showProgress)
  ) {
    stop("'showProgress' must be TRUE or FALSE.", call. = FALSE)
  }
  # Get metadata with data url addresses
  if (length(anp) > 1) {
    temp_meta <- list()
    for (i in seq_along(anp)) {
      temp <- select_metadata_anp(anp = anp[i])
      temp_meta[[i]] <- temp
    }
    temp_meta <- do.call(rbind, temp_meta)
  } else {
    temp_meta <- select_metadata_anp(anp = anp)
  }

  # check if download failed
  if (is.null(temp_meta)) {
    return(invisible(NULL))
  }

  # list paths of files to download
  file_url <- as.character(temp_meta$download_path)

  if (!length(file_url)) {
    warning("No protected natural area matched 'anp'.", call. = FALSE)
    return(invisible(NULL))
  }

  if (length(file_url) > 1) {
    anp_list <- paste0(temp_meta$anp_categoria, " - ", temp_meta$anp_nombre)
    message(paste(
      "Spatial data for:",
      paste0(anp_list, collapse = " and "),
      " has been downloaded as a list object."
    ))

    temp_sf <- list()

    for (i in seq_along(file_url)) {
      temp <- download_gpkg_anp(file_url[i], progress_bar = showProgress)
      temp_sf[[i]] <- temp
    }
  } else {
    temp_sf <- download_gpkg_anp(file_url, progress_bar = showProgress)
  }
  # check if download failed
  if (is.null(temp_sf)) {
    return(invisible(NULL))
  } else {
    return(temp_sf)
  }
}
