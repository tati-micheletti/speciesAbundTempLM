defineModule(sim, list(
  name = "speciesAbundTempLM",
  description = paste0("This is a simple example module on how SpaDES work. It uses made up data",
                       " fitting and forecasting simulated abundance and temperature data.",
                       "This module has been partially inspired by the example publised by Barros et al., 2022",
                       "(https://besjournals.onlinelibrary.wiley.com/doi/full/10.1111/2041-210X.14034)"),
  keywords = c("example", "SpaDES tutorial"),
  authors = structure(list(list(given = "Tati", family = "Micheletti", role = c("aut", "cre"), 
                                email = "tati.micheletti@gmail.com", comment = NULL)), 
                      class = "person"),
  childModules = character(0),
  version = list(speciesAbundTempLM = "0.0.0.9000"),
  timeframe = as.POSIXlt(c(2013, 2032)),
  timeunit = "year",
  citation = list("citation.bib"),
  documentation = list("NEWS.md", "README.md", "speciesAbundTempLM.Rmd"),
  reqdPkgs = list("SpaDES.core (>= 2.0.3)", "terra", "reproducible", "ggplot2"),
  parameters = bindrows(
    defineParameter("modelBuildingTime", "numeric", 2022, start(sim), end(sim),
                    "Describes the simulation time at which the model building event should occur.")
  ),
  inputObjects = bindrows(
    expectsInput(objectName = "abundaRas", objectClass = "SpatRaster", 
                 desc = "A raster object of spatially explicit abundance data for a given year"),
    expectsInput(objectName = "tempRas", objectClass = "SpatRaster",
                 desc = "A raster object of spatially explicit temperature data for a given year")
  ),
  outputObjects = bindrows(
    createsOutput(objectName = "modDT", 
                  objectClass = "data.table", 
                  desc = "Dataset in the form of a data.table with abundance and temperature"),
    createsOutput(objectName = "abundTempLM", 
                  objectClass = "lm", 
                  desc = paste0("A fitted model (of the `lm` class) of abundance in function",
                                " of temperature.")),
    createsOutput(objectName = "forecasts", 
                  objectClass = "SpatRaster", 
                  desc = paste0("This raster shows the forecasts of abundance for each year",
                                " of the simulation after abundance data is no longer ",
                                "available")),
    createsOutput(objectName = "forecastedDifferences", 
                  objectClass = "SpatRaster", 
                  desc = paste0("This raster shows the differences between the first year",
                                "of abundance data and the last abundance forecast"))
  )
))

doEvent.speciesAbundTempLM = function(sim, eventTime, eventType) {
  switch(
    eventType,
    init = {    
      sim$forecasts <- list()
      # schedule future event(s)
      sim <- scheduleEvent(sim, start(sim), "speciesAbundTempLM", "tableBuilding")
      sim <- scheduleEvent(sim, P(sim)$modelBuildingTime + 1, "speciesAbundTempLM", "modelBuilding", eventPriority = .last())
      sim <- scheduleEvent(sim, P(sim)$modelBuildingTime + 1, "speciesAbundTempLM", "abundanceForecasting", eventPriority = .last())
      sim <- scheduleEvent(sim, P(sim)$modelBuildingTime + 1, "speciesAbundTempLM", "plot", eventPriority = .last())
    },
    tableBuilding = {
      rasOverlay <- tryCatch({
        overl <- c(sim$abundaRas, sim$tempRas)
        TRUE
      }, error = function(e) return(FALSE))
      if (any(is.null(sim$abundaRas),
              is.null(sim$tempRas),
              !rasOverlay))
        stop("Both abundaRas and tempRas must be provided, must overlay, and can't be NULL")
      
      sim$modDT <- buildModTable(abundance = sim$abundaRas, 
                                 temperature = sim$tempRas,
                                 currentTime = time(sim),
                                 currModDT = sim$modDT)
      
      sim <- scheduleEvent(sim, time(sim) + 1, "speciesAbundTempLM", "tableBuilding")
    },
    modelBuilding = {

      sim$abundTempLM <- lm(abundance ~ temperature, data = sim$modDT)
      
    },
    abundanceForecasting = {
      
      newData <- data.table(values(sim$tempRas))
      names(newData) <- "temperature"
      forecVals <- as.numeric(predict(object = sim$abundTempLM, newdata = newData))
      forecastRas <- setValues(x = sim$tempRas, values = forecVals)
      sim$forecasts[[paste0("Year", time(sim))]] <- forecastRas
      
      sim <- scheduleEvent(sim, time(sim) + 1, "speciesAbundTempLM", "abundanceForecasting")
    },
    plot = {
      
      terra::plot(sim$forecasts[[paste0("Year", time(sim))]], 
                  main = paste0("Forecasted abundance: ", time(sim)))
      if (time(sim) == end(sim)){
        sim$forecastedDifferences <- sim$forecasts[[paste0("Year", 
                                                           time(sim))]]-sim$forecasts[[paste0("Year", 
                                                                                              P(sim)$modelBuildingTime + 1)]]
        terra::plot(sim$forecastedDifferences, 
                    main = paste0("Difference in abundance between ", 
                                  P(sim)$modelBuildingTime + 1, 
                                  " and ",
                                  time(sim)))
        allForecasts <- rast(sim$forecasts)
        terra::writeRaster(x = allForecasts,
                           filetype = "GTiff",
                           filename = file.path(Paths[["outputPath"]], 
                                                paste0("Abundance_forecasts.tif")), 
                           overwrite = TRUE)
      }
      sim <- scheduleEvent(sim, time(sim) + 1, "speciesAbundTempLM", "plot")
    },
    warning(paste("Undefined event type: \'", current(sim)[1, "eventType", with = FALSE],
                  "\' in module \'", current(sim)[1, "moduleName", with = FALSE], "\'", sep = ""))
  )
  return(invisible(sim))
}

.inputObjects <- function(sim) {
  dPath <- asPath(getOption("reproducible.destinationPath", dataPath(sim)), 1)
  message(currentModule(sim), ": using dataPath '", dPath, "'.")
  if (!suppliedElsewhere(object = "abundaRas", sim = sim)) {
    stop("The object abundaRas needs to be supplied and has currently no defaults")
  }
  if (!suppliedElsewhere(object = "tempRas", sim = sim)) {
    stop("The object tempRas needs to be supplied and has currently no defaults")
  }
  return(invisible(sim))
}
