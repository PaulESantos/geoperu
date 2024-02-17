#' Obtener datos espaciales de distritos por provincia en Peru
#'
#' Esta funcion permite filtrar los datos espaciales de los distritos de Peru
#' según el nombre de la provincia especificada.
#'
#' @param prov_name El nombre de la provincia a la que se desean filtrar los datos.
#' Debe ser una cadena de caracteres. Si se omite o es NULL, la función devolvera
#' todos los distritos.
#'
#' @return Un objeto espacial (SpatialDataFrame) que contiene los datos de los
#' distritos de la provincia especificada. Si no se encuentra ninguna coincidencia
#' devuelve NULL.
#'
#' @examples
#' # Obtener datos de la provincia de Lima
#' lima_data <- get_prov_sf("Lima")
#' # Obtener todos los datos de distritos sin filtrar por provincia
#' all_data <- get_prov_sf()
#' @export
get_prov_sf <- function(prov_name = NULL){
  if(is.null(prov_name) || prov_name == "") {
    warning("No se proporciono un nombre de provincia. Devolviendo todos los distritos.")
    return(geoperu::distritos_peru |>
             sf::st_as_sf())
  }

  df <- geoperu::distritos_peru |>
    sf::st_as_sf()
  prov_name <- toupper(trimws(prov_name))

  if(!prov_name %in% unique(df$provincia)){
    stop("Error: Valor invalido para el argumento prov_name.")
  }

  df |>
    dplyr::filter(provincia == prov_name)
}
