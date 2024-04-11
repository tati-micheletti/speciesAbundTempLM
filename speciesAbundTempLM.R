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
  version = list(speciesAbundTempLM = "1.0.0"),
  timeframe = as.POSIXlt(c(2013, 2032)),
  timeunit = "year",
  citation = list("citation.bib"),
  documentation = list("NEWS.md", "README.md", "speciesAbundTempLM.Rmd"),
  reqdPkgs = list("SpaDES.core (>= 2.0.3)", "terra", "reproducible", "ggplot2"),
  parameters = bindrows(
    defineParameter(".plotInitialTime", "numeric", NA, NA, NA,
                    "Describes the simulation time at which the first plot event should occur."),
    defineParameter(".plotInterval", "numeric", NA, NA, NA,
                    "Describes the simulation time interval between plot events."),
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
      
      # Check last abundance data matches the current year. If so, it means that there is 
      # still data available and we shouldn't build the model quite yet. When the data (Year) 
      # from abundRas doesn't match the current year, it means we don't have data for the 
      # abundance anymore and should build the model for forecasts   

      if (as.numeric(strsplit(x = names(sim$abundaRas), 
                              split = ": ")[[1]][2]) < time(sim)){
        
        sim <- scheduleEvent(sim, time(sim), "speciesAbundTempLM", "modelBuilding")
        
      } else {
        sim$modDT <- buildModTable(abundance = sim$abundaRas, 
                                   temperature = sim$tempRas,
                                   currentTime = time(sim),
                                   currModDT = sim$modDT)
        
        sim <- scheduleEvent(sim, time(sim) + 1, "speciesAbundTempLM", "tableBuilding")
      }
    },
    modelBuilding = {

      sim$abundTempLM <- lm(abundance ~ temperature, data = sim$modDT)
      
      # Schedule the next events
      sim <- scheduleEvent(sim, time(sim), "speciesAbundTempLM", "abundanceForecasting")
      sim <- scheduleEvent(sim, time(sim), "speciesAbundTempLM", "plot")
    },
    abundanceForecasting = {
      newData <- data.table(values(sim$tempRas))
      names(newData) <- "temperature"
      forecVals <- round(as.numeric(predict(object = sim$abundTempLM, newdata = newData)), 0)
      forecastRas <- setValues(x = sim$tempRas, values = forecVals)
      sim$forecasts[[paste0("Year", time(sim))]] <- forecastRas
      
      sim <- scheduleEvent(sim, time(sim) + 1, "speciesAbundTempLM", "abundanceForecasting")
    },
    plot = {
      
      terra::plot(sim$forecasts[[paste0("Year", time(sim))]], 
                  main = paste0("Forecasted abundance: ", time(sim)))
      if (time(sim) == end(sim)){
        sim$forecastedDifferences <- sim$forecasts[[paste0("Year", 
                                                           time(sim))]]-sim$abundaRas
        terra::plot(sim$forecastedDifferences, 
                    main = paste0("Difference in abundance between ", 
                                  strsplit(x = names(sim$abundaRas),
                                           split = ": ")[[1]][2], 
                                  " and ",
                                  time(sim)), col = c("#67001F", "#B2182B", "#D6604D",
                                                      "#F7F7F7", 
                                                      "#D1E5F0", "#92C5DE", "#4393C3", 
                                                      "#2166AC", "#053061", "#032143", 
                                                      "#010f1e"))
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
