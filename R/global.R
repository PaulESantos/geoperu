utils::globalVariables(c( ".data", "provincia", "departamento",
                          "dep_name", "prov_name", "file_url", "file_url2",
                          "showProgress", "tail"
))



# -------------------------------------------------------------------------


.onAttach <- function(lib, pkg) {
  packageStartupMessage("This is geoperu ",
                        utils::packageDescription("geoperu",
                                                  fields = "Version"
                        ),
                        appendLF = TRUE
  )
}


# -------------------------------------------------------------------------

show_progress <- function() {
  isTRUE(getOption("geoperu.show_progress")) && # user disables progress bar
    interactive() # Not actively knitting a document
}



.onLoad <- function(libname, pkgname) {
  opt <- options()
  opt_geoperu<- list(
    geoperu.show_progress = TRUE
  )
  to_set <- !(names(opt_geoperu) %in% names(opt))
  if (any(to_set)) options(opt_geoperu[to_set])
  invisible()
}


