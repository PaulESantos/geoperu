#' Obtener datos espaciales de distritos por departamento en Perú
#'
#' Esta función permite filtrar los datos espaciales de los distritos de Perú
#' según el nombre o nombres de los departamentos especificados.
#'
#' @param dep_name El nombre o nombres de los departamentps a las que se desean filtrar los datos.
#'   Puede ser un vector de cadenas de caracteres. Si se omite o es NULL, la función devolverá todos los distritos.
#' @return Un objeto espacial (SpatialDataFrame) que contiene los datos de los distritos
#'   de las provincias especificadas. Si no se encuentra ninguna coincidencia o los datos de Perú
#'   no están disponibles, devuelve NULL.
#' @examples
#' # Obtener datos del departamento de Lima
#' lima_data <- get_dep_sf(c("LIMA"))
#'
#' # Obtener datos de los departamentos
#'
#' varios_data <- get_dep_sf(c("LIMA", "CUSCO"))
#'
#' @export
get_dep_sf <- function(dep_name = NULL){
  if(is.null(dep_name) || length(dep_name) == 0) {
    warning("No se proporcionaron nombres de departamentos.
            Devolviendo todos los departamentos.")
    return(geoperu::distritos_peru |>
             sf::st_as_sf())
  }

  df <- geoperu::distritos_peru |>
    sf::st_as_sf()

  dep_name <- toupper(dep_name)

  valid_provinces <- unique(df$departamento)
  invalid_provinces <- dep_name[!dep_name %in% valid_provinces]

  if(length(invalid_provinces) > 0){
    stop(paste("Error: Valores invalidos para los siguientes nombres de provincia:",
               paste(invalid_provinces, collapse = ", ")))
  }

  df |>
    dplyr::filter(departamento %in% dep_name)
}
