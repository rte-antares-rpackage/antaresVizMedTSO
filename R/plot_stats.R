.plotMonotone <- function(dt, timeStep, variable, variable2Axe = NULL, typeConfInt = FALSE, confInt = NULL, maxValue,
                          main = NULL, ylab = NULL, highlight = FALSE, stepPlot = FALSE, drawPoints = FALSE, language = "en", 
                          label_variable2Axe = NULL, ...) {
  
  if(is.null(typeConfInt)) typeConfInt <- FALSE
  if(is.null(confInt)) confInt <- 0
  
  uniqueElements <- as.character(sort(unique(dt$element)))
  plotConfInt <- FALSE
  # If dt contains several Monte-Carlo scenario, compute aggregate statistics
  if (is.null(dt$mcYear)) {
    dt <- dt[, .(
      x = 1:length(value),
      y = sort(value, decreasing = TRUE)
    ), by = element]
  } else {
    dt <- dt[, .(
      x = 1:length(value),
      y = sort(value, decreasing = TRUE)
    ), by = .(element, mcYear)]
    
    if(typeConfInt){
      if (confInt == 0) {
        dt <- dt[, .(y = mean(y)), by = .(element, x)]
      } else {
        plotConfInt <- TRUE
        uniqueElements <- as.character(sort(unique(dt$element)))
        
        alpha <- (1 - confInt) / 2
        dt <- dt[, .(y = c(mean(y), quantile(y, c(alpha, 1 - alpha))),
                     suffix = c("", "_l", "_u")), 
                 by = .(x, element)]
        dt[, element := paste0(element, suffix)]
      }
    }
  }
  
  variable <- paste0(variable, collapse = " ; ")
  if (is.null(ylab)) ylab <- variable
  if (is.null(main) | isTRUE(all.equal("", main))){
    main <- paste(.getLabelLanguage("Monotone of", language), variable)
  }
  
  if(!is.null(variable2Axe) && length(variable2Axe) > 0){
    ylab2 <- paste0(label_variable2Axe, collapse = " ; ")
  } else {
    ylab2 <- NULL
  }
  
  .plotStat(dt, ylab = ylab, main = main, uniqueElements = uniqueElements, variable2Axe = variable2Axe,
            plotConfInt = plotConfInt, highlight = highlight, stepPlot = stepPlot, drawPoints = drawPoints, 
            ylab2 = ylab2, ...)
  
}

.density <- function(dt, timeStep, variable, variable2Axe = NULL, minValue = NULL, maxValue = NULL, 
                     main = NULL, ylab = NULL, highlight = FALSE, stepPlot = FALSE, drawPoints = FALSE, 
                     language = "en", label_variable2Axe = NULL, ...) {
  
  uniqueElements <- as.character(sort(unique(dt$element)))
  
  xbins <- .getXBins(dt$value, minValue, maxValue)
  if (is.character(xbins)) return(xbins)
  
  .getDensity <- function(x) {
    dens <- density(x, from = xbins$rangeValues[1], to = xbins$rangeValues[2])
    data.table(x = signif(dens$x, xbins$nsignif), y = dens$y)
  }
  
  dt <- dt[, .getDensity(value), by = element]
  
  variable <- paste0(variable, collapse = " ; ")
  if (is.null(ylab)){
    # ylab <- .getLabelLanguage("Density", language)
    ylab <- variable
  }

  if(!is.null(variable2Axe) && length(variable2Axe) > 0){
    ylab2 <- paste0(label_variable2Axe, collapse = " ; ")
  } else {
    ylab2 <- NULL
  }
  
  if (is.null(main) | isTRUE(all.equal("", main))){
    main <- paste(.getLabelLanguage("Density of", language), variable)
  }
  
  .plotStat(dt, ylab = ylab, main = main, uniqueElements = uniqueElements,variable2Axe = variable2Axe, 
            highlight = highlight, stepPlot = stepPlot, drawPoints = drawPoints, ylab2 = ylab2, ...)
  
}

.cdf <- function(dt, timeStep, variable, variable2Axe = NULL, minValue = NULL, maxValue = NULL,
                 main = NULL, ylab = NULL, highlight = FALSE, stepPlot = FALSE, drawPoints = FALSE, language = "en", ...) {
  
  uniqueElements <- as.character(sort(unique(dt$element)))
  
  xbins <- .getXBins(dt$value, minValue, maxValue)$xbins
  
  .getCDF <- function(x) {
    cdf <- sapply(xbins, function(y) mean(x <= y))
    data.table(x = xbins, y = cdf)
  }
  
  dt <- dt[, .getCDF(value), by = element]
  
  variable <- paste0(variable, collapse = " ; ")
  if (is.null(ylab)){
    ylab <- .getLabelLanguage("Proportion of time steps", language)
  } 

  if (is.null(main) | isTRUE(all.equal("", main))){
    main <-  paste(.getLabelLanguage("Cumulated distribution of", language), variable)
  } 
  
  .plotStat(dt, ylab = ylab, main = main, uniqueElements = uniqueElements, variable2Axe = variable2Axe,
            highlight = highlight, stepPlot = stepPlot, drawPoints = drawPoints, ...)
  
}

.getXBins <- function(values, minValue = NULL, maxValue = NULL, size = 512) {
  if (is.null(minValue) || is.na(minValue)) {
    minValue <- min(values)
  }
  
  if (is.null(maxValue) || is.na(maxValue)) {
    maxValue <- max(values)
  }
  
  if (minValue >= maxValue) {
    return("No value to display. Please change values of minValue or unset them to display all values")
  }
  
  rangeValues <- c(minValue, maxValue)
  
  # Get the correct number of significant digits
  offset <- diff(rangeValues) * 0.1
  rangeValues <- c(rangeValues[1] - offset, rangeValues[2] + offset)
  xbins <- seq(rangeValues[1], rangeValues[2], length.out = 512)
  nsignif <- 3
  
  while(any(duplicated(signif(xbins, nsignif)))) nsignif <- nsignif + 1
  
  list(xbins = signif(xbins, nsignif), nsignif = nsignif, rangeValues = rangeValues)
}

.plotStat <- function(dt, ylab, main, colors, uniqueElements, 
                      legend, legendItemsPerRow, width, height,
                      plotConfInt = FALSE, highlight = FALSE,
                      stepPlot = FALSE, drawPoints = FALSE,variable2Axe = NULL, language = "en", ylab2 = NULL, ...) {
  dt <- dcast(dt, x ~ element, value.var = "y")
  
  if (is.null(colors)) {
    colors <- substring(rainbow(length(uniqueElements), s = 0.7, v = 0.7), 1, 7)
  } else {
    colors <- rep(colors, length.out = length(uniqueElements))
  }
  legendId <- sample(1e9, 1)
  
  if(length(uniqueElements) == 1){
    dycol <- colors[1]
  } else {
    dycol <- NULL
  }
  
  g <- dygraph(as.data.frame(dt), main = main, group = legendId) %>% 
    dyOptions(
      includeZero = TRUE, 
      colors = dycol,
      gridLineColor = gray(0.8), 
      axisLineColor = gray(0.6), 
      axisLabelColor = gray(0.6), 
      labelsKMB = TRUE,
      stepPlot = stepPlot,
      drawPoints = drawPoints
    ) %>% 
    dyAxis("y", label = ylab, pixelsPerLabel = 60) %>% 
    dyLegend(show = "never") %>% 
    dyCallbacks(
      highlightCallback = JS_updateLegend(legendId, timeStep = "none", language = language),
      unhighlightCallback = JS_resetLegend(legendId)
    )
  
  for(i in 1:length(uniqueElements)){
    if(!uniqueElements[i] %in% variable2Axe){
      g <- g %>% dySeries(uniqueElements[i], color = colors[i])
    } else {
      g <- g %>% dySeries(uniqueElements[i], axis = 'y2', color = colors[i])
    }
  }
  
  if(highlight){
    g  <- g  %>% dyHighlight(highlightSeriesOpts = list(strokeWidth = 2))
  }
  
  if(!is.null(ylab2)){
    g  <- g  %>% dyAxis("y2", label = ylab2)
  }
  
  if (plotConfInt) {
    for (v in uniqueElements) {
      axis = NULL
      if(length(variable2Axe)>0){
        if(v%in%variable2Axe){
          axis <- "y2"
        } 
      }
      g <- g %>% dySeries(paste0(v, c("_l", "", "_u")), axis = axis)
    }
  }
  
  if (legend) {
    l <- tsLegend(uniqueElements, types = rep("line", length(uniqueElements)), 
                  colors = colors, legendId = legendId, legendItemsPerRow = legendItemsPerRow)
  } else l <- NULL
  
  
  combineWidgets(g, footer = l, width = width, height = height)
}
