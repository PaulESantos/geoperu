# Changelog

## geoperu 0.0.2

- [`get_geo_peru()`](https://paulesantos.github.io/geoperu/reference/get_geo_peru.md)
  downloads multiple selected files concurrently, reducing the wait for
  all departments or provinces.
- [`get_geo_peru()`](https://paulesantos.github.io/geoperu/reference/get_geo_peru.md)
  now returns all departments or provinces when `geography = "all"` is
  used with the respective level.
- Made downloads atomic and validated HTTP responses before caching
  files.
- Improved error messages for unavailable, empty, or malformed remote
  data.
- Removed duplicate network requests and consolidated GeoPackage
  downloads.
- Added argument validation and expanded automated tests.
- Updated documentation and CRAN metadata.

## geoperu 0.0.0.2

CRAN release: 2024-04-01

- Initial CRAN release.
