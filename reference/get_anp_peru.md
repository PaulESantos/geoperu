# Download Spatial Data of Protected Natural Areas (ANP) in Peru

Downloads spatial data of protected natural areas in Peru declared by
SERNANP (National Service of Natural Areas Protected by the State). Data
were obtained from the [SERNANP Geographic Information
Viewer](https://www.gob.pe/institucion/sernanp/pages/21261-acceder-a-informacion-espacial-de-las-area-naturales-protegidas-visor-de-informacion-geografica)
as the official source. The data use WGS 84 (EPSG:4326).

## Usage

``` r
get_anp_peru(anp = NULL, showProgress = TRUE)
```

## Arguments

- anp:

  A character or a vector with the name(s) of the protected natural
  areas in Peru.

- showProgress:

  Logical TRUE or FALSE to display a progress bar during download.

## Value

An `"sf" "data.frame"` object containing the spatial data of Peru's
protected natural areas.

## Examples

``` r
if (interactive()) {
# Read specific ANP
manu <- get_anp_peru(anp = "Manu")

}
```
