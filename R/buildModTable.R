buildModTable <- function(abundance, temperature, currentTime, currModDT){
  DT <- data.table(values(c(abundance, temperature)))
  names(DT) <- c("abundance", "temperature")
  DT[, year := currentTime]
  if (!is.null(currModDT))
    DT <- rbind(currModDT, DT)
  return(DT)
}
