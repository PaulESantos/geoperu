#' Download spatial data of Peru
#'
#' Downloads spatial data of Peru using Geodetic reference system "WGRS84" and CRS(4326).
#'
#' @param geography A character or a vector with the name of geographical region.
#' An exception is "all" to request all Peru data.
#' @param level A character: "all" for national level data, "dep" for department
#' level data, and "prov" for provincial level data.
#' @param simplified A logical TRUE or FALSE, to select data with all districts or
#' a polygon simplified to a higher level.
#' @param showProgress Logical TRUE or FALSE to display a progress bar during download.
#'
#' @return An `"sf" "data.frame"` object containing the spatial data of Peru.
#'
#' @export
#'
#' @examples
#' \donttest{
#' # Read specific province
#' anta <- get_geo_peru(geography = "ANTA",
#'                      level = "prov",
#'                      simplified = TRUE)
#'
#' # Read more than one province
#' df <- get_geo_peru(geography = c("CALCA"),
#'                    level = "prov",
#'                    simplified = FALSE)
#'
#' # Read department level data
#' cusco <- get_geo_peru(geography = "cusco",
#'                       level = "dep",
#'                       simplified = TRUE)
#'}
get_geo_peru<-  function(geography = "all",
                         level = "all",
                         simplified = TRUE,
                         showProgress = TRUE) {

  # Get metadata with data url addresses
  temp_meta <- select_metadata(geography = geography,
                               level = level,
                               simplified = simplified)
  # check if download failed
  if (is.null(temp_meta)) { return(invisible(NULL)) }

  # list paths of files to download
  file_url <- as.character(temp_meta$download_path)
  # download gpkg
  temp_sf <- download_gpkg(file_url, progress_bar = FALSE)
  # check if download failed
  if (is.null(temp_sf)) {
    return(invisible(NULL))
  }
  else{
    return(temp_sf)
  }

}
