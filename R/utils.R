#' Select data type: 'original' or 'simplified' (default)
#'
#' @param temp_meta A dataframe with the file_url addresses of perugpkg datasets
#' @param simplified Logical TRUE or FALSE indicating  whether the function returns the 'original' dataset with high resolution or a dataset with 'simplified' borders (Defaults to TRUE)
#' @keywords internal
#'
select_data_type <- function(temp_meta, simplified=NULL){

  if (!is.logical(simplified))
  { stop(paste0("Argument 'simplified' needs to be either TRUE or FALSE")) }

  if(isTRUE(simplified)){
    temp_meta <- temp_meta[temp_meta$type == "simplified", ]
  }

  if(isFALSE(simplified)){
    temp_meta <- temp_meta[temp_meta$type != "simplified", ]
  }

  return(temp_meta)
}

# -------------------------------------------------------------------------
#' Select data level: nacional, departamental, provincial
#'
#'
#' @param temp_meta A dataframe with the file_url addresses of perugpkg datasets
#' @param level 'all', 'dep' or 'prov'
#' @keywords internal
#'

select_data_level <- function(temp_meta, level = "prov"){

  if (!level %in% c('all', 'dep', 'prov') )
  { stop(paste0("Argument 'level' needs to be 'all', 'dep' or 'prov'")) }

  if(level == "all"){
    temp_meta <- temp_meta[ temp_meta$level == "nacional", ]
  }
  else if(level == "dep"){
    temp_meta <- temp_meta[ temp_meta$level == "departamento", ]
  }
  else if(level == "prov"){
    temp_meta <- temp_meta[ temp_meta$level == "provincia", ]
  }
  return(temp_meta)
}

# -------------------------------------------------------------------------
#' Support function to download metadata internally used
#'
#' @keywords internal
download_metadata <- function(){

  # create tempfile to save metadata
  tempf <- file.path(tempdir(), "metadata_peru_gpkg.csv")

  # IF metadata has already been successfully downloaded
  if (file.exists(tempf) & file.info(tempf)$size != 0) {

  } else {

    # download metadata to temp file
    metadata_link <- "https://raw.githubusercontent.com/PaulESantos/perugeopkg/master/metadata_peru_gpkg.csv"

    try( silent = TRUE,
         httr::GET(url= metadata_link,
                   httr::write_disk(tempf, overwrite = TRUE))
    )

    if (!file.exists(tempf) | file.info(tempf)$size == 0) { return(invisible(NULL)) }

  }

  # read metadata
  metadata <- utils::read.csv(tempf, stringsAsFactors=FALSE)

  # check if data was read Ok
  if (nrow(metadata)==0) {
    message("A file must have been corrupted during download.
            Please restart your R session and download the data again.")
    return(invisible(NULL))
  }

  return(metadata)
}

# -------------------------------------------------------------------------
#' Select metadata
#'
#' @param geography Which geography will be downloaded.
#' @param simplified Logical TRUE or FALSE indicating  whether the function
#'        returns the 'original' dataset with high resolution or a dataset with
#'        'simplified' borders (Defaults to TRUE).
#'
#' @keywords internal
#'
select_metadata <- function(geography, level = "all", simplified=NULL){
  geography <- trimws(toupper(geography))
  # download metadata
  metadata <- download_metadata()

  # check if download failed
  if (is.null(metadata)) { return(invisible(NULL)) }
  #metadata
  # Select geo
  if(level == "all"){
    temp_meta <- subset(metadata, dep_name == "all")
  }
  else if(level == "dep"){
    temp_meta <- subset(metadata, dep_name %in% geography)
  }
  else if(level == "prov"){
    temp_meta <- subset(metadata, prov_name %in% geography)
  }
  #temp_meta |>  as_tibble()
  # Select data level
  temp_meta <- select_data_level(temp_meta, level = level)
  #temp_meta
  # Select data type
  temp_meta <- select_data_type(temp_meta, simplified = simplified)
  #temp_meta
  return(temp_meta)
}


# -------------------------------------------------------------------------


#' Check internet connection with GitHub repository
#'
#' @description
#' Checks if there is an internet connection with GitHub to download data.
#'
#' @param url A string with the url address of an perugpkg dataset
#' @param silent Logical. Throw a message when silent is `FALSE` (default)
#'
#' @return Logical. `TRUE` if url is working, `FALSE` if not.
#'
#' @keywords internal
#'
check_connection <- function(url = paste0('https://raw.githubusercontent.com/PaulESantos/',
                                          'perugeopkg/master/metadata_peru_gpkg.csv'),
                             silent = FALSE){ # nocov start
#url <- 'https://raw.githubusercontent.com/PaulESantos/perugeopkg/master/metadata_peru_gpkg.csv'
  # check if user has internet connection
  if (!curl::has_internet()) {
    if(isFALSE(silent)){ message("No internet connection.") }

    return(FALSE)
  }

  # message
  msg <- "Problem connecting to data server. Please try again in a few minutes."

  # test server connection
  x <- try(silent = TRUE,
           httr::GET(url, # timeout(5),
                     config = httr::config(ssl_verifypeer = FALSE)))
  # link offline
  if (methods::is(x)=="try-error") {
    if(isFALSE(silent)){ message( msg ) }
    return(FALSE)
  }

  # link working fine
  else if ( identical(httr::status_code(x), 200L)) {
    return(TRUE)
  }

  # link not working or timeout
  else if (! identical(httr::status_code(x), 200L)) {
    if(isFALSE(silent)){ message( msg ) }
    return(FALSE)

  } else if (httr::http_error(x) == TRUE) {
    if(isFALSE(silent)){ message( msg ) }
    return(FALSE)
  }

} # nocov end



# -------------------------------------------------------------------------

#' Load geopackage from tempdir to global environment
#'
#' @param temps The address of a gpkg file stored in tempdir. Defaults to NULL
#' @keywords internal
#'
load_gpkg <- function(temps=NULL){

  ### one single file

  if (length(temps)==1) {

    # read sf
    temp_sf <- sf::st_read(temps, quiet=TRUE)
  }

  else if(length(temps) > 1){

    # read files and pile them up
    files <- lapply(X = temps, FUN = sf::st_read, quiet = TRUE)
    temp_sf <- sf::st_as_sf(data.table::rbindlist(files,
                                                  fill = TRUE))
    # do.call('rbind', files)

    # closes issue 284
    col1 <- names(temp_sf)[1]
    temp_sf <- subset(temp_sf, get(col1) != 'data_table_sf_bug')

    # remove data.table from object class. Closes #279.
    class(temp_sf) <- c("sf", "data.frame")

  }

  # check if data was read Ok
  if (nrow(temp_sf) == 0) {
    message("A file must have been corrupted during download. Please restart your R session and download the data again.")
    return(invisible(NULL))
  }
  return(temp_sf)

  # load gpkg to memory
  temp_sf <- load_gpkg(temps)
  return(temp_sf)
}
# -------------------------------------------------------------------------

#' Download geopackage to tempdir
#'
#' @param file_url A string with the file_url address of a geobr dataset
#' @param progress_bar Logical. Defaults to (TRUE) display progress bar
#' @keywords internal
#'
download_gpkg <- function(file_url, progress_bar = showProgress){

  if (!is.logical(progress_bar))
  { stop("'showProgress' must be of type 'logical'") }

  ## one single file

  if (length(file_url)==1) {

    # location of temp_file
    temps <- paste0(tempdir(),
                    "/",
                    unlist(lapply(strsplit(file_url, "/"),
                                  tail, n = 1L)))
    temps
    # check if file has not been downloaded already. If not, download it
    if (!file.exists(temps) | file.info(temps)$size == 0) {

      # test connection with server1
      try(silent = TRUE,
          check_con <- check_connection(file_url, silent = TRUE)
      )
      #check_con
      # if server1 fails, replace url and test connection with server2
      if (is.null(check_con) | isFALSE(check_con)) {
        # message('Using Github') # debug
        check_con <- try(silent = TRUE,
                         check_connection(file_url,
                                          silent = FALSE))
        if(is.null(check_con) | isFALSE(check_con)){
          return(invisible(NULL)) }
      }

      # download data
      try( httr::GET(url=file_url,
                     if(isTRUE(progress_bar)){
                       httr::progress()},
                     httr::write_disk(temps, overwrite = TRUE),
                     config = httr::config(ssl_verifypeer = FALSE)
      ), silent = TRUE)
    }

    # if anything fails, return NULL
    if (any(!file.exists(temps) | file.info(temps)$size == 0)) {
      return(invisible(NULL)) }

    # load gpkg to memory
    temp_sf <- load_gpkg(temps)
    return(temp_sf)
  }

  ## multiple files

  else if(length(file_url) > 1) {

    # location of all temp_files
    temps <- paste0(tempdir(),"/",
                    unlist(lapply(strsplit(file_url, "/"), tail, n = 1L)))

    # count number of files that have NOT been downloaded already
    number_of_files <- sum( (!file.exists(temps) | file.info(temps)$size == 0) )

    # IF there is any file to download, then download them
    if ( number_of_files > 0 ){

      # test connection with server1
      try(silent = TRUE,
          check_con <- check_connection(file_url, silent = TRUE)
      )

      # if server1 fails, replace url and test connection with server2
      if (is.null(check_con) | isFALSE(check_con)) {
        check_con <- try(silent = TRUE,
                         check_connection(file_url,
                                          silent = FALSE))
        if(is.null(check_con) | isFALSE(check_con)){
          return(invisible(NULL)) }
      }

      # input for progress bar
      if(isTRUE(progress_bar)){
        pb <- utils::txtProgressBar(min = 0,
                                    max = number_of_files,
                                    style = 3)
      }

      # download files
      lapply(X = file_url, function(x){

        # get location of temp_file
        temps <- paste0(tempdir(), "/",
                        unlist(lapply(strsplit(x, "/"), tail, n = 1L)))

        # check if file has not been downloaded already. If not, download it
        if (!file.exists(temps) | file.info(temps)$size == 0) {
          i <- match(c(x), file_url)
          try( httr::GET(url = x, #httr::progress(),
                         httr::write_disk(temps, overwrite = TRUE),
                         config = httr::config(ssl_verifypeer = FALSE)
          ), silent = TRUE)

          if(isTRUE(progress_bar)){ utils::setTxtProgressBar(pb, i) }
        }
      })

      # closing progress bar
      if(isTRUE(progress_bar)){close(pb)}
    }

    # if anything fails, return NULL
    temps <- paste0(tempdir(), "/",
                    unlist(lapply(strsplit(file_url, "/"), tail, n = 1L)))
    if (any(!file.exists(temps) | file.info(temps)$size == 0)) {
      return(invisible(NULL)) }

    # load gpkg
    temp_sf <- load_gpkg(temps) #
    return(temp_sf)

  }
}

