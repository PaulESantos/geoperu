#' Obtener datos espaciales de distritos por provincia en Perú
#'
#' Esta función permite filtrar los datos espaciales de los distritos de Perú
#' según el nombre o nombres de provincia especificados.
#'
#' @param prov_name El nombre o nombres de las provincias a las que se desean filtrar los datos.
#'   Puede ser un vector de cadenas de caracteres. Si se omite o es NULL, la función devolverá todos los distritos.
#' @return Un objeto espacial (SpatialDataFrame) que contiene los datos de los distritos
#'   de las provincias especificadas. Si no se encuentra ninguna coincidencia o los datos de Perú
#'   no están disponibles, devuelve NULL.
#' @examples
#' # Obtener datos de la provincia de Lima
#' lima_data <- get_prov_sf(c("Lima"))
#' # Obtener datos de varias provincias
#' varios_data <- get_prov_sf(c("Lima", "Arequipa", "Cusco"))
#' # Obtener todos los datos de distritos sin filtrar por provincia
#' all_data <- get_prov_sf()
#' @export
get_prov_sf <- function(prov_name = NULL){
  if(is.null(prov_name) || length(prov_name) == 0) {
    warning("No se proporcionaron nombres de provincias. Devolviendo todos los distritos.")
    return(geoperu::distritos_peru |>
             sf::st_as_sf())
  }

  df <- geoperu::distritos_peru |>
    sf::st_as_sf()

  prov_name <- toupper(prov_name)

  valid_provinces <- unique(df$provincia)
  invalid_provinces <- prov_name[!prov_name %in% valid_provinces]

  if(length(invalid_provinces) > 0){
    stop(paste("Error: Valores invalidos para los siguientes nombres de provincia:",
               paste(invalid_provinces, collapse = ", ")))
  }

  df |>
    dplyr::filter(provincia %in% prov_name)
}
