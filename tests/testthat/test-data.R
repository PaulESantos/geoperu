test_that("peru dataset has the documented spatial contract", {
  data("peru", package = "geoperu", envir = environment())

  expect_s3_class(peru, "sf")
  expect_identical(dim(peru), c(1874L, 4L))
  expect_identical(
    names(peru),
    c("departamento", "provincia", "distrito", "geometry")
  )
  expect_identical(sf::st_crs(peru)$epsg, 4326L)
  expect_false(any(sf::st_is_empty(peru)))
})
