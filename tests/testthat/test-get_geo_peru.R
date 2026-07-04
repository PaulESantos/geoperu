test_that("get_geo_peru validates public arguments before downloading", {
  expect_error(get_geo_peru(geography = character()), "non-empty character")
  expect_error(get_geo_peru(geography = NA_character_), "non-empty character")
  expect_error(get_geo_peru(level = "district"), "must be one of")
  expect_error(get_geo_peru(level = c("dep", "prov")), "must be one of")
  expect_error(get_geo_peru(simplified = 1), "must be TRUE or FALSE")
  expect_error(get_geo_peru(simplified = NA), "must be TRUE or FALSE")
  expect_error(get_geo_peru(showProgress = logical()), "must be TRUE or FALSE")
})

test_that("get_geo_peru forwards arguments and progress to helpers", {
  local_mocked_bindings(
    select_metadata = function(geography, level, simplified) {
      expect_identical(geography, "CUSCO")
      expect_identical(level, "dep")
      expect_false(simplified)
      data.frame(download_path = "geo.gpkg")
    },
    download_gpkg = function(file_url, progress_bar) {
      expect_identical(file_url, "geo.gpkg")
      expect_false(progress_bar)
      "geo-result"
    },
    .package = "geoperu"
  )

  result <- get_geo_peru(
    geography = "CUSCO",
    level = "dep",
    simplified = FALSE,
    showProgress = FALSE
  )

  expect_identical(result, "geo-result")
})

test_that("get_geo_peru handles missing metadata and empty matches", {
  local_mocked_bindings(
    select_metadata = function(...) NULL,
    .package = "geoperu"
  )
  expect_null(get_geo_peru())

  local_mocked_bindings(
    select_metadata = function(...) data.frame(download_path = character()),
    .package = "geoperu"
  )
  expect_warning(result <- get_geo_peru(), "No spatial data matched")
  expect_null(result)
})

test_that("get_geo_peru returns NULL when downloading fails", {
  local_mocked_bindings(
    select_metadata = function(...) data.frame(download_path = "geo.gpkg"),
    download_gpkg = function(...) NULL,
    .package = "geoperu"
  )

  expect_null(get_geo_peru())
})
