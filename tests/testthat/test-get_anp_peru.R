test_that("get_anp_peru validates public arguments before downloading", {
  expect_error(get_anp_peru(), "non-empty character")
  expect_error(get_anp_peru(character()), "non-empty character")
  expect_error(get_anp_peru(NA_character_), "non-empty character")
  expect_error(get_anp_peru("Manu", showProgress = 1), "must be TRUE or FALSE")
  expect_error(get_anp_peru("Manu", showProgress = NA), "must be TRUE or FALSE")
})

test_that("get_anp_peru forwards progress for one result", {
  local_mocked_bindings(
    select_metadata_anp = function(...) data.frame(download_path = "anp.gpkg"),
    download_gpkg_anp = function(file_url, progress_bar) {
      expect_identical(file_url, "anp.gpkg")
      expect_true(progress_bar)
      "anp-result"
    },
    .package = "geoperu"
  )

  expect_identical(get_anp_peru("Manu"), "anp-result")
})

test_that("get_anp_peru downloads multiple matches as a list", {
  calls <- character()
  metadata <- data.frame(
    download_path = c("manu.gpkg", "calipuy.gpkg"),
    anp_categoria = c("PN", "SN"),
    anp_nombre = c("MANU", "CALIPUY")
  )
  local_mocked_bindings(
    select_metadata_anp = function(anp) metadata[metadata$anp_nombre == anp, ],
    download_gpkg_anp = function(file_url, progress_bar) {
      calls <<- c(calls, file_url)
      expect_false(progress_bar)
      paste0("result-", file_url)
    },
    .package = "geoperu"
  )

  expect_message(
    result <- get_anp_peru(c("MANU", "CALIPUY"), showProgress = FALSE),
    "downloaded as a list"
  )
  expect_identical(calls, metadata$download_path)
  expect_identical(result, as.list(paste0("result-", metadata$download_path)))
})

test_that("get_anp_peru handles missing metadata and empty matches", {
  local_mocked_bindings(
    select_metadata_anp = function(...) NULL,
    .package = "geoperu"
  )
  expect_null(get_anp_peru("unknown"))

  local_mocked_bindings(
    select_metadata_anp = function(...) data.frame(download_path = character()),
    .package = "geoperu"
  )
  expect_warning(result <- get_anp_peru("unknown"), "No protected natural area")
  expect_null(result)
})
