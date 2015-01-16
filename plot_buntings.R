# Enables split apply combine for each map across data
library(plyr)
# Sexy colors
library(RColorBrewer)
# Map data and tools
library(maptools)
# For color ramps
library(classInt)
# plot library
library(ggplot2)
# Vector wizardry
library(rgeos)

# Grid was made in GRASS GIS mapset and exported
g <- readShapePoly("data/grid.shp") # load 1-degree grid

# NAs to zero for plotting purposes
g$other[ is.na(g$other) ] <- 0 # Set NAs to zero
g$buntings[ is.na(g$buntings) ] <- 0 # NAs to zero

# Bring in admin boundaries
b <- readShapeLines("data/ne_10m_admin_1_states_provinces_shp.shp")

# Read buntings shpfile
# Buntings shpfile creation method logged in Buntings.mkd
p <- readShapePoints("data/buntings.shp")

# Pull only data from MEXICO
mx <- subset(b, ISO == "MEX")
par(mar=c(0,0,0,0))

# Globals
## list of months
months <- c("January", "February", "March", "April", "May", "June", "July", "August","September","October","November","December")

# Function to draw monthly plots, month will be fed in by lapply() splits
#   on month.
plotmonth <- function(month,nclr=5) {
  screen(month)
  #compute class intervals on all data so all plots have same scale.
  mapclass <- classIntervals(na.omit(g$abund)*100, nclr, style="quantile")

  # Bring in a color pallete
  colpal <- brewer.pal(nclr,"PuBu")

  # Select all columns matching current month that are not na
  monthdata <- subset(g, (mes_col == month) & (!is.na(mes_col)))

  # Scale abundance
  scaledabund <-  monthdata$abund*100

  # Create plot intervals for color map
  pltclass <- classIntervals(scaledabund, nclr, style="fixed",
      fixedBreaks=mapclass['brks']$brks)
  # Apply color pal
  pcol <- findColours(pltclass, colpal, cutlabels=T)

  # Plot abundance data
  plot(monthdata, xlim=c(-119.0,-85.75),
    ylim=c(14.0, 32.74), col=pcol, border=FALSE)

  # Plot Mexican states
  plot(mx , col="black", add=T)

  # Plot actual collection points
  points <- subset(p, MES_COL == month)
  plot(points, add=T, pch='o', col="orange", cex=0.6, alpha=0.5)

  legend(-95, 28, title="Bunting collection points",  legend=list('specimen(s)'), pch='o', col="orange", cex=0.75, bty= "n")

  legend(-95,31.6, title="Buntings as a percent of total collections", legend=names(attr(pcol,"table")), fill=attr(pcol,"palette"), cex = 0.75, bty = "n" )

  #title(months[month])
}

svgplot <- function(plotfunc,arg,tag) {
  # Write SVG files out for each plot
  svg(sprintf('%s%03d.svg',tag,arg), width=15, height=9)

  plotfunc(arg)

  # Close SVG
  dev.off()

}

ploteffort <- function(month,nclr=5) {
  effort <- g$buntings + g$other

  mapclass <- classIntervals(na.omit(effort), nclr, style="fisher")

  colpal <- brewer.pal(nclr,"Greys")
  monthdata <- subset(g, (mes_col == month) & (!is.na(mes_col)))
  pltclass <- classIntervals(monthdata$other, nclr, style="fixed", fixedBreaks=mapclass['brks']$brks)
  pcol <- findColours(pltclass, colpal, cutlabels=T)
  png(sprintf('effort%03d.png',month), width=1280, height=1024)
  plot(monthdata, xlim=c(-119.0,-85.75), ylim=c(14.0, 32.74), col=pcol, border="gray")
  plot(mx , col="dodgerblue3", add=T)
  bgcolor <- rgb(246,40,26,128, max=255)
  plot(gCentroid(subset(g,mes_col==month),byid=T), pch=21, col="darkgray", cex=sqrt(subset(g,mes_col == month)$abund)*9, bg=bgcolor, add=T)
  plot(subset(p, MES_COL == month), add=T, pch=20, col="green", cex=0.5)
  legend(-97,30, title="Collection effort - # Specimins Collected", legend=names(attr(pcol,"table")), fill=attr(pcol,"palette"), cex = 0.75, bty = "n" )
  title(months[month])
  dev.off()


}

main <- function() {
ploteffort(1)


lapply(seq(1,12), plotmonth)

lapply(seq(1,12), ploteffort)

system('gm montage -tile 4x3 -geometry 2400x1860 map*.svg map.png')
system('gm montage -tile 4x3 -geometry 2400x1860 effort*.svg effort.png')
}
