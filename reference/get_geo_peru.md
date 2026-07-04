# Download spatial data of Peru

Downloads spatial data of Peru using the WGS 84 geodetic reference
system (EPSG:4326).

## Usage

``` r
get_geo_peru(
  geography = "all",
  level = "all",
  simplified = TRUE,
  showProgress = TRUE
)
```

## Arguments

- geography:

  A character or a vector with the name of geographical region. An
  exception is "all" to request all Peru data.

- level:

  A character: "all" for national level data, "dep" for department level
  data, and "prov" for provincial level data.

- simplified:

  A logical TRUE or FALSE, to select data with all districts or a
  polygon simplified to a higher level.

- showProgress:

  Logical TRUE or FALSE to display a progress bar during download.

## Value

An `"sf" "data.frame"` object containing the spatial data of Peru.

## Examples

``` r
if (interactive()) {
# Read specific province
anta <- get_geo_peru(geography = "ANTA",
                     level = "prov",
                     simplified = TRUE)

}
```
