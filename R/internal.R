#' Support function to download metadata internally used
#'
#' @keywords internal
#' @examples \dontrun{ if (interactive()) {
#' df <- download_metadata()
#' }}
download_metadata <- function(){

  # create tempfile to save metadata
  tempf <- file.path(tempdir(), "metada_prov.csv")

  # IF metadata has already been successfully downloaded
  if (file.exists(tempf) & file.info(tempf)$size != 0) {

  } else {

    # download metadata to temp file
    metadata_link <- "https://raw.githubusercontent.com/PaulESantos/perugeopkg/master/metada_prov.csv"

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
#' Select data level: 'dep', 'prov' (default)
#'
#'
#' @param temp_meta A dataframe with the file_url addresses of geobr datasets
#' @param simplified Logical TRUE or FALSE indicating  whether the function
#' returns the 'complete' dataset or a dataset 'simplified' hiegher level (Defaults to TRUE)
#' @keywords internal
#'
select_data_level <- function(temp_meta, simplified=NULL){

  if (!is.logical(simplified)) { stop(paste0("Argument 'simplified' needs to be either TRUE or FALSE")) }

  if(isTRUE(simplified)){
    temp_meta <- temp_meta[
      grepl(pattern="simplified", temp_meta$download_path), ]
  }

  if(isFALSE(simplified)){
    temp_meta <- temp_meta[
      !(grepl(pattern="simplified", temp_meta$download_path)), ]
  }

  return(temp_meta)
}


