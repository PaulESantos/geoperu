#' Support function to download metadata internally used
#' Funcion para descargar la lista de datos espaciales de peru
#' @keywords internal
#' @examples \dontrun{ if (interactive()) {
#' df <- download_metadata()
#' }}
download_metadata <- function() {
  # Esta función descarga el archivo de metadatos desde una URL específica y lo guarda en un archivo temporal.

  # Crear un archivo temporal para guardar los metadatos.
  tempf <- file.path(tempdir(), "metadata_prov.csv")

  # Verificar si los metadatos ya han sido descargados previamente y son válidos.
  if (file.exists(tempf) & file.info(tempf)$size != 0) {
    # Si los metadatos existen y no están vacíos, no es necesario volver a descargarlos.
    # No se hace nada en este caso.
  } else {
    # Si los metadatos no existen o están vacíos, intentamos descargarlos.

    # Intento de descarga de los metadatos.
    metadata_link <- "https://raw.githubusercontent.com/PaulESantos/perugeopkg/master/metadata_prov.csv"
    tryCatch({
      # Intentar descargar los metadatos a un archivo temporal.
      httr::GET(url = metadata_link,
                httr::write_disk(tempf, overwrite = TRUE))
    }, error = function(e) {
      # Manejar cualquier error que ocurra durante la descarga.
      message("Error durante la descarga de los metadatos:", e$message)
    })

    # Verificar si la descarga fue exitosa.
    if (!file.exists(tempf) | file.info(tempf)$size == 0) {
      # Si la descarga falla o el archivo descargado está vacío, regresar NULL.
      return(invisible(NULL))
    }
  }

  # Leer los metadatos desde el archivo temporal.
  metadata <- utils::read.csv(tempf, stringsAsFactors = FALSE)

  # Verificar si los metadatos se leyeron correctamente.
  if (nrow(metadata) == 0) {
    message("Un archivo podria haberse corrompido durante la descarga. Por favor, reinicie su sesion de R y descargue los datos nuevamente.")
    return(invisible(NULL))
  }

  # Devolver los metadatos.
  return(metadata)
}
