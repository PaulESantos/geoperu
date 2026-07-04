test_that("metadata selectors filter levels and data types", {
  metadata <- data.frame(
    id = 1:4,
    level = c("nacional", "departamento", "provincia", "provincia"),
    type = c("simplified", "simplified", "simplified", "original")
  )

  expect_identical(geoperu:::select_data_level(metadata, "all")$id, 1L)
  expect_identical(geoperu:::select_data_level(metadata, "dep")$id, 2L)
  expect_identical(geoperu:::select_data_level(metadata, "prov")$id, c(3L, 4L))
  expect_identical(geoperu:::select_data_type(metadata, TRUE)$id, 1:3)
  expect_identical(geoperu:::select_data_type(metadata, FALSE)$id, 4L)
})

test_that("metadata selectors reject non-scalar choices", {
  metadata <- data.frame(level = "nacional", type = "simplified")

  for (value in list(
    "district",
    NA_character_,
    character(),
    c("dep", "prov")
  )) {
    expect_error(geoperu:::select_data_level(metadata, value), "needs to be")
  }
  for (value in list(1, NA, logical(), c(TRUE, FALSE))) {
    expect_error(geoperu:::select_data_type(metadata, value), "needs to be")
  }
})

test_that("select_metadata filters downloaded metadata", {
  metadata <- data.frame(
    dep_name = c("all", "CUSCO", "CUSCO"),
    prov_name = c("all", "all", "ANTA"),
    level = c("nacional", "departamento", "provincia"),
    type = c("simplified", "simplified", "original"),
    download_path = c("country", "department", "province")
  )
  local_mocked_bindings(
    download_metadata = function() metadata,
    .package = "geoperu"
  )

  expect_identical(
    geoperu:::select_metadata("all", "all", TRUE)$download_path,
    "country"
  )
  expect_identical(
    geoperu:::select_metadata("cusco", "dep", TRUE)$download_path,
    "department"
  )
  expect_identical(
    geoperu:::select_metadata("anta", "prov", FALSE)$download_path,
    "province"
  )
})

test_that("select_metadata_anp prefers exact matches then partial matches", {
  metadata <- data.frame(
    anp_nombre = c("MANU", "SANTUARIO NACIONAL PAMPA HERMOSA"),
    download_path = c("manu", "pampa")
  )
  local_mocked_bindings(
    download_metadata_anp = function() metadata,
    .package = "geoperu"
  )

  expect_identical(geoperu:::select_metadata_anp("manu")$download_path, "manu")
  expect_identical(
    geoperu:::select_metadata_anp("pampa")$download_path,
    "pampa"
  )
  expect_equal(nrow(geoperu:::select_metadata_anp("unknown")), 0L)
})

test_that("metadata readers use valid cached CSV files", {
  geo_path <- file.path(tempdir(), "metadata_peru_gpkg.csv")
  anp_path <- file.path(tempdir(), "metadata_anp.csv")
  old_geo <- if (file.exists(geo_path)) {
    readBin(geo_path, "raw", file.info(geo_path)$size)
  } else {
    NULL
  }
  old_anp <- if (file.exists(anp_path)) {
    readBin(anp_path, "raw", file.info(anp_path)$size)
  } else {
    NULL
  }
  on.exit(
    {
      if (is.null(old_geo)) {
        unlink(geo_path)
      } else {
        writeBin(old_geo, geo_path)
      }
      if (is.null(old_anp)) unlink(anp_path) else writeBin(old_anp, anp_path)
    },
    add = TRUE
  )

  utils::write.csv(
    data.frame(
      dep_name = "all",
      prov_name = "all",
      level = "nacional",
      type = "simplified",
      download_path = "geo"
    ),
    geo_path,
    row.names = FALSE
  )
  utils::write.csv(
    data.frame(
      anp_nombre = "MANU",
      anp_categoria = "PN",
      download_path = "anp"
    ),
    anp_path,
    row.names = FALSE
  )

  expect_identical(geoperu:::download_metadata()$download_path, "geo")
  expect_identical(geoperu:::download_metadata_anp()$download_path, "anp")
})

test_that("malformed cached metadata are rejected and removed", {
  cache_name <- paste0("geoperu-invalid-", Sys.getpid(), ".csv")
  cache_path <- file.path(tempdir(), cache_name)
  on.exit(unlink(cache_path), add = TRUE)
  utils::write.csv(
    data.frame(unexpected = "value"),
    cache_path,
    row.names = FALSE
  )

  expect_message(
    result <- geoperu:::.read_metadata(
      "https://example.test/metadata.csv",
      cache_name,
      "download_path"
    ),
    "unexpected format"
  )

  expect_null(result)
  expect_false(file.exists(cache_path))
})

test_that("load_gpkg reads and combines GeoPackage files", {
  paths <- c(
    tempfile("geoperu-one-", fileext = ".gpkg"),
    tempfile("geoperu-two-", fileext = ".gpkg")
  )
  on.exit(unlink(paths), add = TRUE)
  make_sf <- function(id, x) {
    sf::st_sf(
      id = id,
      geometry = sf::st_sfc(sf::st_point(c(x, x)), crs = 4326)
    )
  }
  sf::st_write(make_sf(1L, 0), paths[1], quiet = TRUE)
  sf::st_write(make_sf(2L, 1), paths[2], quiet = TRUE)

  one <- geoperu:::load_gpkg(paths[1])
  both <- geoperu:::load_gpkg(paths)

  expect_s3_class(one, "sf")
  expect_identical(one$id, 1L)
  expect_s3_class(both, "sf")
  expect_identical(both$id, 1:2)
  expect_identical(class(both), c("sf", "data.frame"))
  expect_error(geoperu:::load_gpkg(character()), "non-empty character")
})

test_that("download helpers reuse cached GeoPackage files", {
  paths <- c(
    tempfile("geoperu-cache-one-", tmpdir = tempdir(), fileext = ".gpkg"),
    tempfile("geoperu-cache-two-", tmpdir = tempdir(), fileext = ".gpkg")
  )
  on.exit(unlink(paths), add = TRUE)
  make_sf <- function(id, x) {
    sf::st_sf(
      id = id,
      geometry = sf::st_sfc(sf::st_point(c(x, x)), crs = 4326)
    )
  }
  sf::st_write(make_sf(1L, 0), paths[1], quiet = TRUE)
  sf::st_write(make_sf(2L, 1), paths[2], quiet = TRUE)
  urls <- paste0("https://example.test/", basename(paths))

  one <- geoperu:::download_gpkg(urls[1], progress_bar = FALSE)
  both <- geoperu:::download_gpkg(urls, progress_bar = FALSE)
  anp <- geoperu:::download_gpkg_anp(urls[2], progress_bar = FALSE)

  expect_identical(one$id, 1L)
  expect_identical(both$id, 1:2)
  expect_identical(anp$id, 2L)
})

test_that("cache paths ignore query strings and reject collisions", {
  path <- geoperu:::.cache_paths("https://example.test/data.gpkg?download=1")
  expect_identical(basename(path), "data.gpkg")
  expect_error(
    geoperu:::.cache_paths(c(
      "https://one.example/data.gpkg",
      "https://two.example/data.gpkg"
    )),
    "unique file names"
  )
})

test_that("corrupt GeoPackages fail gracefully", {
  path <- tempfile(fileext = ".gpkg")
  on.exit(unlink(path), add = TRUE)
  writeLines("not a GeoPackage", path)

  expect_message(result <- geoperu:::load_gpkg(path), "Unable to read")
  expect_null(result)
})

test_that("progress defaults and download arguments are scalar logical", {
  old <- options(geoperu.show_progress = TRUE)
  on.exit(options(old), add = TRUE)

  expect_type(geoperu:::show_progress(), "logical")
  expect_length(geoperu:::show_progress(), 1L)
  for (value in list(NA, logical(), c(TRUE, FALSE))) {
    expect_error(geoperu:::download_gpkg("unused", value), "TRUE or FALSE")
    expect_error(geoperu:::download_gpkg_anp("unused", value), "TRUE or FALSE")
  }
})

test_that("downloads are atomic and keep only successful responses", {
  destination <- tempfile("geoperu-download-")
  on.exit(unlink(c(destination, paste0(destination, ".part"))), add = TRUE)

  local_mocked_bindings(
    .perform_get = function(url, destination, timeout, progress) {
      writeLines("valid content", destination)
      structure(list(status_code = 200L), class = "response")
    },
    .package = "geoperu"
  )
  expect_true(geoperu:::.download_file("https://example.test", destination))
  expect_identical(readLines(destination), "valid content")

  writeLines("existing content", destination)
  local_mocked_bindings(
    .perform_get = function(url, destination, timeout, progress) {
      writeLines("error page", destination)
      structure(list(status_code = 503L), class = "response")
    },
    .package = "geoperu"
  )
  expect_message(
    expect_false(geoperu:::.download_file("https://example.test", destination)),
    "HTTP 503"
  )
  expect_identical(readLines(destination), "existing content")
  expect_false(file.exists(paste0(destination, ".part")))
})

test_that("download failures return FALSE and remove partial files", {
  destination <- tempfile("geoperu-download-")
  on.exit(unlink(c(destination, paste0(destination, ".part"))), add = TRUE)

  local_mocked_bindings(
    .perform_get = function(...) stop("network unavailable"),
    .package = "geoperu"
  )
  expect_message(
    expect_false(geoperu:::.download_file("https://example.test", destination)),
    "network unavailable"
  )
  expect_false(file.exists(destination))
  expect_false(file.exists(paste0(destination, ".part")))

  local_mocked_bindings(
    .perform_get = function(url, destination, timeout, progress) {
      file.create(destination)
      structure(list(status_code = 200L), class = "response")
    },
    .package = "geoperu"
  )
  expect_message(
    expect_false(geoperu:::.download_file("https://example.test", destination)),
    "empty file"
  )
})
